use serde::{Deserialize, Serialize};
use std::path::PathBuf;
use crate::config::{WorkspaceConfig, GitConfig, SearchConfig, UiConfig, ensure_config_dir};
use crate::error::{ProjectManError, Result};

#[derive(Debug, Serialize, Deserialize)]
pub struct GlobalConfig {
    pub workspace: WorkspaceConfig,
    pub git: GitConfig,
    pub search: SearchConfig,
    pub ui: UiConfig,
}

impl GlobalConfig {
    pub fn load() -> Result<Self> {
        let config_dir = ensure_config_dir()?;
        let config_path = config_dir.join("config.toml");
        
        if !config_path.exists() {
            return Err(ProjectManError::Config(
                "Global configuration not found. Run 'p init <workspace>' to initialize.".to_string()
            ));
        }
        
        let content = std::fs::read_to_string(&config_path)?;
        let config: GlobalConfig = toml::from_str(&content)?;
        Ok(config)
    }
    
    pub fn save(&self) -> Result<()> {
        let config_dir = ensure_config_dir()?;
        let config_path = config_dir.join("config.toml");
        
        let content = toml::to_string_pretty(self)
            .map_err(|e| ProjectManError::Config(format!("Failed to serialize config: {}", e)))?;
        
        std::fs::write(&config_path, content)?;
        Ok(())
    }
    
    pub fn new(workspace_path: PathBuf) -> Self {
        Self {
            workspace: WorkspaceConfig {
                path: workspace_path,
                created_at: chrono::Utc::now(),
            },
            git: GitConfig::default(),
            search: SearchConfig::default(),
            ui: UiConfig::default(),
        }
    }
    
    pub fn get_workspace_path(&self) -> &PathBuf {
        &self.workspace.path
    }
    
    pub fn set_value(&mut self, key: &str, value: &str) -> Result<()> {
        match key {
            "git.default_host" => self.git.default_host = value.to_string(),
            "git.default_protocol" => {
                if value == "ssh" || value == "https" {
                    self.git.default_protocol = value.to_string();
                } else {
                    return Err(ProjectManError::Config(
                        "git.default_protocol must be 'ssh' or 'https'".to_string()
                    ));
                }
            }
            "search.fuzzy_threshold" => {
                self.search.fuzzy_threshold = value.parse()
                    .map_err(|_| ProjectManError::Config("Invalid fuzzy_threshold value".to_string()))?;
            }
            "search.max_results" => {
                self.search.max_results = value.parse()
                    .map_err(|_| ProjectManError::Config("Invalid max_results value".to_string()))?;
            }
            "search.case_sensitive" => {
                self.search.case_sensitive = value.parse()
                    .map_err(|_| ProjectManError::Config("Invalid case_sensitive value".to_string()))?;
            }
            "ui.confirm_destructive_actions" => {
                self.ui.confirm_destructive_actions = value.parse()
                    .map_err(|_| ProjectManError::Config("Invalid confirm_destructive_actions value".to_string()))?;
            }
            "ui.use_colors" => {
                self.ui.use_colors = value.parse()
                    .map_err(|_| ProjectManError::Config("Invalid use_colors value".to_string()))?;
            }
            "ui.pager" => self.ui.pager = value.to_string(),
            _ => return Err(ProjectManError::Config(format!("Unknown configuration key: {}", key))),
        }
        Ok(())
    }
    
    pub fn get_value(&self, key: &str) -> Result<String> {
        let value = match key {
            "workspace.path" => self.workspace.path.to_string_lossy().to_string(),
            "workspace.created_at" => self.workspace.created_at.to_rfc3339(),
            "git.default_host" => self.git.default_host.clone(),
            "git.default_protocol" => self.git.default_protocol.clone(),
            "search.fuzzy_threshold" => self.search.fuzzy_threshold.to_string(),
            "search.max_results" => self.search.max_results.to_string(),
            "search.case_sensitive" => self.search.case_sensitive.to_string(),
            "ui.confirm_destructive_actions" => self.ui.confirm_destructive_actions.to_string(),
            "ui.use_colors" => self.ui.use_colors.to_string(),
            "ui.pager" => self.ui.pager.clone(),
            _ => return Err(ProjectManError::Config(format!("Unknown configuration key: {}", key))),
        };
        Ok(value)
    }
}