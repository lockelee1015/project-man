use crate::config::GlobalConfig;
use crate::cli::ConfigCommands;
use crate::error::Result;

pub async fn execute(subcommand: ConfigCommands) -> Result<()> {
    match subcommand {
        ConfigCommands::Show => show_config().await,
        ConfigCommands::Set { key, value } => set_config(&key, &value).await,
        ConfigCommands::Get { key } => get_config(&key).await,
    }
}

async fn show_config() -> Result<()> {
    let config = GlobalConfig::load()?;
    
    println!("⚙️  Project Man Configuration");
    println!();
    
    println!("📁 Workspace:");
    println!("   path = \"{}\"", config.workspace.path.display());
    println!("   created_at = \"{}\"", config.workspace.created_at.format("%Y-%m-%d %H:%M:%S UTC"));
    println!();
    
    println!("🔗 Git:");
    println!("   default_host = \"{}\"", config.git.default_host);
    println!("   default_protocol = \"{}\"", config.git.default_protocol);
    if let Some(ssh_key) = &config.git.ssh_key_path {
        println!("   ssh_key_path = \"{}\"", ssh_key.display());
    } else {
        println!("   ssh_key_path = (not set)");
    }
    println!();
    
    println!("🔍 Search:");
    println!("   fuzzy_threshold = {}", config.search.fuzzy_threshold);
    println!("   max_results = {}", config.search.max_results);
    println!("   case_sensitive = {}", config.search.case_sensitive);
    println!();
    
    println!("🎨 UI:");
    println!("   confirm_destructive_actions = {}", config.ui.confirm_destructive_actions);
    println!("   use_colors = {}", config.ui.use_colors);
    println!("   pager = \"{}\"", config.ui.pager);
    
    Ok(())
}

async fn set_config(key: &str, value: &str) -> Result<()> {
    let mut config = GlobalConfig::load()?;
    
    config.set_value(key, value)?;
    config.save()?;
    
    println!("✅ Configuration updated: {} = \"{}\"", key, value);
    
    Ok(())
}

async fn get_config(key: &str) -> Result<()> {
    let config = GlobalConfig::load()?;
    
    let value = config.get_value(key)?;
    
    println!("{}", value);
    
    Ok(())
}