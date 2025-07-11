use std::path::Path;
use std::process::Command;
use url::Url;
use crate::error::{ProjectManError, Result};
use crate::config::GlobalConfig;

pub struct GitManager {
    config: GlobalConfig,
}

impl GitManager {
    pub fn new() -> Result<Self> {
        let config = GlobalConfig::load()?;
        Ok(Self { config })
    }
    
    pub fn clone_repository(&self, url: &str, target_path: &Path) -> Result<()> {
        if target_path.exists() {
            return Err(ProjectManError::Git(
                format!("Target directory already exists: {}", target_path.display())
            ));
        }
        
        // Create parent directories if they don't exist
        if let Some(parent) = target_path.parent() {
            std::fs::create_dir_all(parent)?;
        }
        
        println!("🔄 Cloning {} to {}", url, target_path.display());
        println!();
        
        // Use git command directly with inherited stdout/stderr for real-time progress
        let status = Command::new("git")
            .arg("clone")
            .arg("--progress")
            .arg(url)
            .arg(target_path)
            .status()
            .map_err(|e| ProjectManError::Git(format!("Failed to execute git command: {}", e)))?;
        
        if status.success() {
            println!();
            println!("✅ Repository cloned successfully!");
            Ok(())
        } else {
            Err(ProjectManError::Git("Git clone failed".to_string()))
        }
    }
    
    pub fn sync_repository(&self, repo_path: &Path) -> Result<SyncResult> {
        // Use git pull command directly
        let output = Command::new("git")
            .arg("pull")
            .arg("--ff-only")
            .current_dir(repo_path)
            .output()
            .map_err(|e| ProjectManError::Git(format!("Failed to execute git pull: {}", e)))?;
        
        let stdout = String::from_utf8_lossy(&output.stdout);
        let stderr = String::from_utf8_lossy(&output.stderr);
        
        if output.status.success() {
            if stdout.contains("Already up to date") {
                Ok(SyncResult::UpToDate)
            } else {
                // Count commits pulled
                let commits_pulled = stdout.lines()
                    .filter(|line| line.contains("->") && line.contains("/"))
                    .count();
                Ok(SyncResult::Updated { commits_pulled })
            }
        } else if stderr.contains("diverged") || stderr.contains("non-fast-forward") {
            // Get ahead/behind info
            Ok(SyncResult::Conflict { ahead: 0, behind: 0 }) // We'll get exact numbers later if needed
        } else {
            Err(ProjectManError::Git(format!("Git pull failed: {}", stderr)))
        }
    }
    
    pub fn get_repository_status(&self, repo_path: &Path) -> Result<RepoStatus> {
        // Check if working directory is clean
        let status_output = Command::new("git")
            .arg("status")
            .arg("--porcelain")
            .current_dir(repo_path)
            .output()
            .map_err(|e| ProjectManError::Git(format!("Failed to get git status: {}", e)))?;
        
        let is_clean = status_output.stdout.is_empty();
        
        // Check ahead/behind status
        let ahead_behind_output = Command::new("git")
            .arg("rev-list")
            .arg("--left-right")
            .arg("--count")
            .arg("HEAD...@{upstream}")
            .current_dir(repo_path)
            .output();
        
        let (ahead, behind) = if let Ok(output) = ahead_behind_output {
            if output.status.success() {
                let result = String::from_utf8_lossy(&output.stdout);
                let parts: Vec<&str> = result.trim().split('\t').collect();
                if parts.len() == 2 {
                    let ahead = parts[0].parse().unwrap_or(0);
                    let behind = parts[1].parse().unwrap_or(0);
                    (ahead, behind)
                } else {
                    (0, 0)
                }
            } else {
                (0, 0)
            }
        } else {
            (0, 0)
        };
        
        Ok(RepoStatus {
            is_clean,
            ahead,
            behind,
        })
    }
    
    pub fn parse_repository_url(&self, input: &str) -> Result<(String, String)> {
        // If it's already a full URL, parse it
        if input.starts_with("http") || input.starts_with("git@") {
            return self.parse_full_url(input);
        }
        
        // Handle shorthand format (user/repo)
        if input.contains('/') && !input.contains('@') && !input.contains(':') {
            let parts: Vec<&str> = input.split('/').collect();
            if parts.len() == 2 {
                let user = parts[0];
                let repo = parts[1];
                let url = match self.config.git.default_protocol.as_str() {
                    "ssh" => format!("git@{}:{}/{}.git", self.config.git.default_host, user, repo),
                    "https" => format!("https://{}/{}/{}.git", self.config.git.default_host, user, repo),
                    _ => return Err(ProjectManError::Config("Invalid default protocol".to_string())),
                };
                let path = format!("{}/{}/{}", self.config.git.default_host, user, repo);
                return Ok((url, path));
            }
        }
        
        Err(ProjectManError::InvalidUrl(format!("Invalid repository format: {}", input)))
    }
    
    
    fn parse_full_url(&self, url: &str) -> Result<(String, String)> {
        if url.starts_with("git@") {
            // SSH format: git@github.com:user/repo.git
            let parts: Vec<&str> = url.splitn(2, ':').collect();
            if parts.len() != 2 {
                return Err(ProjectManError::InvalidUrl("Invalid SSH URL format".to_string()));
            }
            
            let host = parts[0].trim_start_matches("git@");
            let repo_part = parts[1].trim_end_matches(".git");
            let path = format!("{}/{}", host, repo_part);
            
            Ok((url.to_string(), path))
        } else if url.starts_with("http") {
            // HTTPS format: https://github.com/user/repo.git
            let parsed_url = Url::parse(url)
                .map_err(|e| ProjectManError::InvalidUrl(format!("Invalid URL: {}", e)))?;
            
            let host = parsed_url.host_str()
                .ok_or_else(|| ProjectManError::InvalidUrl("No host in URL".to_string()))?;
            
            let path_segments: Vec<&str> = parsed_url.path()
                .trim_start_matches('/')
                .trim_end_matches(".git")
                .split('/')
                .collect();
            
            if path_segments.len() < 2 {
                return Err(ProjectManError::InvalidUrl("Invalid repository path".to_string()));
            }
            
            let repo_path = format!("{}/{}/{}", host, path_segments[0], path_segments[1]);
            
            Ok((url.to_string(), repo_path))
        } else {
            Err(ProjectManError::InvalidUrl("Unsupported URL format".to_string()))
        }
    }
}

#[derive(Debug)]
pub enum SyncResult {
    UpToDate,
    Updated { commits_pulled: usize },
    Conflict { ahead: usize, behind: usize },
}

#[derive(Debug)]
pub struct RepoStatus {
    pub is_clean: bool,
    pub ahead: usize,
    pub behind: usize,
}