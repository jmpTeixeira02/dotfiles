{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    colima
  ];

  home.file = {
    ".config/zsh/colima.zsh".source =
      config.lib.file.mkOutOfStoreSymlink "${config.paths.configPath}/zsh/colima.zsh";
  };
}
