{ config, ... }:
{
  flake.modules.nixos.desktop = { pkgs, ... }: {
    imports = [
      config.flake.modules.nixos.audio
      config.flake.modules.nixos.tilling-manager
      config.flake.modules.nixos.file-manager
      config.flake.modules.nixos.security
      config.flake.modules.nixos.virtualization
    ];

    fonts.packages = with pkgs; [
      nerd-fonts.hack
    ];

    hardware.bluetooth.enable = true;
  };
}
