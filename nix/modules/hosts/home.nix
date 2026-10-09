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
  flake.nixosConfigurations.home = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      ./_home/configuration.nix
      nixos.default
      nixos.gamming
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          extraSpecialArgs = { inherit inputs; };
          users.joao = {
            imports = [
              hm.default
              hm.desktop-default
              hm.desktop-gamming
              hm.ai
              hm.programming
            ];
            opencodeProfile = "home";
            home = {
              username = "joao";
              homeDirectory = "/home/joao";
              stateVersion = "26.05";
            };
          };
        };
      }
    ];
  };
}
