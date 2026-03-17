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
      
        mkPkgs = system: import nixpkgs {
            inherit system;
            overlays = [ 
                (import ./overlays/go.nix)
            ];
        };
    in
    {
      homeConfigurations = {
        joao = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          modules = [
            ./core.nix
          ];
        };
        server = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          modules = [
            ./core.nix
            { tmux = false; }
          ];
        };
        work = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.aarch64-darwin;
          modules = [
            ./core.nix
            ./module/work.nix
            { colima = true; }
          ];
        };
      };
    };
}
