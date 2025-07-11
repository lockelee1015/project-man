use crate::config::WorkspaceRegistry;
use crate::search::FuzzySearch;
use crate::error::Result;
use std::io::{self, Write};

pub async fn execute(pattern: &str) -> Result<()> {
    let mut workspace_registry = WorkspaceRegistry::load_from_workspace()?;
    let fuzzy_search = FuzzySearch::new();
    
    let repositories = workspace_registry.list_repositories();
    
    if repositories.is_empty() {
        println!("📋 No repositories found in workspace.");
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
        
        println!("📋 Repository to remove:");
        println!("   🔷 Name: {}", selected_repo.name);
        println!("   📁 Path: {}", full_path.display());
        println!("   🔗 URL: {}", selected_repo.repo_config.url);
        println!();
        
        // Confirm deletion
        print!("❓ Remove this repository from workspace? (y/N): ");
        io::stdout().flush()?;
        
        let mut input = String::new();
        io::stdin().read_line(&mut input)?;
        
        if input.trim().to_lowercase() != "y" {
            println!("❌ Operation cancelled.");
            return Ok(());
        }
        
        // Ask about local files
        print!("❓ Also delete local files? (y/N): ");
        io::stdout().flush()?;
        
        let mut input = String::new();
        io::stdin().read_line(&mut input)?;
        let delete_files = input.trim().to_lowercase() == "y";
        
        // Remove from registry
        workspace_registry.remove_repository(&selected_repo.name);
        workspace_registry.save()?;
        
        println!("✅ Repository removed from workspace registry.");
        
        // Delete local files if requested
        if delete_files {
            if full_path.exists() {
                std::fs::remove_dir_all(&full_path)?;
                println!("🗑️  Local files deleted: {}", full_path.display());
            } else {
                println!("ℹ️  Local directory not found (already deleted?)");
            }
        } else {
            println!("💾 Local files preserved: {}", full_path.display());
        }
    } else {
        println!("❌ No repository selected.");
    }
    
    Ok(())
}