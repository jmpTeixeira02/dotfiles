{ inputs, config, ... }:
{
  flake.modules.homeManager.desktop-default = {
    imports = [
      config.flake.modules.homeManager.desktop-browser
      config.flake.modules.homeManager.desktop-shell
      config.flake.modules.homeManager.desktop-display
      config.flake.modules.homeManager.desktop-communication
      config.flake.modules.homeManager.desktop-spotify
      config.flake.modules.homeManager.desktop-security
      config.flake.modules.homeManager.desktop-tilling-manager
      config.flake.modules.homeManager.desktop-file-manager
      config.flake.modules.homeManager.desktop-office
      config.flake.modules.homeManager.desktop-media
    ];

    programs.home-manager.enable = true;
  };

  flake.modules.nixos.default = { pkgs, ... }: {
    imports = [
      inputs.disko.nixosModules.disko
      inputs.sops-nix.nixosModules.sops
      inputs.home-manager.nixosModules.home-manager
    ];

    nixpkgs.config = {
      allowUnfree = true;
      allowBroken = true;
    };

    programs.zsh = {
      enable = true;
      enableGlobalCompInit = false;
    };
  };

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
