pub mod nix;
pub mod nixos;

use clap::Args;
use std::process::Command;

use crate::{Target, Users};

#[derive(Args, Debug)]
pub struct InstallArgs {
    /// Nix User
    #[arg(short, long)]
    pub user: Users,

    /// Host installation target (only takes effect on NixOS hosts)
    #[arg(long, default_value = "localhost")]
    pub host: String,

    /// Format disks according to disko setup (only takes effect on NixOS hosts)
    #[arg(short, long)]
    pub format_disks: bool,

    /// Add Age Key (only takes effect on NixOS hosts)
    #[arg(short, long)]
    pub key: bool,

    /// Directory of the flake
    #[arg(long, env = "FLAKE", default_value = "$HOME/dotfiles/nix")]
    pub flake_dir: String,
}

impl InstallArgs {
    pub fn flake_dir(&self) -> String {
        shellexpand::full(&self.flake_dir)
            .unwrap_or_else(|_| self.flake_dir.as_str().into())
            .to_string()
    }
}

pub fn command(args: InstallArgs) -> Command {
    match args.user.target() {
        Target::Nixos => nixos::command(args),
        Target::HomeManager => nix::command(),
    }
}
