{ config, ... }:
{
  flake.modules.nixos.desktop = { pkgs, ... }: {
    imports = [
      config.flake.modules.nixos.audio
      config.flake.modules.nixos.tilling-manager
      config.flake.modules.nixos.file-manager
      config.flake.modules.nixos.security
    ];

    fonts.packages = with pkgs; [
      nerd-fonts.hack
    ];
  };
}
