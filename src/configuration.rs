use clap::Parser;
use log::LevelFilter;

/// Renovate approve bot for Forgejo/Gitea.
#[derive(Parser)]
#[command(version, about, long_about = None)]
pub struct Configuration {
    /// Host of forge
    #[arg(long)]
    pub host: String,

    /// File with forgen token
    #[arg(long, name = "token-file")]
    pub token_file: std::path::PathBuf,

    /// Topic for repository search
    #[arg(long, default_value = "renovate")]
    pub repository_topic: String,

    /// Username of renovate bot to identity pull requests to handle
    #[arg(long, default_value = "renovate")]
    pub renovate_user: String,

    /// Log level
    #[arg(long, default_value = "Info")]
    pub log_level: LevelFilter,
}
