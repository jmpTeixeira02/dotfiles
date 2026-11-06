{
  flake.modules.nixos.homelab-containers-ddns-updater =
    {
      config,
      lib,
      ...
    }:

    {
      sops = {
        secrets = {
          "network/desecToken" = {
            sopsFile = ./secrets.yaml;
          };
        };
      };

      virtualisation.oci-containers.containers.ddns-updater = {
        image = "ghcr.io/qdm12/ddns-updater:v2.10.0@sha256:3e2aa558946b5a293def4d73008fa4651c072b2c12932cecd02126fb23979831";
        autoStart = true;
        volumes = [
          "${config.sops.templates."ddns-updater.json".path}:/updater/data/config.json:ro,U"
        ];
        labels = {
          "traefik.enable" = "true";
          "traefik.http.routers.ddns-updater.entryPoints" = "websecure";
          "traefik.http.routers.ddns-updater.rule" = "Host(`ddns-updater.${config.domain}`)";
        };
      };

      sops.templates = {
        "ddns-updater.json".content = builtins.toJSON {
          settings = [
            {
              provider = "desec";
              domain = config.domain;
              token = config.sops.placeholder."network/desecToken";
              ip_version = "ipv4";
            }
          ];
        };
      };

      systemd.services."podman-ddns-updater" = {
        restartTriggers = [
          config.sops.templates."ddns-updater.json".content
        ];
      };
    };
}
