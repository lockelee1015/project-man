use crate::config::{WorkspaceRegistry, RepositoryConfig, GlobalConfig};
use crate::git::GitManager;
use crate::error::Result;
use std::path::Path;
use std::fs;

pub async fn execute(source_path: &Path) -> Result<()> {
    let mut workspace_registry = WorkspaceRegistry::load_from_workspace()?;
    let global_config = GlobalConfig::load()?;
    let git_manager = GitManager::new()?;
    
    if !source_path.exists() {
        println!("❌ Source directory does not exist: {}", source_path.display());
        return Ok(());
    }
    
    println!("🔍 Scanning for Git repositories in: {}", source_path.display());
    
    let repositories = find_git_repositories(source_path)?;
    
    if repositories.is_empty() {
        println!("📋 No Git repositories found in source directory.");
        return Ok(());
    }
    
    println!("📦 Found {} Git repositories:", repositories.len());
    for repo_path in &repositories {
        println!("   📁 {}", repo_path.display());
    }
    println!();
    
    // Confirm migration
    print!("❓ Migrate these repositories to workspace? (y/N): ");
    std::io::Write::flush(&mut std::io::stdout()).unwrap();
    
    let mut input = String::new();
    std::io::stdin().read_line(&mut input)?;
    
    if input.trim().to_lowercase() != "y" {
        println!("❌ Migration cancelled.");
        return Ok(());
    }
    
    let workspace_path = global_config.get_workspace_path();
    let mut migrated_count = 0;
    let mut skipped_count = 0;
    
    for repo_path in repositories {
        println!("🔄 Processing: {}", repo_path.display());
        
        // Try to determine repository info
        let (repo_name, repo_url, target_path) = match analyze_repository(&repo_path, &git_manager) {
            Ok(info) => info,
            Err(e) => {
                println!("   ⚠️  Skipping: {}", e);
                skipped_count += 1;
                continue;
            }
        };
        
        let full_target_path = workspace_path.join(&target_path);
        
        // Check if target already exists
        if full_target_path.exists() {
            println!("   ⚠️  Target already exists: {}", full_target_path.display());
            skipped_count += 1;
            continue;
        }
        
        // Check if repository is already in registry
        if workspace_registry.get_repository(&repo_name).is_some() {
            println!("   ⚠️  Repository '{}' already in workspace", repo_name);
            skipped_count += 1;
            continue;
        }
        
        // Create target directory structure
        if let Some(parent) = full_target_path.parent() {
            fs::create_dir_all(parent)?;
        }
        
        // Move the repository
        if repo_path == std::path::Path::new(".") {
            // Special case: migrating current directory
            // We need to move contents instead of the directory itself
            fs::create_dir_all(&full_target_path)?;
            
            // Copy git directory and other contents
            copy_directory_contents(&repo_path, &full_target_path)?;
            
            println!("   ✅ Contents copied to: {}", full_target_path.display());
            println!("   📝 Note: Original directory preserved (current working directory)");
        } else {
            fs::rename(&repo_path, &full_target_path)?;
            println!("   ✅ Moved to: {}", full_target_path.display());
        }
        
        // Add to registry
        let repo_config = RepositoryConfig::new(
            target_path,
            repo_url,
            vec!["migrated".to_string()],
        );
        
        workspace_registry.add_repository(repo_name, repo_config);
        migrated_count += 1;
    }
    
    // Save registry
    workspace_registry.save()?;
    
    println!();
    println!("📊 Migration Summary:");
    println!("   ✅ Migrated: {}", migrated_count);
    println!("   ⚠️  Skipped: {}", skipped_count);
    println!("📝 Workspace registry updated");
    
    Ok(())
}

fn find_git_repositories(dir: &Path) -> Result<Vec<std::path::PathBuf>> {
    let mut repositories = Vec::new();
    
    fn scan_directory(dir: &Path, repositories: &mut Vec<std::path::PathBuf>) -> Result<()> {
        if dir.join(".git").exists() {
            repositories.push(dir.to_path_buf());
            return Ok(()); // Don't recurse into git repos
        }
        
        if let Ok(entries) = fs::read_dir(dir) {
            for entry in entries {
                if let Ok(entry) = entry {
                    let path = entry.path();
                    if path.is_dir() && !path.file_name().unwrap_or_default().to_string_lossy().starts_with('.') {
                        let _ = scan_directory(&path, repositories);
                    }
                }
            }
        }
        
        Ok(())
    }
    
    scan_directory(dir, &mut repositories)?;
    Ok(repositories)
}

fn analyze_repository(repo_path: &Path, git_manager: &GitManager) -> Result<(String, String, String)> {
    use std::process::Command;
    
    // Get remote origin URL using git command
    let output = Command::new("git")
        .arg("remote")
        .arg("get-url")
        .arg("origin")
        .current_dir(repo_path)
        .output()
        .map_err(|e| crate::error::ProjectManError::Git(format!("Failed to get remote URL: {}", e)))?;
    
    if !output.status.success() {
        return Err(crate::error::ProjectManError::Git("No origin remote found".to_string()));
    }
    
    let url = String::from_utf8_lossy(&output.stdout).trim().to_string();
    
    if url.is_empty() {
        return Err(crate::error::ProjectManError::Git("Origin URL not found".to_string()));
    }
    
    // Parse URL to get target path
    let (_, target_path) = git_manager.parse_repository_url(&url)?;
    
    // Generate repository name
    let repo_name = target_path.replace("/", "_");
    
    Ok((repo_name, url, target_path))
}

fn copy_directory_contents(src: &Path, dst: &Path) -> Result<()> {
    for entry in fs::read_dir(src)? {
        let entry = entry?;
        let src_path = entry.path();
        let dst_path = dst.join(entry.file_name());
        
        if src_path.is_dir() {
            fs::create_dir_all(&dst_path)?;
            copy_directory_contents(&src_path, &dst_path)?;
        } else {
            fs::copy(&src_path, &dst_path)?;
        }
    }
    Ok(())
}