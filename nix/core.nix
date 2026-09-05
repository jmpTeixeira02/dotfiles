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
  imports = [ ./module/nvim.nix ];

  options = {
    terminal = lib.mkOption {
      type = lib.types.enum [ "ghostty" ];
      default = "ghostty";
      description = "Terminal emulator";
    };
  };

  config = {
    xdg.enable = true;

    home = {
      username = builtins.getEnv "FLAKE_USER";
      homeDirectory = builtins.getEnv "FLAKE_HOME";
      stateVersion = "26.05";
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
    };

    xdg.configFile = {
      # ZSH
      "zsh/zshrc".source = linkConfig "zsh/zshrc";
      "zsh/aliases.zsh".source = linkConfig "zsh/aliases.zsh";
      "zsh/plugins.zsh".source = linkConfig "zsh/plugins.zsh";
      "zsh/fzf.zsh".source = linkConfig "zsh/fzf.zsh";
      "zsh/macos.zsh" = lib.mkIf isMacOS {
        source = linkConfig "zsh/macos.zsh";
      };
      "starship".source = linkConfig "starship";
      "ghostty" = lib.mkIf (config.terminal == "ghostty") {
        source = linkConfig "ghostty";
      };
      "lazygit".source = linkConfig "lazygit";
      "git".source = linkConfig "git";
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
