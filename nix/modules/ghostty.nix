{
  flake.modules.homeManager.ghostty =
    {
      lib,
      pkgs,
      linkConfig,
      ...
    }:
    {
      home.packages = lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.ghostty ];

      xdg.enable = true;
      xdg.configFile = {
        "ghostty".source = linkConfig "ghostty";
      };
    };
}
