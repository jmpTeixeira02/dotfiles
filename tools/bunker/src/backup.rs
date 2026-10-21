use std::{
    error::Error,
    io::{self, Write},
    path::Path,
    process::Command,
};

use crate::bitwarden;

pub fn run(drive: &Path) -> Result<(), Box<dyn Error>> {
    let dir_name = build_dir_name();
    let dir = drive.join(format!("bunker_{dir_name}"));

    println!("Exporting Bitwarden…");
    io::stdout().flush()?;
    bitwarden::export(&dir.join("bitwarden.json"))?;

    println!("Backup complete: {}", dir.display());
    Ok(())
}

fn build_dir_name() -> String {
    Command::new("date")
        .arg("+%Y-%m-%d_%Hh%M")
        .output()
        .map(|o| String::from_utf8_lossy(&o.stdout).trim().to_string())
        .unwrap_or_else(|_| "backup".to_string())
}
