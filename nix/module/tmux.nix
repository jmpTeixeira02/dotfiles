{
  pkgs,
  linkConfig,
  ...
}:

let
  theme = pkgs.tmuxPlugins.mkTmuxPlugin {
    pluginName = "ukiyo";
    version = "unstable-2026-09-18";
    src = pkgs.fetchFromGitHub {
      owner = "Nybkox";
      repo = "tmux-ukiyo";
      rev = "b1b45a178010c228bfbb7da40862083553b549c1";
      sha256 = "yqPc11FT+CoHF+MNbmTBSlMRy4hCHiRULiylyNe8jnY=";
    };
  };
in
{
  home.packages = with pkgs; [
    tmux
    sesh
  ];

  xdg.configFile = {
    "tmux/tmux-local.conf".source = linkConfig "tmux/tmux.conf";
    "zsh/tmux-sesh.zsh".source = linkConfig "zsh/tmux-sesh.zsh";
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
        plugin = theme;
        extraConfig = ''
          set -g @ukiyo-plugins "ssh-session  time"
          set -g @ukiyo-show-timezone false
          set -g @ukiyo-theme "kanagawa/dragon"
          set -g @ukiyo-day-month true
          set -g @ukiyo-show-powerline true
          set -g @ukiyo-military-time true
          set -g @ukiyo-show-left-icon session
          set -g @ukiyo-time-format " %R"
          set -g @ukiyo-ignore-window-colors true
        '';
      }
      yank
      vim-tmux-navigator
      tmux-thumbs
      better-mouse-mode
      tmux-fzf
      sensible
      {
        plugin = resurrect;
        extraConfig = ''
          set -g @resurrect-capture-pane-contents 'on'
        '';
      }
      {
        plugin = continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '10'
        '';
      }
    ];
    extraConfig = ''
      source-file ~/.config/tmux/tmux-local.conf
    '';
  };
}
