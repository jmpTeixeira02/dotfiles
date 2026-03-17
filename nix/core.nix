{ config, pkgs, lib, ... }:

let
  dotfilesRoot = builtins.getEnv "FLAKE_DOTFILES";
  configPath = if dotfilesRoot != ""
               then "${dotfilesRoot}/config"
               else "${config.home.homeDirectory}/.dotfiles/config";
in
{
  options = {
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
        unzip
        xclip
        mermaid-cli

        # IDE
        neovim
        tectonic
        imagemagick_light
        ghostscript

        # Languages
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
      };
    };

    programs = {
        home-manager.enable = true;
    };

  };
}
