mod backup;
mod bitwarden;
mod commands;
mod drives;
mod ente;

use clap::{Parser, Subcommand};
use commands::{list, watch};

#[derive(Parser, Debug)]
#[command(version, about = "Backup auth secrets (Bitwarden) to encrypted drives")]
struct Cli {
    #[command(subcommand)]
    action: Action,
}

#[derive(Subcommand, Debug)]
enum Action {
    /// List connected drives and pick one or more to back up to
    List,

    /// Wait for drives to be connected and back up automatically (Ctrl+C to stop)
    Watch,
}

fn main() {
    let cli = Cli::parse();
    let result = match cli.action {
        Action::List => list::run(),
        Action::Watch => watch::run(),
    };
    if let Err(e) = result {
        eprintln!("{e:#}");
        std::process::exit(1);
    }
}
