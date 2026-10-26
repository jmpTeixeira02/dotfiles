{
  flake.modules.homeManager.desktop-security =
    { inputs, pkgs, ... }:
    {
      home.packages = with pkgs; [
        bitwarden-desktop
        bitwarden-cli
        ente-cli
      ];
    };

  flake.modules.nixos.security = { pkgs, ... }: {
    programs.ente-auth.enable = true;
    security.pam.services.passwd.enableGnomeKeyring = true;
  };
}
