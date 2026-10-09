mod commands;
use clap::{Parser, Subcommand, ValueEnum};
use commands::clean;
use std::{error::Error, fmt, os::unix::process::ExitStatusExt, process::Command};

use crate::commands::{install, reload, update};

#[derive(Parser, Debug)]
#[command(version, about = "Manage the systems: install, reload, clean")]
struct Cli {
    #[command(subcommand)]
    action: Action,
}

#[derive(Subcommand, Debug)]
enum Action {
    /// Install Nix/NixOS on a machine
    Install(install::InstallArgs),

    /// Re-apply the NixOS or Home Manager configuration
    Reload(reload::ReloadArgs),

    /// Garbage-collect the Nix store
    Clean(clean::CleanArgs),

    /// Update flake inputs
    Update(update::UpdateArgs),
}

#[derive(ValueEnum, Clone, Debug)]
pub enum Users {
    Home,
    WSL,
    Homelab,
    Work,
}

pub enum Target {
    Nixos,
    HomeManager,
}

impl Users {
    pub fn target(&self) -> Target {
        match self {
            Users::Home | Users::Homelab => Target::Nixos,
            Users::WSL | Users::Work => Target::HomeManager,
        }
    }
}

impl fmt::Display for Users {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        match self {
            Users::Home => write!(f, "home"),
            Users::WSL => write!(f, "wsl"),
            Users::Homelab => write!(f, "homelab"),
            Users::Work => write!(f, "work"),
        }
    }
}

fn main() {
    let cli = Cli::parse();
    let result = match cli.action {
        Action::Install(args) => install::command(args),
        Action::Reload(args) => reload::command(args),
        Action::Clean(args) => clean::command(args),
        Action::Update(args) => update::command(args),
    };
    let result = run(result);
    if let Err(e) = result {
        eprintln!("{e:#}");
        std::process::exit(1);
    }
}

pub fn run(mut cmd: Command) -> Result<(), Box<dyn Error>> {
    ctrlc::set_handler(|| {}).expect("failed to set signal handler");

    let name = cmd.get_program().to_string_lossy().into_owned();
    let status = cmd
        .status()
        .map_err(|e| format!("failed to run {name}: {e}"))?;
    if let Some(sig) = status.signal() {
        std::process::exit(128 + sig);
    }
    if !status.success() {
        return Err(format!("{name} failed ({status})").into());
    }
    Ok(())
}
