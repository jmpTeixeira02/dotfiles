{
  flake.modules.homeManager.desktop-communication =
    { pkgs, lib, ... }:
    {
      home.packages = with pkgs; [
        zapfast
      ];

      programs.discord = {
        enable = true;
      };
      # Fix warning for settings.json as discord writes itself
      xdg.configFile."discord/settings.json".enable = lib.mkForce false;
    };
}
