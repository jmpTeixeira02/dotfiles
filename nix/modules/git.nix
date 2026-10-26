{
  flake.modules.homeManager.git =
    {
      pkgs,
      linkConfig,
      config,
      ...
    }:
    {
      home.packages = with pkgs; [
        gh
        gnupg
        lazygit
      ];

      programs.gh = {
        enable = true;
        gitCredentialHelper.enable = true;
      };

      programs.git = {
        enable = true;
        includes = [ { path = "${config.paths.dotfiles}/config/git/config"; } ];
      };

      xdg.configFile."git/work".source = linkConfig "git/work";
      xdg.configFile."lazygit/config.yml".source = linkConfig "lazygit/config.yml";
    };
}
