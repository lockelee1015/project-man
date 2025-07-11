use crate::config::{WorkspaceRegistry, GlobalConfig};
use crate::search::FuzzySearch;
use crate::error::Result;

pub async fn execute(pattern: Option<&str>, output_cd: bool) -> Result<()> {
    let workspace_registry = WorkspaceRegistry::load_from_workspace()?;
    
    // If no pattern provided, go to workspace root
    if pattern.is_none() {
        let global_config = GlobalConfig::load()?;
        let workspace_path = global_config.get_workspace_path();
        
        if !workspace_path.exists() {
            println!("❌ Workspace directory does not exist: {}", workspace_path.display());
            return Ok(());
        }
        
        if output_cd {
            println!("CD_TARGET:{}", workspace_path.display());
        } else {
            println!("📁 Workspace: {}", workspace_path.display());
        }
        return Ok(());
    }
    
    let pattern = pattern.unwrap();
    let fuzzy_search = FuzzySearch::new();
    
    let repositories = workspace_registry.list_repositories();
    
    if repositories.is_empty() {
        println!("📋 No repositories found in workspace.");
        println!("💡 Use 'p add <repository>' to add repositories.");
        return Ok(());
    }
    
    // Convert to owned data for search
    let owned_repos: Vec<(String, _)> = repositories
        .into_iter()
        .map(|(name, config)| (name.clone(), config.clone()))
        .collect();
    
    // Perform fuzzy search
    let results = fuzzy_search.search(&owned_repos, pattern);
    
    if results.is_empty() {
        println!("❌ No repositories found matching '{}'", pattern);
        return Ok(());
    }
    
    // Select repository (interactive if multiple matches)
    let selected = if results.len() == 1 {
        Some(results.into_iter().next().unwrap())
    } else {
        fuzzy_search.interactive_select(results)?
    };
    
    if let Some(selected_repo) = selected {
        let full_path = workspace_registry.get_full_path(&selected_repo.repo_config)?;
        
        if !full_path.exists() {
            println!("❌ Repository directory does not exist: {}", full_path.display());
            return Ok(());
        }
        
        if output_cd {
            // Output for shell integration
            println!("CD_TARGET:{}", full_path.display());
        } else {
            println!("📁 Repository: {}", selected_repo.name);
            println!("📍 Path: {}", full_path.display());
            println!("🔗 URL: {}", selected_repo.repo_config.url);
        }
    } else {
        println!("❌ No repository selected.");
    }
    
    Ok(())
}