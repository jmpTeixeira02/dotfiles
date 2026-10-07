{
  flake.modules.homeManager.paths =
    { config, lib, ... }:
    let
      envRoot = builtins.getEnv "FLAKE_DOTFILES";
    in
    {
      options.paths = {
        dotfiles = lib.mkOption {
          type = lib.types.str;
          default = if envRoot != "" then envRoot else "${config.home.homeDirectory}/dotfiles";
          description = "Path of the dotfiles repo";
        };
      };

      config = {
        _module.args.linkConfig =
          path: config.lib.file.mkOutOfStoreSymlink "${config.paths.dotfiles}/config/${path}";
        home.sessionVariables = {
          FLAKE_DOTFILES = config.paths.dotfiles;
          FLAKE = "${config.paths.dotfiles}/nix";
        };
      };
    };
}
