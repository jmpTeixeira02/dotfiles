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
      programs.discord = {
        enable = true;
      };

      home.packages = with pkgs; [
        whatsie
      ];
    };
}
