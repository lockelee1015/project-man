use fuzzy_matcher::{skim::SkimMatcherV2, FuzzyMatcher};
use std::io::{self, Write};
use crossterm::{
    cursor,
    event::{self, Event, KeyCode, KeyEvent},
    execute,
    style::{Color, Print, ResetColor, SetForegroundColor},
    terminal::{self, ClearType},
};
use crate::config::RepositoryConfig;
use crate::error::Result;

pub struct SearchResult {
    pub name: String,
    pub repo_config: RepositoryConfig,
    pub score: i64,
}

pub struct FuzzySearch {
    matcher: SkimMatcherV2,
}

impl FuzzySearch {
    pub fn new() -> Self {
        Self {
            matcher: SkimMatcherV2::default(),
        }
    }
    
    pub fn search(&self, repositories: &[(String, RepositoryConfig)], pattern: &str) -> Vec<SearchResult> {
        let mut results: Vec<SearchResult> = repositories
            .iter()
            .filter_map(|(name, repo_config)| {
                let score = self.matcher.fuzzy_match(name, pattern)?;
                Some(SearchResult {
                    name: name.clone(),
                    repo_config: repo_config.clone(),
                    score,
                })
            })
            .collect();
        
        // Sort by score (descending)
        results.sort_by(|a, b| b.score.cmp(&a.score));
        
        results
    }
    
    pub fn interactive_select(&self, candidates: Vec<SearchResult>) -> Result<Option<SearchResult>> {
        if candidates.is_empty() {
            return Ok(None);
        }
        
        if candidates.len() == 1 {
            return Ok(Some(candidates.into_iter().next().unwrap()));
        }
        
        // Enable raw mode for interactive selection
        terminal::enable_raw_mode()?;
        
        let mut selected = 0;
        let result = loop {
            // Clear screen and move cursor to top
            execute!(
                io::stdout(),
                terminal::Clear(ClearType::All),
                cursor::MoveTo(0, 0)
            )?;
            
            // Display header
            execute!(
                io::stdout(),
                SetForegroundColor(Color::Yellow),
                Print("📋 Select a repository (use ↑/↓ to navigate, Enter to select, Esc to cancel):\n\n"),
                ResetColor
            )?;
            
            // Display candidates
            for (i, candidate) in candidates.iter().enumerate() {
                let prefix = if i == selected { "➤ " } else { "  " };
                let color = if i == selected { Color::Green } else { Color::White };
                
                execute!(
                    io::stdout(),
                    SetForegroundColor(color),
                    Print(format!("{}{}\n", prefix, candidate.name)),
                    ResetColor
                )?;
                
                // Show path for selected item
                if i == selected {
                    execute!(
                        io::stdout(),
                        SetForegroundColor(Color::DarkGrey),
                        Print(format!("    📁 {}\n", candidate.repo_config.path)),
                        ResetColor
                    )?;
                }
            }
            
            io::stdout().flush()?;
            
            // Handle input
            if let Event::Key(KeyEvent { code, .. }) = event::read()? {
                match code {
                    KeyCode::Up => {
                        if selected > 0 {
                            selected -= 1;
                        }
                    }
                    KeyCode::Down => {
                        if selected < candidates.len() - 1 {
                            selected += 1;
                        }
                    }
                    KeyCode::Enter => {
                        break Some(candidates[selected].clone());
                    }
                    KeyCode::Esc => {
                        break None;
                    }
                    _ => {}
                }
            }
        };
        
        // Disable raw mode
        terminal::disable_raw_mode()?;
        
        // Clear screen
        execute!(
            io::stdout(),
            terminal::Clear(ClearType::All),
            cursor::MoveTo(0, 0)
        )?;
        
        Ok(result)
    }
}

impl Clone for SearchResult {
    fn clone(&self) -> Self {
        Self {
            name: self.name.clone(),
            repo_config: self.repo_config.clone(),
            score: self.score,
        }
    }
}