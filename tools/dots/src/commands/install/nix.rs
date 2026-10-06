use std::process::Command;

pub fn command() -> Command {
    let mut cmd = Command::new("sh");
    cmd.args([
        "-c",
        "curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install",
    ]);
    cmd
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn builds_expected_command() {
        let cmd = command();

        assert_eq!(cmd.get_program(), "sh");
        assert_eq!(
            cmd.get_args().collect::<Vec<_>>(),
            [
                "-c",
                "curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install"
            ]
        );
    }
}
