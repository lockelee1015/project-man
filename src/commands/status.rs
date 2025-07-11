use crate::config::{GlobalConfig, WorkspaceRegistry};
use crate::git::GitManager;
use crate::error::Result;

pub async fn execute() -> Result<()> {
    let global_config = GlobalConfig::load()?;
    let workspace_registry = WorkspaceRegistry::load_from_workspace()?;
    let git_manager = GitManager::new()?;
    
    println!("📊 Project Man Status");
    println!();
    
    // Workspace info
    println!("📁 Workspace:");
    let workspace_path = global_config.get_workspace_path();
    println!("   Path: {}", workspace_path.display());
    
    if workspace_path.exists() {
        println!("   Status: ✅ Exists");
    } else {
        println!("   Status: ❌ Directory not found");
        println!("   💡 Run 'p init <path>' to recreate workspace");
        return Ok(());
    }
    
    println!("   Created: {}", global_config.workspace.created_at.format("%Y-%m-%d %H:%M:%S UTC"));
    println!();
    
    // Repository statistics
    let repositories = workspace_registry.list_repositories();
    println!("📦 Repositories:");
    println!("   Total: {}", repositories.len());
    
    if repositories.is_empty() {
        println!("   💡 Use 'p add <repository>' to add repositories");
        return Ok(());
    }
    
    let mut clean_count = 0;
    let mut dirty_count = 0;
    let mut ahead_count = 0;
    let mut behind_count = 0;
    let mut missing_count = 0;
    let mut error_count = 0;
    
    for (_, repo_config) in &repositories {
        let full_path = workspace_registry.get_full_path(repo_config)?;
        
        if !full_path.exists() {
            missing_count += 1;
            continue;
        }
        
        match git_manager.get_repository_status(&full_path) {
            Ok(status) => {
                if status.is_clean {
                    clean_count += 1;
                } else {
                    dirty_count += 1;
                }
                
                if status.ahead > 0 {
                    ahead_count += 1;
                }
                
                if status.behind > 0 {
                    behind_count += 1;
                }
            }
            Err(_) => {
                error_count += 1;
            }
        }
    }
    
    println!("   Clean: {}", clean_count);
    if dirty_count > 0 {
        println!("   Dirty: {}", dirty_count);
    }
    if ahead_count > 0 {
        println!("   Ahead of remote: {}", ahead_count);
    }
    if behind_count > 0 {
        println!("   Behind remote: {}", behind_count);
    }
    if missing_count > 0 {
        println!("   Missing directories: {}", missing_count);
    }
    if error_count > 0 {
        println!("   Errors: {}", error_count);
    }
    println!();
    
    // Configuration info
    println!("⚙️  Configuration:");
    println!("   Global config: ~/.config/project-man/config.toml");
    println!("   Workspace registry: {}/project-man.yml", workspace_path.display());
    println!("   Default git host: {}", global_config.git.default_host);
    println!("   Default protocol: {}", global_config.git.default_protocol);
    println!();
    
    // Recommendations
    if dirty_count > 0 || ahead_count > 0 {
        println!("💡 Recommendations:");
        if dirty_count > 0 {
            println!("   • Use 'p list' to see which repositories have uncommitted changes");
        }
        if ahead_count > 0 {
            println!("   • Consider pushing your local commits");
        }
        if behind_count > 0 {
            println!("   • Use 'p sync' to pull latest changes");
        }
        if missing_count > 0 {
            println!("   • Use 'p remove <pattern>' to clean up missing repositories");
        }
    }
    
    Ok(())
}