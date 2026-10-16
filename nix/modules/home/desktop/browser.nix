{
  flake.modules.homeManager.desktop-browser =
    { inputs,pkgs, ... }:
    let
      mkExtensionSettings = builtins.mapAttrs (
        _: pluginId: {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/${pluginId}/latest.xpi";
          installation_mode = "force_installed";
        }
      );
    in
    {
      imports = [
        inputs.zen-browser.homeModules.beta
      ];

      home.packages = with pkgs; [
        google-chrome
      ];

      programs.zen-browser = {
        enable = true;
        setAsDefaultBrowser = true;
        policies = {
          ExtensionSettings = mkExtensionSettings {
            "uBlock0@raymondhill.net" = "ublock-origin";
            "addon@darkreader.org" = "darkreader";
            "{446900e4-71c2-419f-a6a7-df9c091e268b}" = "bitwarden-password-manager";
          };
        };
      };
    };
}
