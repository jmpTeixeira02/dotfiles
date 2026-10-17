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
      lact.enable = true;
    };
    hardware = {
      graphics = {
        enable = true;
        enable32Bit = true;
      };
      amdgpu.overdrive.enable = true;
    };

    environment.etc."lact/config.yaml".text = ''
      version: 7
      daemon:
        log_level: info
        admin_group: wheel
        disable_clocks_cleanup: false
      apply_settings_timer: 5
      gpus:
        1002:73DF-1DA2:E445-0000:0b:00.0:
          fan_control_enabled: false
          performance_level: auto
          voltage_offset: -100
      current_profile: null
      auto_switch_profiles: false
    '';

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
