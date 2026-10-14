{ config, ... }:
{
  flake.modules.homeManager.desktop-default = {
    imports = [
      config.flake.modules.homeManager.desktop-browser
      config.flake.modules.homeManager.desktop-shell
      config.flake.modules.homeManager.desktop-display
      config.flake.modules.homeManager.desktop-discord
      config.flake.modules.homeManager.desktop-spotify
      config.flake.modules.homeManager.desktop-security
      config.flake.modules.homeManager.desktop-tilling-manager
      config.flake.modules.homeManager.desktop-file-manager
    ];

    programs.home-manager.enable = true;
  };
}
