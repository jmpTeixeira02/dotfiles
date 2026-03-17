{ config, pkgs, lib, ... }:

let
  kanagawa = pkgs.tmuxPlugins.mkTmuxPlugin {
    pluginName = "kanagawa";
    version = "stable-2024-09-12";
    src = pkgs.fetchFromGitHub {
      owner = "Nybkox";
      repo = "tmux-kanagawa";
      rev = "master";
      sha256 = "sFL9/PMdPJxN7tgpc4YbUHW4PkCXlKmY7a7gi7PLcn8=";
    };
  };
in
{
  home.packages = with pkgs; [
    tmux
    sesh
  ];

  home.file = {
    ".config/tmux/tmux-local.conf".source =
      config.lib.file.mkOutOfStoreSymlink "${config.paths.configPath}/tmux/tmux.conf";
  };

  programs.tmux = {
    enable = true;
    terminal = "tmux-256color";
    baseIndex = 1;
    keyMode = "vi";
    mouse = true;
    clock24 = true;
    plugins = with pkgs.tmuxPlugins; [
      {
        plugin = kanagawa;
        extraConfig = ''
          set -g @kanagawa-plugins "ssh-session  time"
          set -g @kanagawa-show-timezone false
          set -g @kanagawa-theme dragon
          set -g @kanagawa-day-month true
          set -g @kanagawa-show-powerline true
          set -g @kanagawa-military-time true
          set -g @kanagawa-show-left-icon session
          # set -g @kanagawa-time-colors "cyan gray"
          set -g @kanagawa-time-format " %R"
          set -g @kanagawa-ignore-window-colors true
        '';
      }
      yank
      vim-tmux-navigator
      tmux-thumbs
      better-mouse-mode
      tmux-fzf
      sensible
      resurrect
      continuum
    ];
    extraConfig = ''
      source-file ~/.config/tmux/tmux-local.conf
    '';
  };
}
