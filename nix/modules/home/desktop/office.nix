{
  flake.modules.homeManager.desktop-office =
    { inputs, pkgs, ... }:
    {
      home.packages = with pkgs; [
        euro-office-desktopeditors
      ];
    };
}
