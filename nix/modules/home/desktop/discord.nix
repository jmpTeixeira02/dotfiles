{
  flake.modules.homeManager.desktop-discord =
    {
      inputs,
      pkgs,
      lib,
      config,
      ...
    }:
    let
      noctaliaActive = lib.elem pkgs.noctalia config.home.packages;
    in
    {
      programs.vesktop = {
        enable = true;
        vencord.settings.enabledThemes = lib.mkIf noctaliaActive [
          "noctalia.theme.css"
        ];
      };

      xdg.desktopEntries.vesktop = {
        name = "Discord";
        genericName = "Discord OpenSource Client (Vesktop)";
        exec = "vesktop %U";
        icon = "${config.paths.dotfiles}/assets/icons/discord.ico";
        categories = [
          "Network"
          "InstantMessaging"
          "Chat"
        ];
        mimeType = [ "x-scheme-handler/discord" ];
        startupNotify = true;
        settings.StartupWMClass = "vesktop";
      };
    };
}
