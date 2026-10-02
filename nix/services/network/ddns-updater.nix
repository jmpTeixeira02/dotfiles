{
  config,
  lib,
  ...
}:

{
  sops = {
    secrets = {
      "network/desecToken" = {
        sopsFile = ../secrets.yaml;
      };
    };
  };

  virtualisation.oci-containers.containers.ddns-updater = {
    image = "ghcr.io/qdm12/ddns-updater:v2.8";
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
}
