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
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          extraSpecialArgs = { inherit inputs; };
          users.joao = {
            imports = [
              hm.default
              hm.tmux
              hm.ai
              hm.programming
              hm.desktop
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
