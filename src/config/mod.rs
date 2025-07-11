use serde::{Deserialize, Serialize};
use std::path::PathBuf;
use chrono::{DateTime, Utc};
use crate::error::{ProjectManError, Result};

pub mod global;
pub mod workspace;

pub use global::GlobalConfig;
pub use workspace::{WorkspaceRegistry, RepositoryConfig};

#[derive(Debug, Serialize, Deserialize)]
pub struct WorkspaceConfig {
    pub path: PathBuf,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct GitConfig {
    pub default_host: String,
    pub default_protocol: String,
    pub ssh_key_path: Option<PathBuf>,
}

impl Default for GitConfig {
    fn default() -> Self {
        Self {
            default_host: "github.com".to_string(),
            default_protocol: "ssh".to_string(),
            ssh_key_path: None,
        }
    }
}

#[derive(Debug, Serialize, Deserialize)]
pub struct SearchConfig {
    pub fuzzy_threshold: f64,
    pub max_results: usize,
    pub case_sensitive: bool,
}

impl Default for SearchConfig {
    fn default() -> Self {
        Self {
            fuzzy_threshold: 0.6,
            max_results: 10,
            case_sensitive: false,
        }
    }
}

#[derive(Debug, Serialize, Deserialize)]
pub struct UiConfig {
    pub confirm_destructive_actions: bool,
    pub use_colors: bool,
    pub pager: String,
}

impl Default for UiConfig {
    fn default() -> Self {
        Self {
            confirm_destructive_actions: true,
            use_colors: true,
            pager: "less".to_string(),
        }
    }
}

pub fn get_config_dir() -> Result<PathBuf> {
    dirs::config_dir()
        .map(|dir| dir.join("project-man"))
        .ok_or_else(|| ProjectManError::Config("Could not determine config directory".to_string()))
}

pub fn ensure_config_dir() -> Result<PathBuf> {
    let config_dir = get_config_dir()?;
    std::fs::create_dir_all(&config_dir)?;
    Ok(config_dir)
}