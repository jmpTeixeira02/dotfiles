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

          # Here just for the zsh plugins
          git
          tmux
          kubectl
        ]
        ++ lib.optionals (!isMacOS) [
          gcc
          xclip
        ];

      xdg.enable = true;
      xdg.configFile = {
        # ZSH
        "zsh/aliases.zsh".source = linkConfig "zsh/aliases.zsh";
        "zsh/fzf.zsh".source = linkConfig "zsh/fzf.zsh";
        "zsh/macos.zsh" = lib.mkIf isMacOS {
          source = linkConfig "zsh/macos.zsh";
        };
        "starship".source = linkConfig "starship";
      };
      xdg.dataFile."zsh/.keep".text = "do not delete me";

      programs = {
        zsh = {
          sessionVariables = config.home.sessionVariables;

          enable = true;
          enableCompletion = false;
          autosuggestion.enable = true;
          syntaxHighlighting.enable = true;

          oh-my-zsh = {
            enable = true;
            plugins = [
              "git"
              "eza"
              "tmux"
              "kubectl"
            ];
            extraConfig = ''
              ZSH_TMUX_DEFAULT_SESSION_NAME="master"
              ZSH_TMUX_UNICODE=true
              [[ -z "$SSH_CONNECTION" ]] && ZSH_TMUX_AUTOSTART=true
            '';

          };

          plugins = [
            {
              name = "zsh-autocomplete";
              src = pkgs.zsh-autocomplete;
              file = "share/zsh-autocomplete/zsh-autocomplete.plugin.zsh";
            }
          ];

          initContent = ''
            export FLAKE="${config.paths.dotfiles}/nix"
            export FLAKE_DOTFILES="${config.paths.dotfiles}"
            source ${config.paths.dotfiles}/config/zsh/zshrc
          '';
        };
      };
    };
}
