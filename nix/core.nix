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
  dotfilesRoot = builtins.getEnv "FLAKE_DOTFILES";
  configPath = if dotfilesRoot != "" 
               then "${dotfilesRoot}/config" 
               else "${config.home.homeDirectory}/.dotfiles/config";
in
{
  options = {
    tmux = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Include tmux";
    };
    colima = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Include colima specific fixes";
    };
    terminal = lib.mkOption {
        type = lib.types.str;
        default = "ghostty";
        description = "Terminal emulator";
    };
    macOS = lib.mkOption {
        type = lib.types.bool;
        default = pkgs.stdenv.isDarwin;
        description = "Include macos specific fixes";
    };
  };

  config = {
    home = {
      username = builtins.getEnv "FLAKE_USER";
      homeDirectory = builtins.getEnv "FLAKE_HOME";
      stateVersion = "24.11";
      packages = with pkgs; [
        # Utils
        gnumake
        bison
        nh
        # Core tools
        antigen
        starship
        zoxide
        eza
        bat
        fzf
        tlrc
        fd
        ripgrep
        btop
        lazygit
        sesh
        unzip
        xclip
        mermaid-cli
        tectonic
        imagemagick_light
        ghostscript
        # IDE
        neovim
        go
        nodejs
        python3
        cargo
        # Docker
        docker
        docker-compose
        kubernetes-helm
        lazydocker
        kubectl
        k3d
        k9s
        opentofu
        ansible
        # Git
        gh
        gnupg # Sign commits
      ]
      ++ lib.optionals config.colima [
        colima
      ]
      ++ lib.optionals (!config.macOS) [
        gcc
        zsh
      ];
      file = {
        ".config/nvim".source =
          config.lib.file.mkOutOfStoreSymlink "${configPath}/nvim";
        ".zshrc".source =
            config.lib.file.mkOutOfStoreSymlink "${configPath}/zsh/zshrc";
        ".config/zsh/aliases.zsh".source =
            config.lib.file.mkOutOfStoreSymlink "${configPath}/zsh/aliases.zsh";
        ".config/zsh/tmux-sesh.zsh".source =
            config.lib.file.mkOutOfStoreSymlink "${configPath}/zsh/tmux-sesh.zsh";
        ".config/zsh/plugins.zsh".source =
            config.lib.file.mkOutOfStoreSymlink "${configPath}/zsh/plugins.zsh";
        ".config/zsh/fzf.zsh".source =
            config.lib.file.mkOutOfStoreSymlink "${configPath}/zsh/fzf.zsh";
        ".config/zsh/macos.zsh" = lib.mkIf config.macOS {
            source = config.lib.file.mkOutOfStoreSymlink "${configPath}/zsh/macos.zsh";
        };
        ".config/starship".source =
            config.lib.file.mkOutOfStoreSymlink "${configPath}/starship";
        ".config/zsh/colima.zsh" = lib.mkIf config.colima {
            source = config.lib.file.mkOutOfStoreSymlink "${configPath}/zsh/colima.zsh";
        };
        ".config/ghostty" = lib.mkIf (config.terminal == "ghostty") {
            source = config.lib.file.mkOutOfStoreSymlink "${configPath}/ghostty";
        };
        ".config/tmux/tmux-local.conf" = lib.mkIf config.tmux {
            source = config.lib.file.mkOutOfStoreSymlink "${configPath}/tmux/tmux.conf";
        };
      };
    };

    programs = {
        home-manager.enable = true;
        tmux = lib.mkIf config.tmux {
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
                    set -g @kanagawa-time-format " %R"
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
    };

  };
}
