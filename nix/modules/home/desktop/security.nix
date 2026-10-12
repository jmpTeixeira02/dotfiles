{
  flake.modules.homeManager.desktop-security =
    { inputs, pkgs, ... }:
    {
      home.packages = with pkgs; [
        bitwarden-desktop
        bitwarden-cli
      ];
    };
}
