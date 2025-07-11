use crate::config::WorkspaceRegistry;
use crate::git::GitManager;
use crate::error::Result;
use chrono::{DateTime, Utc};

pub async fn execute() -> Result<()> {
    let workspace_registry = WorkspaceRegistry::load_from_workspace()?;
    let git_manager = GitManager::new()?;
    
    let repositories = workspace_registry.list_repositories();
    
    if repositories.is_empty() {
        println!("📋 No repositories found in workspace.");
        println!("💡 Use 'p add <repository>' to add repositories.");
        return Ok(());
    }
    
    println!("📋 Repositories in workspace:");
    println!();
    
    for (name, repo_config) in &repositories {
        let full_path = workspace_registry.get_full_path(repo_config)?;
        
        // Get repository status
        let status = if full_path.exists() {
            match git_manager.get_repository_status(&full_path) {
                Ok(status) => {
                    let mut status_parts = vec![];
                    
                    if !status.is_clean {
                        status_parts.push("dirty".to_string());
                    }
                    
                    if status.ahead > 0 {
                        status_parts.push(format!("ahead {}", status.ahead));
                    }
                    
                    if status.behind > 0 {
                        status_parts.push(format!("behind {}", status.behind));
                    }
                    
                    if status_parts.is_empty() {
                        "clean".to_string()
                    } else {
                        status_parts.join(", ")
                    }
                }
                Err(_) => "unknown".to_string(),
            }
        } else {
            "missing".to_string()
        };
        
        // Format last sync time
        let last_sync = repo_config.last_sync
            .map(|dt| format_relative_time(dt))
            .unwrap_or_else(|| "never".to_string());
        
        // Display repository info
        println!("🔷 {}", name);
        println!("   📁 {}", full_path.display());
        println!("   🔗 {}", repo_config.url);
        println!("   📊 Status: {}", status);
        println!("   🔄 Last sync: {}", last_sync);
        
        if !repo_config.tags.is_empty() {
            println!("   🏷️  Tags: {}", repo_config.tags.join(", "));
        }
        
        println!();
    }
    
    println!("📊 Total repositories: {}", repositories.len());
    
    Ok(())
}

fn format_relative_time(dt: DateTime<Utc>) -> String {
    let now = Utc::now();
    let duration = now.signed_duration_since(dt);
    
    if duration.num_seconds() < 60 {
        "just now".to_string()
    } else if duration.num_minutes() < 60 {
        format!("{} minutes ago", duration.num_minutes())
    } else if duration.num_hours() < 24 {
        format!("{} hours ago", duration.num_hours())
    } else if duration.num_days() < 7 {
        format!("{} days ago", duration.num_days())
    } else if duration.num_weeks() < 4 {
        format!("{} weeks ago", duration.num_weeks())
    } else {
        format!("{} months ago", duration.num_days() / 30)
    }
}