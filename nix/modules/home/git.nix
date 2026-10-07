{
  flake.modules.homeManager.git =
    {
      pkgs,
      linkConfig,
      ...
    }:
    {
      home.packages = with pkgs; [
        git
        lazygit
        gh
        gnupg
      ];

      xdg.enable = true;
      xdg.configFile = {
        "lazygit".source = linkConfig "lazygit";
        "git".source = linkConfig "git";
      };
    };
}
