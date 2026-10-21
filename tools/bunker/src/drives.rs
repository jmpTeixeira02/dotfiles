use std::{
    fs,
    io::{BufRead, BufReader},
    path::PathBuf,
    sync::atomic::{AtomicBool, Ordering},
    thread,
    time::Duration,
};

pub fn external_drives() -> Vec<PathBuf> {
    let Ok(f) = fs::File::open("/proc/mounts") else {
        return vec![];
    };

    BufReader::new(f)
        .lines()
        .flatten()
        .filter_map(|line| {
            let mut parts = line.splitn(3, ' ');
            let _device = parts.next()?;
            let mount = parts.next()?;
            if mount.starts_with("/media/") || mount.starts_with("/run/media/") {
                Some(PathBuf::from(mount))
            } else {
                None
            }
        })
        .collect()
}

pub fn wait_for_new_drive(known: &[PathBuf], shutdown: &AtomicBool) -> Option<PathBuf> {
    println!("Waiting for a new drive… (Ctrl+C to stop)");
    loop {
        if shutdown.load(Ordering::Relaxed) {
            return None;
        }
        if let Some(drive) = external_drives().into_iter().find(|d| !known.contains(d)) {
            println!("New drive detected: {}", drive.display());
            return Some(drive);
        }
        thread::sleep(Duration::from_secs(2));
    }
}
