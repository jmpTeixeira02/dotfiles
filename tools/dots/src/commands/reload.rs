use std::{env, process::Command};

use clap::{Args, ValueEnum};

use crate::Users;

#[derive(ValueEnum, Clone, Debug)]
pub enum ReloadTarget {
    NixOS,
    HomeManager,
}

#[derive(Args, Debug)]
pub struct ReloadArgs {
    /// Nix User
    #[arg(short, long)]
    pub target: ReloadTarget,

    /// Nix User
    #[arg(short, long)]
    user: Users,

    /// Directory of the flake
    #[arg(long, default_value = "./nix")]
    flake_dir: String,
}

pub fn command(args: ReloadArgs) -> Command {
    let flake = format!("{}#{}", args.flake_dir, args.user);

    let cmd = match args.target {
        ReloadTarget::NixOS => {
            let mut cmd = Command::new("sudo");
            cmd.args(["nixos-rebuild", "switch", "--flake", &flake]);
            cmd
        }
        ReloadTarget::HomeManager => {
            let mut cmd = Command::new("nix");
            cmd.env("NIX_USER", args.user.to_string())
                .env(
                    "FLAKE_USER",
                    env::var("USER").expect("User environment variable is not set"),
                )
                .env(
                    "FLAKE_HOME",
                    env::var("HOME").expect("Home environment variable is not set"),
                )
                .env("NIXPKGS_ALLOW_BROKEN", "1")
                .env("NIXPKGS_ALLOW_UNFREE", "1")
                .args([
                    "run",
                    "home-manager",
                    "--",
                    "switch",
                    "--flake",
                    &flake,
                    "--impure",
                ]);

            cmd
        }
    };
    cmd
}

#[cfg(test)]
mod tests {
    use super::*;

    fn args(target: ReloadTarget, flake_dir: &str) -> ReloadArgs {
        ReloadArgs {
            target,
            user: Users::Home,
            flake_dir: flake_dir.to_string(),
        }
    }

    #[test]
    fn nixos_target_runs_nixos_rebuild() {
        let cmd = command(args(ReloadTarget::NixOS, "./nix"));
        let flake = format!("./nix#{}", Users::Home);

        assert_eq!(cmd.get_program(), "sudo");
        assert_eq!(
            cmd.get_args().collect::<Vec<_>>(),
            ["nixos-rebuild", "switch", "--flake", flake.as_str()]
        );
    }

    #[test]
    fn home_manager_target_runs_home_manager_switch() {
        let cmd = command(args(ReloadTarget::HomeManager, "./nix"));
        let flake = format!("./nix#{}", Users::Home);

        assert_eq!(cmd.get_program(), "nix");
        assert_eq!(
            cmd.get_args().collect::<Vec<_>>(),
            [
                "run",
                "home-manager",
                "--",
                "switch",
                "--flake",
                flake.as_str(),
                "--impure",
            ]
        );
    }

    #[test]
    fn flake_dir_changes_flake_path() {
        let cmd = command(args(ReloadTarget::NixOS, "/etc/flake"));
        let flake = format!("/etc/flake#{}", Users::Home);

        assert_eq!(
            cmd.get_args().collect::<Vec<_>>(),
            ["nixos-rebuild", "switch", "--flake", flake.as_str()]
        );
    }
}
