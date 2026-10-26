{ config, ... }:
{
  flake.modules.homeManager.default = {
    imports = [
      config.flake.modules.homeManager.paths
      config.flake.modules.homeManager.encryption
      config.flake.modules.homeManager.ghostty
      config.flake.modules.homeManager.git
      config.flake.modules.homeManager.nvim
      config.flake.modules.homeManager.shell
      config.flake.modules.homeManager.tmux
    ];

    programs.home-manager.enable = true;
    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };
}
