{
  flake.modules.homeManager.git =
    {
      pkgs,
      linkConfig,
      ...
    }:
    {
      home.packages = with pkgs; [
        gnupg
        lazygit
      ];

      programs.gh = {
        enable = true;
        gitCredentialHelper.enable = true;
      };

      xdg.configFile = {
        "git".source = linkConfig "git";
        "lazygit".source = linkConfig "lazygit";
      };
    };
}
