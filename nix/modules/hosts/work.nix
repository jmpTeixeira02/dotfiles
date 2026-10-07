{
  config,
  inputs,
  ...
}:
let
  hm = config.flake.modules.homeManager;
in
{
  flake.homeConfigurations.work = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = import inputs.nixpkgs {
      system = "aarch64-darwin";
      config = {
        allowUnfree = true;
        allowBroken = true;
      };
    };
    extraSpecialArgs = { inherit inputs; };
    modules = [
      hm.default
      hm.colima
      hm.tmux
      hm.ai
      hm.programming
      {
        opencodeProfile = "work";
        home = {
          username = "joaoteixeira";
          homeDirectory = "/Users/joaoteixeira";
          stateVersion = "26.05";
        };
      }
    ];
  };
}
