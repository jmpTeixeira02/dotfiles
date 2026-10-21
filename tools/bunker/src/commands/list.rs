use inquire::MultiSelect;
use std::error::Error;

use crate::{backup, drives::external_drives};

pub fn run() -> Result<(), Box<dyn Error>> {
    let drives = external_drives();
    if drives.is_empty() {
        return Err("no external drives found".into());
    }

    let options: Vec<String> = drives.iter().map(|d| d.display().to_string()).collect();
    let chosen = MultiSelect::new("Select drives to back up to:", options).prompt()?;
    if chosen.is_empty() {
        return Err("no drives selected".into());
    }

    let sources = backup::prepare()?;

    for path in &chosen {
        if let Err(e) = backup::run(std::path::Path::new(path), &sources) {
            eprintln!("Backup to {path} failed: {e:#}");
        }
    }

    Ok(())
}
