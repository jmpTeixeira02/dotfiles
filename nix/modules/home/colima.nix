{
  flake.modules.homeManager.colima =
    {
      pkgs,
      linkConfig,
      ...
    }:
    {
      home.packages = with pkgs; [
        colima
      ];

      xdg.enable = true;
      xdg.configFile = {
        "zsh/colima.zsh".source = linkConfig "zsh/colima.zsh";
      };
    };
}
