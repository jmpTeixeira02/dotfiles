{
  flake.modules.homeManager.desktop-shell =
    { inputs, pkgs, ... }:
    {
      home.packages = with pkgs; [
        noctalia-shell
      ];
    };
}
