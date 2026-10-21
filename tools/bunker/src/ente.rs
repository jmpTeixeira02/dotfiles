use std::{error::Error, fs, path::Path, process::Command};

pub fn export(out: &Path) -> Result<(), Box<dyn Error>> {
    let export = Command::new("ente").arg("export").status()?;

    if !export.success() {
        return Err("ente export failed".into());
    }

    let home = std::env::var("HOME").map_err(|_| "HOME environment variable not set")?;
    let source_file = Path::new(&home).join(".ente").join("ente_auth.txt");

    if !source_file.exists() {
        return Err("Export source file not found".into());
    }

    fs::copy(&source_file, out)?;

    Ok(())
}
