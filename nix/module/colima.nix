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

  home.file = {
    ".config/zsh/colima.zsh".source = linkConfig "zsh/colima.zsh";
  };
}
