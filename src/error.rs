use thiserror::Error;

#[derive(Error, Debug)]
pub enum ProjectManError {
    #[error("Configuration error: {0}")]
    Config(String),
    
    #[error("Git operation failed: {0}")]
    Git(String),
    
    #[error("Repository not found: {0}")]
    RepositoryNotFound(String),
    
    #[error("Workspace not found. Run 'p init <path>' to initialize a workspace")]
    WorkspaceNotFound,
    
    #[error("Invalid repository URL: {0}")]
    InvalidUrl(String),
    
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),
    
    #[error("YAML parsing error: {0}")]
    Yaml(#[from] serde_yaml::Error),
    
    #[error("TOML parsing error: {0}")]
    Toml(#[from] toml::de::Error),
    
}

pub type Result<T> = std::result::Result<T, ProjectManError>;