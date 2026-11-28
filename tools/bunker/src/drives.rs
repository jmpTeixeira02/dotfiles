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
    parse_mounts(BufReader::new(f))
}

fn parse_mounts<R: std::io::Read>(reader: R) -> Vec<PathBuf> {
    BufReader::new(reader)
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

#[cfg(test)]
mod tests {
    use super::*;

    fn mounts(s: &str) -> Vec<PathBuf> {
        parse_mounts(s.as_bytes())
    }

    #[test]
    fn empty_input_returns_no_drives() {
        assert!(mounts("").is_empty());
    }

    #[test]
    fn non_external_mounts_excluded() {
        let input = "/dev/sda1 / ext4 rw 0 0\ntmpfs /tmp tmpfs rw 0 0\n";
        assert!(mounts(input).is_empty());
    }

    #[test]
    fn media_mount_included() {
        let input = "/dev/sdb1 /media/usb ext4 rw 0 0\n";
        assert_eq!(mounts(input), vec![PathBuf::from("/media/usb")]);
    }

    #[test]
    fn run_media_mount_included() {
        let input = "/dev/sdb1 /run/media/user/drive ext4 rw 0 0\n";
        assert_eq!(mounts(input), vec![PathBuf::from("/run/media/user/drive")]);
    }

    #[test]
    fn reinserted_drive_is_new_again() {
        let mut known = vec![PathBuf::from("/media/usb")];
        // unplugged: nothing mounted, so the drive is forgotten
        assert_eq!(pick_new(&[], &mut known), None);
        // replugged at the same path: backs up again
        assert_eq!(
            pick_new(&[PathBuf::from("/media/usb")], &mut known),
            Some(PathBuf::from("/media/usb"))
        );
    }

    #[test]
    fn still_mounted_drive_is_not_new() {
        let mut known = vec![PathBuf::from("/media/usb")];
        assert_eq!(pick_new(&[PathBuf::from("/media/usb")], &mut known), None);
    }

    #[test]
    fn multiple_drives_all_returned() {
        let input = "/dev/sda1 / ext4 rw 0 0\n/dev/sdb1 /media/usb1 ext4 rw 0 0\n/dev/sdc1 /run/media/user/usb2 ext4 rw 0 0\n";
        assert_eq!(
            mounts(input),
            vec![
                PathBuf::from("/media/usb1"),
                PathBuf::from("/run/media/user/usb2"),
            ]
        );
    }
}

pub fn wait_for_new_drive(known: &mut Vec<PathBuf>, shutdown: &AtomicBool) -> Option<PathBuf> {
    println!("Waiting for a new drive… (Ctrl+C to stop)");
    loop {
        if shutdown.load(Ordering::Relaxed) {
            return None;
        }
        if let Some(drive) = pick_new(&external_drives(), known) {
            println!("New drive detected: {}", drive.display());
            return Some(drive);
        }
        thread::sleep(Duration::from_secs(2));
    }
}

// Forget drives that were unplugged so re-inserting one triggers a new backup.
fn pick_new(current: &[PathBuf], known: &mut Vec<PathBuf>) -> Option<PathBuf> {
    known.retain(|d| current.contains(d));
    current.iter().find(|d| !known.contains(d)).cloned()
}
