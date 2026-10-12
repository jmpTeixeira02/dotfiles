{
  flake.modules.homeManager.desktop-tilling-manager =
    {
      inputs,
      pkgs,
      config,
      linkConfig,
      ...
    }:
    {
      home.packages = with pkgs; [
        niri
      ];

      xdg.enable = true;
      xdg.configFile = {
        "niri".source = linkConfig "niri";
      };

    };
}
