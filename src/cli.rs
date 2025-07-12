use clap::{Parser, Subcommand};
use std::path::PathBuf;

#[derive(Parser)]
#[command(name = "p")]
#[command(about = "Project Man - A CLI tool for managing multiple code repositories")]
#[command(version = "0.1.0")]
pub struct Cli {
    #[command(subcommand)]
    pub command: Commands,
}

#[derive(Subcommand)]
pub enum Commands {
    #[command(about = "Initialize a new workspace")]
    Init {
        #[arg(help = "Path to the workspace directory")]
        path: PathBuf,
    },
    
    #[command(about = "Add a repository to the workspace")]
    Add {
        #[arg(help = "Repository URL or shorthand (e.g., user/repo)")]
        repository: String,
        #[arg(long, help = "Output directory path for shell integration")]
        output_cd: bool,
    },
    
    #[command(about = "Navigate to a repository")]
    Go {
        #[arg(help = "Repository pattern for fuzzy search (empty to go to workspace)")]
        pattern: Option<String>,
        #[arg(long, help = "Output directory path for shell integration")]
        output_cd: bool,
    },
    
    #[command(about = "List all repositories")]
    List,
    
    #[command(about = "Remove a repository from workspace")]
    Remove {
        #[arg(help = "Repository pattern to remove")]
        pattern: String,
    },
    
    #[command(about = "Synchronize repositories (pull updates)")]
    Sync {
        #[arg(help = "Optional repository pattern to sync")]
        pattern: Option<String>,
    },
    
    #[command(about = "Search across repositories")]
    Grep {
        #[arg(help = "Search pattern")]
        pattern: String,
        #[arg(help = "Optional repository pattern to limit search")]
        repo_pattern: Option<String>,
    },
    
    #[command(about = "Migrate existing repositories to workspace")]
    Migrate {
        #[arg(help = "Source directory containing repositories")]
        source: PathBuf,
    },
    
    #[command(about = "Manage configuration")]
    Config {
        #[command(subcommand)]
        subcommand: ConfigCommands,
    },
    
    #[command(about = "Show workspace status")]
    Status,
}

#[derive(Subcommand)]
pub enum ConfigCommands {
    #[command(about = "Show current configuration")]
    Show,
    
    #[command(about = "Set a configuration value")]
    Set {
        #[arg(help = "Configuration key")]
        key: String,
        #[arg(help = "Configuration value")]
        value: String,
    },
    
    #[command(about = "Get a configuration value")]
    Get {
        #[arg(help = "Configuration key")]
        key: String,
    },
}