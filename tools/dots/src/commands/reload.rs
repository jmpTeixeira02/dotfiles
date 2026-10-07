use std::{path::Path, process::Command};

use clap::Args;

use crate::{Target, Users};

#[derive(Args, Debug)]
pub struct ReloadArgs {
    /// Nix User
    #[arg(short, long)]
    user: Users,

    /// Directory of the flake
    #[arg(long, env = "FLAKE", default_value = "$HOME/dotfiles/nix")]
    flake_dir: String,
}

impl ReloadArgs {
    pub fn flake_dir(&self) -> String {
        shellexpand::full(&self.flake_dir)
            .unwrap_or_else(|_| self.flake_dir.as_str().into())
            .to_string()
    }

    pub fn dotfiles_dir(&self) -> String {
        let expanded = self.flake_dir();
        let clean = expanded.trim_end_matches('/');

        Path::new(clean)
            .parent()
            .and_then(|p| p.to_str())
            .filter(|s| !s.is_empty())
            .map(|s| s.to_string())
            .unwrap_or_else(|| ".".to_string())
    }
}

pub fn command(args: ReloadArgs) -> Command {
    let flake = format!("{}#{}", args.flake_dir(), args.user);

    let mut cmd = match args.user.target() {
        Target::Nixos => {
            let mut cmd = Command::new("sudo");
            cmd.args(["nixos-rebuild", "switch", "--flake", &flake, "--impure"]);
            cmd
        }
        Target::HomeManager => {
            let mut cmd = Command::new("nix");
            cmd.args([
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
    cmd.env("FLAKE_DOTFILES", args.dotfiles_dir());
    cmd
}

#[cfg(test)]
mod tests {
    use super::*;

    fn args(user: Users, flake_dir: &str) -> ReloadArgs {
        ReloadArgs {
            user,
            flake_dir: flake_dir.to_string(),
        }
    }

    #[test]
    fn nixos_user_runs_nixos_rebuild() {
        let cmd = command(args(Users::Home, "./nix"));
        let flake = format!("./nix#{}", Users::Home);

        assert_eq!(cmd.get_program(), "sudo");
        assert_eq!(
            cmd.get_args().collect::<Vec<_>>(),
            [
                "nixos-rebuild",
                "switch",
                "--flake",
                flake.as_str(),
                "--impure"
            ]
        );
    }

    #[test]
    fn home_manager_user_runs_home_manager_switch() {
        let cmd = command(args(Users::Work, "./nix"));
        let flake = format!("./nix#{}", Users::Work);

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
                "--impure"
            ]
        );
    }

    #[test]
    fn flake_dir_changes_flake_path() {
        let cmd = command(args(Users::Home, "/etc/flake"));
        let flake = format!("/etc/flake#{}", Users::Home);

        assert_eq!(
            cmd.get_args().collect::<Vec<_>>(),
            [
                "nixos-rebuild",
                "switch",
                "--flake",
                flake.as_str(),
                "--impure"
            ]
        );
    }
}
