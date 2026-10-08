{
  config,
  inputs,
  ...
}:
let
  hm = config.flake.modules.homeManager;
in
{
  flake.homeConfigurations.wsl = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = import inputs.nixpkgs {
      system = "x86_64-linux";
      config = {
        allowUnfree = true;
        allowBroken = true;
      };
    };
    extraSpecialArgs = { inherit inputs; };
    modules = [
      hm.default
      hm.ai
      hm.programming
      {
        opencodeProfile = "home";
        home = {
          username = "joao";
          homeDirectory = "/home/joao";
          stateVersion = "26.05";
        };
      }
    ];
  };
}
