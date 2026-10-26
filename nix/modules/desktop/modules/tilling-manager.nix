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
        niri
        nirius
      ];

      xdg.enable = true;
      xdg.configFile = {
        "niri".source = linkConfig "niri";
      };

    };

  flake.modules.nixos.tilling-manager =
    { pkgs, lib, ... }:
    let
      # https://github.com/niri-wm/niri/pull/4392
      niriSrc = pkgs.fetchFromGitHub {
        owner = "niri-wm";
        repo = "niri";
        rev = "refs/pull/4392/head";
        hash = "sha256-K8rKFl1DsR+PSfLuHilQWtb95NaD1jsDy5fbeVOtukc=";
      };

      niriForceRender = pkgs.niri.overrideAttrs (old: {
        src = niriSrc;
        cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
          src = niriSrc;
          hash = "sha256-vtTh+TG6TdX46QydGKaeo50u2qdQf3UkQ50EML+5H9c=";
        };
      });
    in
    {
      programs.niri = {
        enable = true;
        package = niriForceRender;
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
