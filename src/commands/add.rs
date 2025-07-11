use crate::config::{WorkspaceRegistry, RepositoryConfig, GlobalConfig};
use crate::git::GitManager;
use crate::error::Result;

pub async fn execute(repository: &str) -> Result<()> {
    let git_manager = GitManager::new()?;
    let mut workspace_registry = WorkspaceRegistry::load_from_workspace()?;
    let global_config = GlobalConfig::load()?;
    
    // Parse repository URL and get target path
    let (url, relative_path) = git_manager.parse_repository_url(repository)?;
    
    // Check if repository already exists
    let repo_name = relative_path.replace("/", "_");
    if workspace_registry.get_repository(&repo_name).is_some() {
        println!("❌ Repository '{}' already exists in workspace", repo_name);
        return Ok(());
    }
    
    // Create full target path
    let workspace_path = global_config.get_workspace_path();
    let target_path = workspace_path.join(&relative_path);
    
    // Check if directory already exists
    if target_path.exists() {
        println!("❌ Directory already exists: {}", target_path.display());
        return Ok(());
    }
    
    println!("🔄 Cloning repository...");
    println!("📦 Repository: {}", url);
    println!("📁 Target: {}", target_path.display());
    println!();
    
    // Clone the repository
    git_manager.clone_repository(&url, &target_path)?;
    
    // Add to workspace registry
    let repo_config = RepositoryConfig::new(
        relative_path.clone(),
        url.clone(),
        vec![], // No tags by default
    );
    
    workspace_registry.add_repository(repo_name.clone(), repo_config);
    workspace_registry.save()?;
    
    println!("✅ Repository added successfully!");
    println!("📝 Registry updated");
    
    // Output directory for shell integration
    println!("CD_TARGET:{}", target_path.display());
    
    Ok(())
}