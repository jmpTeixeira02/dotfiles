{
  flake.modules.homeManager.desktop-media =
    { inputs, pkgs, ... }:
    {
      programs.mpv.enable = true;

      home.packages = with pkgs; [
        stremio-linux-shell
      ];
    };
}
