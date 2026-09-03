{
  config,
  pkgs,
  lib,
  linkConfig,
  ...
}:

let
  isMacOS = pkgs.stdenv.hostPlatform.isDarwin;
in
{
  options = {
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
      packages =
        with pkgs;
        [
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

          git
          lazygit
          gh
          gnupg # Sign commits

          # File Encryption
          age
          sops
        ]
        ++ lib.optionals (!isMacOS) [
          gcc
          xclip
        ];
      file = {
        # ZSH
        ".config/zsh/aliases.zsh".source = linkConfig "zsh/aliases.zsh";
        ".config/zsh/plugins.zsh".source = linkConfig "zsh/plugins.zsh";
        ".config/zsh/fzf.zsh".source = linkConfig "zsh/fzf.zsh";
        ".config/zsh/macos.zsh" = lib.mkIf isMacOS {
          source = linkConfig "zsh/macos.zsh";
        };
        ".config/starship".source = linkConfig "starship";
        ".config/ghostty" = lib.mkIf (config.terminal == "ghostty") {
          source = linkConfig "ghostty";
        };
        ".config/nvim".source = linkConfig "nvim";
        ".config/lazygit".source = linkConfig "lazygit";
        ".config/git".source = linkConfig "git";
      };
    };

    programs = {
      home-manager.enable = true;

      zsh = {
        enable = true;
        initContent = ''
          source ${linkConfig "zsh/zshrc"}
        '';
      };
    };

    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };
}
