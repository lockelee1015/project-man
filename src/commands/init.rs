use std::path::Path;
use crate::config::{GlobalConfig, WorkspaceRegistry};
use crate::error::Result;

pub async fn execute(workspace_path: &Path) -> Result<()> {
    // Convert to absolute path
    let workspace_path = workspace_path.canonicalize()
        .unwrap_or_else(|_| workspace_path.to_path_buf());
    
    // Create the workspace directory if it doesn't exist
    std::fs::create_dir_all(&workspace_path)?;
    
    // Create global configuration
    let global_config = GlobalConfig::new(workspace_path.clone());
    global_config.save()?;
    
    // Create workspace registry
    let mut workspace_registry = WorkspaceRegistry::new();
    workspace_registry.save()?;
    
    println!("✅ Workspace initialized successfully!");
    println!("📁 Workspace path: {}", workspace_path.display());
    println!("⚙️  Global config: ~/.config/project-man/config.toml");
    println!("📋 Workspace registry: {}/project-man.yml", workspace_path.display());
    
    Ok(())
}