{
  description = "Home Manager configuration of joao";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, home-manager, ... }:
    let
      dotfilesRoot = builtins.getEnv "FLAKE_DOTFILES";
      mkConfigPath = homeDirectory:
        if dotfilesRoot != ""
        then "${dotfilesRoot}/config"
        else "${homeDirectory}/dotfiles/config";

      pathsModule = { config, ... }: {
        options.paths.configPath = nixpkgs.lib.mkOption {
          type = nixpkgs.lib.types.str;
          default = mkConfigPath config.home.homeDirectory;
        };
      };

      baseModules = [
        pathsModule
        ./core.nix
      ];
    in
    {
      homeConfigurations = {
        joao = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          modules = baseModules ++ [
            ./module/tmux.nix
          ];
        };
        server = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          modules = baseModules;
        };
        work = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.aarch64-darwin;
          modules = baseModules ++ [
            ./module/tmux.nix
            ./module/colima.nix
          ];
        };
      };
    };
}
