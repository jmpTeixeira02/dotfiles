{
  flake.modules.homeManager.desktop-display =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        xwayland-satellite
      ];
    };
}
