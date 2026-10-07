{
  pkgs,
  linkConfig,
  ...
}:

{
  home.packages = with pkgs; [
    ghostty
  ];

  xdg.configFile = {
    "ghostty".source = linkConfig "ghostty";
  };
}
