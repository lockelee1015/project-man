use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::path::PathBuf;
use chrono::{DateTime, Utc};
use crate::error::{ProjectManError, Result};
use crate::config::GlobalConfig;

#[derive(Debug, Serialize, Deserialize)]
pub struct WorkspaceRegistry {
    pub version: String,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    pub repositories: HashMap<String, RepositoryConfig>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct RepositoryConfig {
    pub path: String,
    pub url: String,
    pub added_at: DateTime<Utc>,
    pub last_sync: Option<DateTime<Utc>>,
    pub tags: Vec<String>,
}

impl WorkspaceRegistry {
    pub fn new() -> Self {
        let now = Utc::now();
        Self {
            version: "1.0".to_string(),
            created_at: now,
            updated_at: now,
            repositories: HashMap::new(),
        }
    }
    
    pub fn load_from_workspace() -> Result<Self> {
        let global_config = GlobalConfig::load()?;
        let workspace_path = global_config.get_workspace_path();
        
        if !workspace_path.exists() {
            return Err(ProjectManError::WorkspaceNotFound);
        }
        
        let registry_path = workspace_path.join("project-man.yml");
        
        if !registry_path.exists() {
            return Ok(Self::new());
        }
        
        let content = std::fs::read_to_string(&registry_path)?;
        let mut registry: WorkspaceRegistry = serde_yaml::from_str(&content)?;
        
        // Validate that all repository paths exist
        registry.repositories.retain(|_, repo| {
            workspace_path.join(&repo.path).exists()
        });
        
        Ok(registry)
    }
    
    pub fn save(&mut self) -> Result<()> {
        let global_config = GlobalConfig::load()?;
        let workspace_path = global_config.get_workspace_path();
        
        if !workspace_path.exists() {
            return Err(ProjectManError::WorkspaceNotFound);
        }
        
        self.updated_at = Utc::now();
        
        let registry_path = workspace_path.join("project-man.yml");
        let content = serde_yaml::to_string(self)?;
        
        std::fs::write(&registry_path, content)?;
        Ok(())
    }
    
    pub fn add_repository(&mut self, name: String, config: RepositoryConfig) {
        self.repositories.insert(name, config);
        self.updated_at = Utc::now();
    }
    
    pub fn remove_repository(&mut self, name: &str) -> Option<RepositoryConfig> {
        let result = self.repositories.remove(name);
        if result.is_some() {
            self.updated_at = Utc::now();
        }
        result
    }
    
    pub fn get_repository(&self, name: &str) -> Option<&RepositoryConfig> {
        self.repositories.get(name)
    }
    
    pub fn list_repositories(&self) -> Vec<(&String, &RepositoryConfig)> {
        self.repositories.iter().collect()
    }
    
    #[allow(dead_code)]
    pub fn find_repositories(&self, pattern: &str) -> Vec<(&String, &RepositoryConfig)> {
        self.repositories
            .iter()
            .filter(|(name, _)| {
                name.to_lowercase().contains(&pattern.to_lowercase())
            })
            .collect()
    }
    
    pub fn update_last_sync(&mut self, name: &str) -> Result<()> {
        if let Some(repo) = self.repositories.get_mut(name) {
            repo.last_sync = Some(Utc::now());
            self.updated_at = Utc::now();
            Ok(())
        } else {
            Err(ProjectManError::RepositoryNotFound(name.to_string()))
        }
    }
    
    pub fn get_full_path(&self, repo_config: &RepositoryConfig) -> Result<PathBuf> {
        let global_config = GlobalConfig::load()?;
        let workspace_path = global_config.get_workspace_path();
        Ok(workspace_path.join(&repo_config.path))
    }
}

impl RepositoryConfig {
    pub fn new(path: String, url: String, tags: Vec<String>) -> Self {
        Self {
            path,
            url,
            added_at: Utc::now(),
            last_sync: None,
            tags,
        }
    }
}