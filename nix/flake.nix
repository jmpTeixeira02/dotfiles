{
  description = "Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    {
      nixpkgs,
      home-manager,
      disko,
      sops-nix,
      ...
    }:
    let
      dotfilesRoot = builtins.getEnv "FLAKE_DOTFILES";
      mkConfigPath =
        homeDirectory:
        if dotfilesRoot != "" then "${dotfilesRoot}/config" else "${homeDirectory}/dotfiles/config";

      pathsModule = { config, ... }: {
        options.paths.configPath = nixpkgs.lib.mkOption {
          type = nixpkgs.lib.types.str;
          default = mkConfigPath config.home.homeDirectory;
        };
      };

      baseModules = [
        pathsModule
        ./core.nix
        ./lib/utils.nix
      ];

    in
    {
      homeConfigurations = {
        home = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          modules = baseModules ++ [
            ./module/tmux.nix
            ./module/ai.nix
            ./module/programming.nix
            {
              opencodeProfile = "home";
            }
          ];
        };
        homelab = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          modules = baseModules ++ [
            ./module/programming.nix
          ];
        };
        work = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.aarch64-darwin;
          modules = baseModules ++ [
            ./module/colima.nix
            ./module/tmux.nix
            ./module/ai.nix
            ./module/programming.nix
            {
              opencodeProfile = "work";
            }
          ];
        };
      };

      nixosConfigurations = {
        homelab = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            disko.nixosModules.disko
            sops-nix.nixosModules.sops
            ./hosts/homelab/disks/disko.nix
            ./hosts/homelab/configuration.nix
            ./hosts/homelab/hardware-configuration.nix
          ];
        };
      };
    };
}
