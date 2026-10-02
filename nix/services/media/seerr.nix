{
  pkgs,
  config,
  lib,
  ...
}:

{
  systemd.tmpfiles.rules = [
    "d ${config.mySystem.serviceData}/seerr 0755 1000 1000 -"
  ];

  virtualisation.oci-containers.containers.seerr = {
    image = "ghcr.io/seerr-team/seerr:latest";
    autoStart = true;
    volumes = [
      "${config.mySystem.serviceData}/seerr:/app/config:rw,U"
    ];
    ports = [
      "5055:5055"
    ];
    extraOptions = [
      "--label-file=${config.sops.templates."seerr-labels".path}"
    ];
  };

  sops.templates = {
    "seerr-labels".content = lib.generators.toKeyValue { } {
      "traefik.enable" = "true";
      "traefik.http.routers.seerr.entryPoints" = "websecure";
      "traefik.http.routers.seerr.rule" = "Host(`seerr.${config.domain}`)";
    };
  };

  systemd.services."podman-seerr" = {
    after = [
      "podman-sonarr.service"
      "podman-radarr.service"
      "podman-jellyfin.service"
    ];
    requires = [
      "podman-sonarr.service"
      "podman-radarr.service"
      "podman-jellyfin.service"
    ];
    restartTriggers = [
      config.sops.templates."seerr-labels".content
    ];
  };
}
