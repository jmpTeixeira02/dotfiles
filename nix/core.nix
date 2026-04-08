{ config, pkgs, lib, ... }:

{
  options = {
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
        unzip
        xclip

        # IDE
        neovim
        tectonic
        imagemagick_light
        ghostscript
        mermaid-cli

        # Languages
        go
        graphviz # Go Profiler dependency
        buf # Protobuf
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

        # File Encryption
        age
        sops

        # Git
        git
        lazygit
        gh
        gnupg # Sign commits
      ]
      ++ lib.optionals (!config.macOS) [
        gcc
        zsh
      ];
      file = {
        ".config/nvim".source =
          config.lib.file.mkOutOfStoreSymlink "${config.paths.configPath}/nvim";
        ".zshrc".source =
            config.lib.file.mkOutOfStoreSymlink "${config.paths.configPath}/zsh/zshrc";
        ".config/zsh/aliases.zsh".source =
            config.lib.file.mkOutOfStoreSymlink "${config.paths.configPath}/zsh/aliases.zsh";
        ".config/zsh/tmux-sesh.zsh".source =
            config.lib.file.mkOutOfStoreSymlink "${config.paths.configPath}/zsh/tmux-sesh.zsh";
        ".config/zsh/plugins.zsh".source =
            config.lib.file.mkOutOfStoreSymlink "${config.paths.configPath}/zsh/plugins.zsh";
        ".config/zsh/fzf.zsh".source =
            config.lib.file.mkOutOfStoreSymlink "${config.paths.configPath}/zsh/fzf.zsh";
        ".config/zsh/macos.zsh" = lib.mkIf config.macOS {
            source = config.lib.file.mkOutOfStoreSymlink "${config.paths.configPath}/zsh/macos.zsh";
        };
        ".config/starship".source =
            config.lib.file.mkOutOfStoreSymlink "${config.paths.configPath}/starship";
        ".config/ghostty" = lib.mkIf (config.terminal == "ghostty") {
            source = config.lib.file.mkOutOfStoreSymlink "${config.paths.configPath}/ghostty";
        };
      };
    };

    programs = {
        home-manager.enable = true;
    };

  };
}
