{ inputs, config, ... }:
{
  flake.modules.nixos.default = { pkgs, ... }: {
    imports = [
      inputs.disko.nixosModules.disko
      inputs.sops-nix.nixosModules.sops
      inputs.home-manager.nixosModules.home-manager
      config.flake.modules.nixos.audio
    ];

    nixpkgs.config = {
      allowUnfree = true;
      allowBroken = true;
    };

    fonts.packages = with pkgs; [
      nerd-fonts.hack
    ];

    programs.zsh = {
      enable = true;
      enableGlobalCompInit = false;
    };
  };
}
