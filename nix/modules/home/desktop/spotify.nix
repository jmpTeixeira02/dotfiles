{
  flake.modules.homeManager.desktop-spotify =
    {
      inputs,
      pkgs,
      lib,
      config,
      ...
    }:
    let
      spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
    in
    {
      imports = [ inputs.spicetify-nix.homeManagerModules.spicetify ];
      programs.spicetify = {
        enable = true;
        enabledExtensions = with spicePkgs.extensions; [
          adblock
          hidePodcasts
          shuffle
        ];
        wayland = true;
        theme = spicePkgs.themes.sleek;
        customColorScheme = {
          text = "c5c9c5"; # #c5c9c5
          subtext = "c8c093"; # #c8c093
          sidebar-text = "c5c9c5"; # #c5c9c5
          main = "1f1f28"; # #1f1f28
          sidebar = "181616"; # #181616
          player = "1f1f28"; # #1f1f28
          card = "1f1f28"; # #1f1f28
          shadow = "181616"; # #181616
          selected-row = "9cabca"; # #9cabca
          button = "8a9a7b"; # #8a9a7b
          button-active = "9cabca"; # #9cabca
          button-disabled = "625e5a"; # #625e5a
          tab-active = "363646"; # #363646
          notification = "363646"; # #363646
          notification-error = "c4746e"; # #c4746e
          misc = "54546d"; # #54546d
        };
      };
    };
}
