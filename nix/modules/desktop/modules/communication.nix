{
  flake.modules.homeManager.desktop-communication =
    { pkgs, lib, ... }:
    {
      home.packages = with pkgs; [
        zapzap
      ];

      programs.discord = {
        enable = true;
      };
    };
}
