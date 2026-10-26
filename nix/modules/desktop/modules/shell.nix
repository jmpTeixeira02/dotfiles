{
  flake.modules.homeManager.desktop-shell =
    {
      inputs,
      pkgs,
      config,
      linkConfig,
      ...
    }:
    {
      home.packages = with pkgs; [
        noctalia
        gowall
      ];

      home.file."Pictures/wallpapers".source =
        config.lib.file.mkOutOfStoreSymlink "${config.paths.dotfiles}/assets/wallpapers";

      xdg.enable = true;
      xdg.configFile = {
        "gowall".source = linkConfig "gowall";
        "noctalia".source = linkConfig "noctalia";
      };

    };
}
