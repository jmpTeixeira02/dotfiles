{
  config,
  lib,
  ...
}:

{
  sops = {
    secrets = {
      "domain" = {
        sopsFile = ../secrets.yaml;
      };
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
    extraOptions = [
      "--label-file=${config.sops.templates."ddns-updater-labels".path}"
    ];
  };

  sops.templates = {
    "ddns-updater-labels".content = lib.generators.toKeyValue { } {
      "traefik.enable" = "true";
      "traefik.http.routers.ddns-updater.entryPoints" = "websecure";
      "traefik.http.routers.ddns-updater.rule" = "Host(`ddns-updater.${
        config.sops.placeholder."domain"
      }`)";
    };

    "ddns-updater.json".content = builtins.toJSON {
      settings = [
        {
          provider = "desec";
          domain = config.sops.placeholder."domain";
          token = config.sops.placeholder."network/desecToken";
          ip_version = "ipv4";
        }
      ];
    };
  };

}
