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
        # Wait for vesktop 1.6.8 to be merged in nixpkgs to fix screenshare audio volume spikes
        # vesktop.enable = true
      };

      # xdg.desktopEntries.vesktop = {
      #   name = "Discord";
      #   genericName = "Discord OpenSource Client (Vesktop)";
      #   exec = "vesktop %U";
      #   icon = "${config.paths.dotfiles}/assets/icons/discord.ico";
      #   categories = [
      #     "Network"
      #     "InstantMessaging"
      #     "Chat"
      #   ];
      #   mimeType = [ "x-scheme-handler/discord" ];
      #   startupNotify = true;
      #   settings.StartupWMClass = "vesktop";
      # };
    };
}
