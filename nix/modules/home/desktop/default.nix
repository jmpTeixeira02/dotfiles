{ config, ... }:
{
  flake.modules.homeManager.desktop-default = {
    imports = [
      config.flake.modules.homeManager.desktop-browser
      config.flake.modules.homeManager.desktop-shell
      config.flake.modules.homeManager.desktop-display
      config.flake.modules.homeManager.desktop-discord
    ];

    programs.home-manager.enable = true;
  };
}
