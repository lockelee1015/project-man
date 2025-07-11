use anyhow::Result;
use clap::Parser;

mod cli;
mod config;
mod git;
mod search;
mod commands;
mod error;

use cli::Cli;
use commands::Commands;

#[tokio::main]
async fn main() -> Result<()> {
    let cli = Cli::parse();
    
    let result = match cli.command {
        Commands::Init { path } => commands::init::execute(&path).await,
        Commands::Add { repository } => commands::add::execute(&repository).await,
        Commands::Go { pattern, output_cd } => commands::go::execute(pattern.as_deref(), output_cd).await,
        Commands::List => commands::list::execute().await,
        Commands::Remove { pattern } => commands::remove::execute(&pattern).await,
        Commands::Sync { pattern } => commands::sync::execute(pattern.as_deref()).await,
        Commands::Grep { pattern, repo_pattern } => commands::grep::execute(&pattern, repo_pattern.as_deref()).await,
        Commands::Migrate { source } => commands::migrate::execute(&source).await,
        Commands::Config { subcommand } => commands::config::execute(subcommand).await,
        Commands::Status => commands::status::execute().await,
    };
    
    match result {
        Ok(()) => Ok(()),
        Err(e) => Err(anyhow::anyhow!("{}", e)),
    }
}
