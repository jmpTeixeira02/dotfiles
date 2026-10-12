{
  flake.modules.nixos.security = { pkgs, ... }: {
    programs.ente-auth.enable = true;
  };
}
