use clap::Args;
use std::process::Command;

#[derive(Args, Debug)]
pub struct UpdateArgs {
    /// Directory of the flake
    #[arg(long, env = "FLAKE", default_value = "./nix")]
    flake_dir: String,
}

pub fn command(args: UpdateArgs) -> Command {
    let mut cmd = Command::new("nix");
    cmd.args(["flake", "update", "--flake", &args.flake_dir]);
    cmd
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn updates_flake_in_flake_dir() {
        let cmd = command(UpdateArgs {
            flake_dir: "./nix".to_string(),
        });

        assert_eq!(cmd.get_program(), "nix");
        assert_eq!(
            cmd.get_args().collect::<Vec<_>>(),
            ["flake", "update", "--flake", "./nix"]
        );
    }
}
