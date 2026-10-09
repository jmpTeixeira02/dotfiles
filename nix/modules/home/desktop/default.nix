{ config, ... }:
{
  flake.modules.homeManager.desktop-default = {
    imports = [
      config.flake.modules.homeManager.desktop-browser
      config.flake.modules.homeManager.desktop-shell
    ];

    programs.home-manager.enable = true;
  };
}
