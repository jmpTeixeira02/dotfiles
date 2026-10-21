use ctrlc;
use std::{
    error::Error,
    sync::{
        atomic::{AtomicBool, Ordering},
        Arc,
    },
};

use crate::{backup, drives::wait_for_new_drive};

pub fn run() -> Result<(), Box<dyn Error>> {
    let shutdown = Arc::new(AtomicBool::new(false));
    let flag = Arc::clone(&shutdown);

    ctrlc::set_handler(move || {
        if flag.load(Ordering::Relaxed) {
            std::process::exit(130);
        }
        eprintln!("\nShutting down after current backup finishes…");
        flag.store(true, Ordering::Relaxed);
    })?;

    let sources = backup::prepare()?;

    let mut known: Vec<std::path::PathBuf> = Vec::new();
    loop {
        let Some(drive) = wait_for_new_drive(&known, &shutdown) else {
            eprintln!("Shutdown complete.");
            break;
        };
        if let Err(e) = backup::run(&drive, &sources) {
            eprintln!("Backup to {} failed: {e:#}", drive.display());
        }
        known.push(drive);

        if shutdown.load(Ordering::Relaxed) {
            eprintln!("Shutdown complete.");
            break;
        }
    }

    Ok(())
}
