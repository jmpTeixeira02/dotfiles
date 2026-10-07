{
  flake.modules.homeManager.shell =
    {
      pkgs,
      config,
      lib,
      linkConfig,
      ...
    }:
    let
      isMacOS = pkgs.stdenv.hostPlatform.isDarwin;
    in
    {
      home.packages =
        with pkgs;
        [
          gnumake
          bison

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
        ]
        ++ lib.optionals (!isMacOS) [
          gcc
          xclip
        ];

      xdg.enable = true;
      xdg.configFile = {
        # ZSH
        "zsh/aliases.zsh".source = linkConfig "zsh/aliases.zsh";
        "zsh/plugins.zsh".source = linkConfig "zsh/plugins.zsh";
        "zsh/fzf.zsh".source = linkConfig "zsh/fzf.zsh";
        "zsh/macos.zsh" = lib.mkIf isMacOS {
          source = linkConfig "zsh/macos.zsh";
        };
        "starship".source = linkConfig "starship";
      };

      programs = {
        zsh = {
          enable = true;
          sessionVariables = config.home.sessionVariables;
          initContent = ''
            export FLAKE="${config.paths.dotfiles}/nix"
            export FLAKE_DOTFILES="${config.paths.dotfiles}"
            source ${config.paths.dotfiles}/config/zsh/zshrc
          '';
        };
      };
    };
}
