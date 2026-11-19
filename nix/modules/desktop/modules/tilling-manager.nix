{
  flake.modules.homeManager.desktop-tilling-manager =
    {
      inputs,
      pkgs,
      config,
      linkConfig,
      ...
    }:
    {
      home.packages = with pkgs; [
        umbriel
      ];

      xdg.enable = true;
      xdg.configFile = {
        "umbriel".source = linkConfig "umbriel";
      };

    };

  flake.modules.nixos.tilling-manager =
    { pkgs, lib, ... }:
    {
      programs.umbriel = {
        enable = true;
      };

      services.displayManager.noctalia-greeter = {
        enable = true;
        settings = {
          keyboard = {
            layout = "pt";
            variant = "mac";
          };
        };
      };

      security.polkit.enable = true;
    };
}
