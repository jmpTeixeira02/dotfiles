use std::{fs, io::Write, process::Command};

use super::InstallArgs;

pub fn command(args: InstallArgs) -> Command {
    let mut phases = Vec::new();
    if args.host != "localhost" {
        phases.push("kexec");
    }
    if args.format_disks {
        phases.push("disko");
    }
    phases.extend(["install", "reboot"]);

    let flake = format!("{}#{}", args.flake_dir(), args.user);
    let hardware_config = format!(
        "{}/modules/hosts/_{}/hardware-configuration.nix",
        args.flake_dir(),
        args.user
    );

    let mut cmd = Command::new("nix");
    cmd.args(["--extra-experimental-features", "nix-command flakes"])
        .args(["run", "github:nix-community/nixos-anywhere", "--"])
        .args(["--phases", &phases.join(",")])
        .args(["--flake", &flake])
        .args([
            "--generate-hardware-config",
            "nixos-generate-config",
            &hardware_config,
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

    #[test]
    fn localhost_skips_kexec() {
        let cmd = command(args("localhost", false, "./nix"));

        assert_eq!(cmd.get_program(), "nix");
        assert_eq!(
            args_of(&cmd),
            expected("install,reboot", "./nix", "localhost")
        );
    }

    #[test]
    fn remote_host_adds_kexec_phase() {
        let cmd = command(args("example.com", false, "./nix"));

        assert_eq!(
            args_of(&cmd),
            expected("kexec,install,reboot", "./nix", "example.com")
        );
    }

    #[test]
    fn format_disks_adds_disko_phase() {
        let cmd = command(args("localhost", true, "./nix"));

        assert_eq!(
            args_of(&cmd),
            expected("disko,install,reboot", "./nix", "localhost")
        );
    }

    #[test]
    fn flake_dir_changes_flake_and_hardware_config_paths() {
        let cmd = command(args("localhost", false, "/etc/flake"));

        assert_eq!(
            args_of(&cmd),
            expected("install,reboot", "/etc/flake", "localhost")
        );
    }
}
