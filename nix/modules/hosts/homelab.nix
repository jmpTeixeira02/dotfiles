{
  config,
  inputs,
  ...
}:
let
  hm = config.flake.modules.homeManager;
  nixos = config.flake.modules.nixos;
in
{
  flake.nixosConfigurations.homelab = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      ./_homelab/configuration.nix
      nixos.default
      nixos.containers
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          extraSpecialArgs = { inherit inputs; };
          users.homelab = {
            imports = [
              hm.default
              hm.programming
            ];
            home = {
              username = "homelab";
              homeDirectory = "/home/homelab";
              stateVersion = "26.05";
            };
          };
        };
      }
    ];
  };
}
