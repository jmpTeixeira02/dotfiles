use inquire::{Select, Text};
use std::{
    error::Error,
    path::Path,
    process::{Command, Stdio},
};

fn setup_server() -> Result<(), Box<dyn Error>> {
    let choice = Select::new(
        "Bitwarden server:",
        vec![
            "https://vault.bitwarden.com",
            "https://vault.bitwarden.eu",
            "Custom…",
        ],
    )
    .prompt()?;

    let server = match choice {
        "Custom..." => Text::new("Server URL:").prompt()?,
        _ => choice.to_string(),
    };

    let status = Command::new("bw")
        .args(["config", "server", &server])
        .status()?;

    if !status.success() {
        return Err(format!("bw config server failed for {server}").into());
    }
    Ok(())
}

fn is_logged_in() -> Result<bool, Box<dyn Error>> {
    let status_out = Command::new("bw").arg("status").output()?;
    let status_json = String::from_utf8_lossy(&status_out.stdout);
    Ok(status_json.contains("\"status\":\"locked\"")
        || status_json.contains("\"status\":\"unlocked\""))
}

fn get_session() -> Result<(String, bool), Box<dyn Error>> {
    if !is_logged_in()? {
        setup_server()?;

        let login = Command::new("bw")
            .args(["login", "--raw"])
            .stdin(Stdio::inherit())
            .stdout(Stdio::piped())
            .stderr(Stdio::inherit())
            .output()?;
        if !login.status.success() {
            return Err("bw login failed".into());
        }
        let key = String::from_utf8_lossy(&login.stdout).trim().to_string();
        return Ok((key, false));
    }

    let out = Command::new("bw")
        .args(["unlock", "--raw"])
        .stdin(Stdio::inherit())
        .stdout(Stdio::piped())
        .stderr(Stdio::inherit())
        .output()?;
    if !out.status.success() {
        return Err("bw unlock failed".into());
    }
    let key = String::from_utf8_lossy(&out.stdout).trim().to_string();
    Ok((key, true))
}

pub fn export(out: &Path) -> Result<(), Box<dyn Error>> {
    let (session_key, was_logged_in) = get_session()?;

    let export = Command::new("bw")
        .args([
            "export",
            "--format",
            "encrypted_json",
            "--output",
            out.to_string_lossy().as_ref(),
        ])
        .env("BW_SESSION", &session_key)
        .status()?;

    if !was_logged_in {
        let _ = Command::new("bw").arg("logout").status();
    }

    if !export.success() {
        return Err("bw export failed".into());
    }

    Ok(())
}
