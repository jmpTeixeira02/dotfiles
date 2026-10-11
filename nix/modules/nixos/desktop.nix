{ config, ... }:
{
  flake.modules.nixos.desktop = { pkgs, ... }: {
    imports = [
      config.flake.modules.nixos.audio
      config.flake.modules.nixos.tilling-manager
    ];

    fonts.packages = with pkgs; [
      nerd-fonts.hack
    ];
  };
}
