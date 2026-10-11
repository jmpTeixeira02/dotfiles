{ config, ... }:
{
  flake.modules.homeManager.desktop-default = {
    imports = [
      config.flake.modules.homeManager.desktop-browser
      config.flake.modules.homeManager.desktop-shell
      config.flake.modules.homeManager.desktop-display
      config.flake.modules.homeManager.desktop-discord
      config.flake.modules.homeManager.desktop-spotify
    ];

    programs.home-manager.enable = true;
  };
}
