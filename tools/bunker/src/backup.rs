use std::{
    env,
    error::Error,
    fs,
    io::{self, Write},
    path::{Path, PathBuf},
    process::Command,
};

use crate::{bitwarden, ente};

pub struct Sources {
    pub bitwarden: PathBuf,
    pub ente: PathBuf,
    tmp: PathBuf,
}

impl Drop for Sources {
    fn drop(&mut self) {
        let _ = fs::remove_dir_all(&self.tmp);
    }
}

pub fn prepare() -> Result<Sources, Box<dyn Error>> {
    let tmp = env::temp_dir().join("bunker_export");
    fs::create_dir_all(&tmp)?;

    let bw_path = tmp.join("bitwarden.json");
    let ente_path = tmp.join("ente_auth.txt");

    println!("Exporting Bitwarden…");
    io::stdout().flush()?;
    bitwarden::export(&bw_path)?;

    println!("Exporting Ente Auth…");
    io::stdout().flush()?;
    ente::export(&ente_path)?;

    Ok(Sources {
        bitwarden: bw_path,
        ente: ente_path,
        tmp,
    })
}

pub fn run(drive: &Path, sources: &Sources) -> Result<(), Box<dyn Error>> {
    let dir_name = build_dir_name();
    let dir = drive.join(format!("bunker_{dir_name}"));
    fs::create_dir_all(&dir)?;

    fs::copy(&sources.bitwarden, dir.join("bitwarden.json"))?;
    fs::copy(&sources.ente, dir.join("ente_auth.txt"))?;

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
