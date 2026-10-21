use std::{error::Error, fs, path::Path, process::Command};

pub fn export(out: &Path) -> Result<(), Box<dyn Error>> {
    let export = Command::new("ente").arg("export").status()?;

    if !export.success() {
        return Err("ente export failed".into());
    }

    let home = std::env::var("HOME").map_err(|_| "HOME environment variable not set")?;
    let source_file = Path::new(&home).join(".ente").join("ente_auth.txt");

    copy_export(&source_file, out)
}

fn copy_export(source: &Path, out: &Path) -> Result<(), Box<dyn Error>> {
    if !source.exists() {
        return Err("Export source file not found".into());
    }
    fs::copy(source, out)?;
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::env;

    #[test]
    fn copy_export_copies_file() {
        let dir = env::temp_dir().join("ente_test_copy");
        fs::create_dir_all(&dir).unwrap();
        let src = dir.join("ente_auth.txt");
        let dst = dir.join("out.txt");
        fs::write(&src, b"totp-secret").unwrap();

        copy_export(&src, &dst).unwrap();
        assert_eq!(fs::read(&dst).unwrap(), b"totp-secret");

        fs::remove_dir_all(&dir).unwrap();
    }

    #[test]
    fn copy_export_fails_when_source_missing() {
        let dir = env::temp_dir().join("ente_test_missing");
        fs::create_dir_all(&dir).unwrap();
        let src = dir.join("nonexistent.txt");
        let dst = dir.join("out.txt");

        assert!(copy_export(&src, &dst).is_err());

        fs::remove_dir_all(&dir).unwrap();
    }
}
