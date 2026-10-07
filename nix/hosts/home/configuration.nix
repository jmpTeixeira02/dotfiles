{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ./disks/disko.nix
  ];

  config = {
    zramSwap.enable = true;
    boot.loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    services = {
      btrfs.autoScrub.enable = true;
      fstrim.enable = true;
      displayManager.sddm = {
        enable = true;
        wayland.enable = true;
      };
      desktopManager.plasma6.enable = true;
    };

    console.keyMap = "pt-latin1";

    networking = {
      hostName = "joao";
      networkmanager.enable = true;
    };

    time.timeZone = "Europe/Lisbon";

    programs.zsh.enable = true;

    users.mutableUsers = true;
    users.users = {
      joao = {
        uid = 1000;
        isNormalUser = true;
        extraGroups = [
          "wheel"
          "networkmanager"
          "video"
          "audio"
        ];
        shell = pkgs.zsh;
        initialPassword = "temp";
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
