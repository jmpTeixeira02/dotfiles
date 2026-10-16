{
  disko.devices.disk = {
    main = {
      type = "disk";
      device = "/dev/nvme0n1";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };
          swap = {
            size = "16G";
            content = {
              type = "swap";
            };
          };
          root = {
            size = "100%";
            content = {
              type = "btrfs";
              extraArgs = [ "-f" ];
              subvolumes = {
                "@" = {
                  mountpoint = "/";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                };
                "@home" = {
                  mountpoint = "/home";
                  mountOptions = [
                    "compress=zstd:1"
                    "noatime"
                  ];
                };
                "@nix" = {
                  mountpoint = "/nix";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                };
                "@log" = {
                  mountpoint = "/var/log";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                };
                "@vms" = {
                  mountpoint = "/var/lib/libvirt/images";
                  mountOptions = [ "noatime" ];
                };
              };
            };
          };
        };
      };
    };
    games-hdd = {
      device = "/dev/sda";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          data = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/mnt/games-hdd";
              mountOptions = [
                "nofail"
                "x-gvfs-show"
                "x-gvfs-name=Games-HDD"
              ];
            };
          };
        };
      };
    };
    games-ssd = {
      device = "/dev/sdb";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          data = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/mnt/games-ssd";
              mountOptions = [
                "nofail"
                "x-gvfs-show"
                "x-gvfs-name=Games-SSD"
              ];
            };
          };
        };
      };
    };
    storage-hdd = {
      device = "/dev/sdc";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          data = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/mnt/storage-hdd";
              mountOptions = [
                "nofail"
                "x-gvfs-show"
                "x-gvfs-name=Storage-SSD"
              ];
            };
          };
        };
      };
    };
    steam-games-ssd = {
      device = "/dev/sdd";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          data = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/mnt/steam-games-ssd";
              mountOptions = [
                "nofail"
                "x-gvfs-show"
                "x-gvfs-name=Steam-Games-SSD"
              ];
            };
          };
        };
      };
    };
  };
}
