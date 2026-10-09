use std::{fs, io::Write, process::Command};

use super::InstallArgs;

pub fn command(args: InstallArgs) -> Command {
    if args.host == "localhost" {
        local_command(&args)
    } else {
        remote_command(&args)
    }
}

fn local_command(args: &InstallArgs) -> Command {
    let flake = args.flake();

    let mut steps = vec![format!(
        "nixos-generate-config --no-filesystems --show-hardware-config > {}",
        args.hardware_config()
    )];
    if args.format_disks {
        steps.push(format!(
            "nix --extra-experimental-features 'nix-command flakes' \
             run github:nix-community/disko -- --mode destroy,format,mount --flake {flake}"
        ));
    }
    steps.push(format!("nixos-install --flake {flake}"));

    let mut cmd = Command::new("sh");
    cmd.args(["-c", &steps.join(" && ")]);
    cmd
}

fn remote_command(args: &InstallArgs) -> Command {
    let mut phases = vec!["kexec"];
    if args.format_disks {
        phases.push("disko");
    }
    phases.extend(["install", "reboot"]);

    let mut cmd = Command::new("nix");
    cmd.args(["--extra-experimental-features", "nix-command flakes"])
        .args(["run", "github:nix-community/nixos-anywhere", "--"])
        .args(["--phases", &phases.join(",")])
        .args(["--flake", &args.flake()])
        .args([
            "--generate-hardware-config",
            "nixos-generate-config",
            &args.hardware_config(),
        ])
        .args(["--target-host", &format!("nixos@{}", args.host)]);

    if !args.key {
        return cmd;
    }

    let key = rpassword::prompt_password("Paste your age private key")
        .expect("Failed to get the private key");
    let key = key.trim();

    let temp = tempfile::tempdir().expect("Failed to create temp dir to hold the secret key");
    let keys_dir = temp.path().join("var/lib/sops-nix");
    fs::DirBuilder::new()
        .recursive(true)
        .create(&keys_dir)
        .expect("Failed to create path for the key");
    fs::OpenOptions::new()
        .write(true)
        .create_new(true)
        .open(keys_dir.join("key.txt"))
        .expect("Failed to open key file")
        .write_all(format!("{key}\n").as_bytes())
        .expect("Failed to write key");

    let dir = temp.keep();
    cmd.arg("--extra-files").arg(&dir);

    let mut wrapped = Command::new("sh");
    wrapped
        .args([
            "-c",
            r#"dir=$1; shift; trap 'rm -rf "$dir"' EXIT INT TERM HUP; "$@""#,
            "sh",
        ])
        .arg(&dir)
        .arg(cmd.get_program())
        .args(cmd.get_args());
    wrapped
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::Users;

    fn args(host: &str, format_disks: bool, flake_dir: &str) -> InstallArgs {
        InstallArgs {
            user: Users::Home,
            host: host.to_string(),
            format_disks,
            key: false,
            flake_dir: flake_dir.to_string(),
        }
    }

    fn args_of(cmd: &Command) -> Vec<String> {
        cmd.get_args()
            .map(|a| a.to_string_lossy().into_owned())
            .collect()
    }

    /// The full argument list `command` is expected to produce when `key` is false.
    fn expected(phases: &str, flake_dir: &str, host: &str) -> Vec<String> {
        vec![
            "--extra-experimental-features".to_string(),
            "nix-command flakes".to_string(),
            "run".to_string(),
            "github:nix-community/nixos-anywhere".to_string(),
            "--".to_string(),
            "--phases".to_string(),
            phases.to_string(),
            "--flake".to_string(),
            format!("{flake_dir}#{}", Users::Home),
            "--generate-hardware-config".to_string(),
            "nixos-generate-config".to_string(),
            format!(
                "{flake_dir}/modules/hosts/_{}/hardware-configuration.nix",
                Users::Home
            ),
            "--target-host".to_string(),
            format!("nixos@{host}"),
        ]
    }

    /// The `sh -c <script>` the localhost path runs.
    fn script_of(cmd: &Command) -> String {
        assert_eq!(cmd.get_program(), "sh");
        let args = args_of(cmd);
        assert_eq!(args[0], "-c");
        args[1].clone()
    }

    #[test]
    fn localhost_generates_hardware_config_and_installs() {
        let script = script_of(&command(args("localhost", false, "./nix")));

        assert_eq!(
            script,
            "nixos-generate-config --no-filesystems --show-hardware-config \
             > ./nix/modules/hosts/_home/hardware-configuration.nix \
             && nixos-install --flake ./nix#home"
        );
    }

    #[test]
    fn localhost_formats_disks_with_disko() {
        let script = script_of(&command(args("localhost", true, "./nix")));

        assert!(script.contains("github:nix-community/disko"));
        assert!(script.contains("--mode destroy,format,mount --flake ./nix#home"));
    }

    #[test]
    fn remote_host_uses_nixos_anywhere_with_kexec() {
        let cmd = command(args("example.com", false, "./nix"));

        assert_eq!(cmd.get_program(), "nix");
        assert_eq!(
            args_of(&cmd),
            expected("kexec,install,reboot", "./nix", "example.com")
        );
    }

    #[test]
    fn remote_format_disks_adds_disko_phase() {
        let cmd = command(args("example.com", true, "./nix"));

        assert_eq!(
            args_of(&cmd),
            expected("kexec,disko,install,reboot", "./nix", "example.com")
        );
    }

    #[test]
    fn remote_flake_dir_changes_flake_and_hardware_config_paths() {
        let cmd = command(args("example.com", false, "/etc/flake"));

        assert_eq!(
            args_of(&cmd),
            expected("kexec,install,reboot", "/etc/flake", "example.com")
        );
    }
}
