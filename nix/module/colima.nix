{
  config,
  pkgs,
  linkConfig,
  ...
}:

{
  home.packages = with pkgs; [
    colima
  ];

  xdg.configFile = {
    "zsh/colima.zsh".source = linkConfig "zsh/colima.zsh";
  };
}
