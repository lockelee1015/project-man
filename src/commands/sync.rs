use crate::config::WorkspaceRegistry;
use crate::git::{GitManager, SyncResult};
use crate::search::FuzzySearch;
use crate::error::Result;

pub async fn execute(pattern: Option<&str>) -> Result<()> {
    let mut workspace_registry = WorkspaceRegistry::load_from_workspace()?;
    let git_manager = GitManager::new()?;
    
    let repositories = workspace_registry.list_repositories();
    
    if repositories.is_empty() {
        println!("📋 No repositories found in workspace.");
        return Ok(());
    }
    
    let repos_to_sync: Vec<(String, _)> = if let Some(pattern) = pattern {
        // Filter repositories by pattern
        let fuzzy_search = FuzzySearch::new();
        let owned_repos: Vec<(String, _)> = repositories
            .into_iter()
            .map(|(name, config)| (name.clone(), config.clone()))
            .collect();
        
        let results = fuzzy_search.search(&owned_repos, pattern);
        
        if results.is_empty() {
            println!("❌ No repositories found matching '{}'", pattern);
            return Ok(());
        }
        
        results.into_iter()
            .map(|r| (r.name, r.repo_config))
            .collect()
    } else {
        // Sync all repositories
        repositories.into_iter()
            .map(|(name, config)| (name.clone(), config.clone()))
            .collect()
    };
    
    println!("🔄 Synchronizing {} repositories...", repos_to_sync.len());
    println!();
    
    let mut success_count = 0;
    let mut error_count = 0;
    
    for (name, repo_config) in repos_to_sync {
        let full_path = workspace_registry.get_full_path(&repo_config)?;
        
        print!("🔄 Syncing {}: ", name);
        std::io::Write::flush(&mut std::io::stdout()).unwrap();
        
        if !full_path.exists() {
            println!("❌ Directory not found");
            error_count += 1;
            continue;
        }
        
        match git_manager.sync_repository(&full_path) {
            Ok(SyncResult::UpToDate) => {
                println!("✅ Up to date");
                success_count += 1;
            }
            Ok(SyncResult::Updated { commits_pulled }) => {
                println!("✅ Updated ({} commits)", commits_pulled);
                // Update last sync time
                if let Err(e) = workspace_registry.update_last_sync(&name) {
                    eprintln!("⚠️  Failed to update sync time: {}", e);
                }
                success_count += 1;
            }
            Ok(SyncResult::Conflict { ahead, behind }) => {
                println!("⚠️  Conflict (ahead: {}, behind: {})", ahead, behind);
                println!("   💡 Manual merge required");
                error_count += 1;
            }
            Err(e) => {
                println!("❌ Failed: {}", e);
                error_count += 1;
            }
        }
    }
    
    // Save registry if any syncs were successful
    if success_count > 0 {
        workspace_registry.save()?;
    }
    
    println!();
    println!("📊 Sync Summary:");
    println!("   ✅ Successful: {}", success_count);
    println!("   ❌ Failed: {}", error_count);
    
    if error_count > 0 {
        println!("💡 Use 'p list' to check repository status");
    }
    
    Ok(())
}