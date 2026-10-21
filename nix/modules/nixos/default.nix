{ inputs, ... }:
{
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
}
