{
  flake.modules.homeManager.desktop-communication =
    {
      inputs,
      pkgs,
      lib,
      config,
      ...
    }:
    {
      home.packages = with pkgs; [
        zapzap
      ];

      programs = {
        discord = {
          enable = true;
          package = pkgs.discord-canary;
        };
      };
    };
}
