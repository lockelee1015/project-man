use crate::config::WorkspaceRegistry;
use crate::search::FuzzySearch;
use crate::error::Result;
use std::process::Command;

pub async fn execute(pattern: &str, repo_pattern: Option<&str>) -> Result<()> {
    let workspace_registry = WorkspaceRegistry::load_from_workspace()?;
    
    let repositories = workspace_registry.list_repositories();
    
    if repositories.is_empty() {
        println!("📋 No repositories found in workspace.");
        return Ok(());
    }
    
    let repos_to_search: Vec<(String, _)> = if let Some(repo_pattern) = repo_pattern {
        // Filter repositories by pattern
        let fuzzy_search = FuzzySearch::new();
        let owned_repos: Vec<(String, _)> = repositories
            .into_iter()
            .map(|(name, config)| (name.clone(), config.clone()))
            .collect();
        
        let results = fuzzy_search.search(&owned_repos, repo_pattern);
        
        if results.is_empty() {
            println!("❌ No repositories found matching '{}'", repo_pattern);
            return Ok(());
        }
        
        results.into_iter()
            .map(|r| (r.name, r.repo_config))
            .collect()
    } else {
        // Search all repositories
        repositories.into_iter()
            .map(|(name, config)| (name.clone(), config.clone()))
            .collect()
    };
    
    println!("🔍 Searching for '{}' in {} repositories...", pattern, repos_to_search.len());
    println!();
    
    let mut total_matches = 0;
    let mut repo_with_matches = 0;
    
    let total_repos = repos_to_search.len();
    
    for (name, repo_config) in repos_to_search {
        let full_path = workspace_registry.get_full_path(&repo_config)?;
        
        if !full_path.exists() {
            eprintln!("⚠️  Skipping {} (directory not found)", name);
            continue;
        }
        
        // Try ripgrep first, fallback to grep
        let search_result = if which::which("rg").is_ok() {
            search_with_ripgrep(pattern, &full_path, &name)
        } else if which::which("grep").is_ok() {
            search_with_grep(pattern, &full_path, &name)
        } else {
            println!("❌ Neither 'rg' (ripgrep) nor 'grep' found in PATH");
            return Ok(());
        };
        
        match search_result {
            Ok(matches) => {
                if matches > 0 {
                    repo_with_matches += 1;
                    total_matches += matches;
                }
            }
            Err(e) => {
                eprintln!("⚠️  Error searching in {}: {}", name, e);
            }
        }
    }
    
    println!();
    println!("📊 Search Summary:");
    println!("   🔍 Pattern: '{}'", pattern);
    println!("   📁 Repositories searched: {}", total_repos);
    println!("   ✅ Repositories with matches: {}", repo_with_matches);
    println!("   🎯 Total matches: {}", total_matches);
    
    Ok(())
}

fn search_with_ripgrep(pattern: &str, path: &std::path::Path, repo_name: &str) -> Result<usize> {
    let output = Command::new("rg")
        .arg("--color=always")
        .arg("--heading")
        .arg("--line-number")
        .arg("--smart-case")
        .arg("--no-ignore")  // Don't respect .gitignore for comprehensive search
        .arg(pattern)
        .arg(path)
        .output()?;
    
    if output.status.success() && !output.stdout.is_empty() {
        let stdout = String::from_utf8_lossy(&output.stdout);
        let lines: Vec<&str> = stdout.lines().collect();
        let match_count = lines.iter()
            .filter(|line| !line.is_empty() && !line.starts_with(&format!("{}:", path.display())))
            .count();
        
        if match_count > 0 {
            println!("🔷 {} ({} matches):", repo_name, match_count);
            println!("{}", stdout.trim());
            println!();
        }
        
        Ok(match_count)
    } else {
        Ok(0)
    }
}

fn search_with_grep(pattern: &str, path: &std::path::Path, repo_name: &str) -> Result<usize> {
    let output = Command::new("grep")
        .arg("-r")
        .arg("-n")
        .arg("--color=always")
        .arg("-i")  // Case insensitive
        .arg(pattern)
        .arg(path)
        .output()?;
    
    if output.status.success() && !output.stdout.is_empty() {
        let stdout = String::from_utf8_lossy(&output.stdout);
        let lines: Vec<&str> = stdout.lines().collect();
        let match_count = lines.len();
        
        if match_count > 0 {
            println!("🔷 {} ({} matches):", repo_name, match_count);
            
            // Group matches by file
            let mut current_file = String::new();
            for line in lines {
                if let Some(colon_pos) = line.find(':') {
                    let file_part = &line[..colon_pos];
                    let stripped_path = file_part.strip_prefix(&path.to_string_lossy().to_string())
                        .unwrap_or(file_part)
                        .trim_start_matches('/');
                    
                    if stripped_path != current_file {
                        current_file = stripped_path.to_string();
                        println!("📄 {}", stripped_path);
                    }
                    
                    // Show the match with line number
                    if let Some(second_colon) = line[colon_pos + 1..].find(':') {
                        let line_num = &line[colon_pos + 1..colon_pos + 1 + second_colon];
                        let content = &line[colon_pos + 2 + second_colon..];
                        println!("   {}:{}", line_num, content.trim());
                    }
                }
            }
            println!();
        }
        
        Ok(match_count)
    } else {
        Ok(0)
    }
}