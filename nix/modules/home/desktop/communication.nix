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
        package = pkgs.discord-ptb;
      };

      home.packages = with pkgs; [
        zapzap
      ];
    };
}
