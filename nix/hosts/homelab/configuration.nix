{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./disks/disko.nix
    ./disks/pool.nix
    ../../services/network/default.nix
    ../../services/management/default.nix
    ../../services/nas/default.nix
  ];

  options.mySystem = {
    poolMount = lib.mkOption {
      type = lib.types.str;
      default = "/mnt/storage";
      description = "Mount point for the primary mergerfs storage pool";
    };
    serviceData = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/homelab";
      description = "Directory storing service persistent state";
    };
  };

  config = {
    mySystem = {
      poolMount = "/mnt/storage";
      serviceData = "/var/lib/homelab";
    };

    sops = {
      age.keyFile = "/var/lib/sops-nix/key.txt";
      secrets = {
        homelab-password-hash = {
          sopsFile = ./secrets.yaml;
          neededForUsers = true;
        };
      };
    };

    boot.loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    virtualisation = {
      podman = {
        enable = true;
        dockerCompat = true;
        defaultNetwork.settings.dns_enabled = true;
      };
      oci-containers.backend = "podman";
    };

    console.keyMap = "pt-latin1";

    networking = {
      hostName = "homelab";
      firewall = {
        enable = true;
        allowedTCPPorts = [ 22 ];
      };
      useDHCP = false;
      interfaces.eth0.ipv4.addresses = [
        {
          address = "192.168.1.11";
          prefixLength = 24;
        }
      ];
      defaultGateway = "192.168.1.254";
      nameservers = [
        "1.1.1.1"
        "8.8.8.8"
      ];
    };

    time.timeZone = "Europe/Lisbon";

    users.mutableUsers = false;
    users.users = {
      homelab = {
        isNormalUser = true;
        extraGroups = [
          "wheel"
          "podman"
        ];
        hashedPasswordFile = config.sops.secrets.homelab-password-hash.path;
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK7GueGAFmWmg0Bvx7RGb2MhMWRntk4OOwWDsYuGQHyt"
        ];
      };
    };

    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
        KbdInteractiveAuthentication = false;
      };
    };

    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];

    environment.systemPackages = with pkgs; [ git ];

    system.stateVersion = "26.05";
  };
}
