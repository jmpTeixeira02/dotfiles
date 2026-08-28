{ config, pkgs, lib, ... }:

let
  linkConfig = path: config.lib.file.mkOutOfStoreSymlink "${config.paths.configPath}/${path}";
  isMacOS = pkgs.stdenv.hostPlatform.isDarwin;
in
{
  options = {
    opencodeProfile = lib.mkOption {
      type = lib.types.enum [ "home" "work" ];
      default = "home";
      description = "OpenCode machine config";
    };
    terminal = lib.mkOption {
      type = lib.types.enum [ "ghostty" ];
      default = "ghostty";
      description = "Terminal emulator";
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
        rustup
        openjdk

        # AI
        opencode

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
      ++ lib.optionals (!isMacOS) [
        gcc
        zsh
        xclip
      ];
      file = {
        # ZSH
        ".zshrc".source = linkConfig "zsh/zshrc";
        ".config/zsh/aliases.zsh".source = linkConfig "zsh/aliases.zsh";
        ".config/zsh/tmux-sesh.zsh".source = linkConfig "zsh/tmux-sesh.zsh";
        ".config/zsh/plugins.zsh".source = linkConfig "zsh/plugins.zsh";
        ".config/zsh/fzf.zsh".source = linkConfig "zsh/fzf.zsh";

        ".config/starship".source = linkConfig "starship";
        ".config/lazygit".source = linkConfig "lazygit";
        ".config/nvim".source = linkConfig "nvim";
        ".config/git".source = linkConfig "git";

        ".config/zsh/macos.zsh" = lib.mkIf isMacOS {
          source = linkConfig "zsh/macos.zsh";
        };
        ".config/ghostty" = lib.mkIf (config.terminal == "ghostty") {
          source = linkConfig "ghostty";
        };

        # Opencode
        ".config/opencode/opencode.jsonc".source = linkConfig "opencode/opencode.jsonc";
        ".config/opencode/opencode.json".source = linkConfig "opencode/${config.opencodeProfile}.json";
      };
    };

    programs = {
      home-manager.enable = true;
    };
  };
}
