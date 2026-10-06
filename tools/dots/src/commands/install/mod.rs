pub mod nix;
pub mod nixos;

use clap::{Args, Subcommand};
use std::process::Command;

#[derive(Args, Debug)]
pub struct InstallArgs {
    #[command(subcommand)]
    command: InstallCommand,
}

#[derive(Subcommand, Debug)]
enum InstallCommand {
    /// Install NixOS
    Nixos(nixos::NixosArgs),
    /// Install Nix
    Nix,
}

pub fn command(args: InstallArgs) -> Command {
    let cmd = match args.command {
        InstallCommand::Nix => nix::command(),
        InstallCommand::Nixos(args) => nixos::command(args),
    };
    cmd
}
