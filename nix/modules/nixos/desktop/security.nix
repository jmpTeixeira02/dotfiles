{
  flake.modules.nixos.security = { pkgs, ... }: {
    programs.ente-auth.enable = true;
    security.pam.services.passwd.enableGnomeKeyring = true;
  };
}
