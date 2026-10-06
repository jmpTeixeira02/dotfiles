use clap::Args;
use std::process::Command;

#[derive(Args, Debug)]
pub struct CleanArgs {
    /// Delete collection older than X in days
    #[arg(long, value_name = "DAYS", conflicts_with = "all")]
    older_than: Option<u32>,

    /// Delete all collections
    #[arg(long)]
    all: bool,
}

pub fn command(args: CleanArgs) -> Command {
    let mut cmd = Command::new("nix-collect-garbage");

    if args.all {
        cmd.arg("-d");
    } else if let Some(days) = args.older_than {
        cmd.args(["--delete-older-than", &format!("{days}d")]);
    }

    cmd
}

#[cfg(test)]
mod tests {
    use super::*;

    fn args(older_than: Option<u32>, all: bool) -> CleanArgs {
        CleanArgs { older_than, all }
    }

    #[test]
    fn older_than_deletes_older_than_days() {
        let cmd = command(args(Some(7), false));

        assert_eq!(cmd.get_program(), "nix-collect-garbage");
        assert_eq!(
            cmd.get_args().collect::<Vec<_>>(),
            ["--delete-older-than", "7d"]
        );
    }

    #[test]
    fn all_deletes_everything() {
        let cmd = command(args(None, true));

        assert_eq!(cmd.get_program(), "nix-collect-garbage");
        assert_eq!(cmd.get_args().collect::<Vec<_>>(), ["-d"]);
    }
}
