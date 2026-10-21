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

#[cfg(test)]
mod tests {
    use super::*;

    fn make_sources(tmp: &Path) -> Sources {
        let bw = tmp.join("bitwarden.json");
        let ente = tmp.join("ente_auth.txt");
        fs::write(&bw, b"{}").unwrap();
        fs::write(&ente, b"secret").unwrap();
        Sources {
            bitwarden: bw,
            ente,
            tmp: tmp.to_path_buf(),
        }
    }

    #[test]
    fn run_copies_files_to_drive() {
        let drive_dir = env::temp_dir().join("bunker_test_drive");
        fs::create_dir_all(&drive_dir).unwrap();
        let src_dir = env::temp_dir().join("bunker_test_src");
        fs::create_dir_all(&src_dir).unwrap();

        let sources = make_sources(&src_dir);
        run(&drive_dir, &sources).unwrap();

        // find the bunker_* subdir created
        let entry = fs::read_dir(&drive_dir)
            .unwrap()
            .flatten()
            .find(|e| e.file_name().to_string_lossy().starts_with("bunker_"))
            .expect("no bunker_ dir created");

        let dir = entry.path();
        assert!(dir.join("bitwarden.json").exists());
        assert!(dir.join("ente_auth.txt").exists());

        fs::remove_dir_all(&drive_dir).unwrap();
        // src_dir dropped by Sources::drop
    }

    #[test]
    fn run_fails_on_missing_source_file() {
        let drive_dir = env::temp_dir().join("bunker_test_drive_fail");
        fs::create_dir_all(&drive_dir).unwrap();

        let src_dir = env::temp_dir().join("bunker_test_src_fail");
        fs::create_dir_all(&src_dir).unwrap();

        // Create sources but remove bitwarden file
        let bw = src_dir.join("bitwarden.json");
        let ente = src_dir.join("ente_auth.txt");
        fs::write(&ente, b"secret").unwrap();
        // bw intentionally missing
        let sources = Sources {
            bitwarden: bw,
            ente,
            tmp: src_dir,
        };

        assert!(run(&drive_dir, &sources).is_err());
        fs::remove_dir_all(&drive_dir).unwrap();
    }

    #[test]
    fn drop_removes_tmp_dir() {
        let tmp = env::temp_dir().join("bunker_test_drop");
        fs::create_dir_all(&tmp).unwrap();
        let sources = make_sources(&tmp);
        assert!(tmp.exists());
        drop(sources);
        assert!(!tmp.exists());
    }
}
