{
  config,
  pkgs,
  lib,
  ...
}:

{
  sops = {
    secrets = {
      "domain" = {
        sopsFile = ../secrets.yaml;
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d ${config.mySystem.poolMount}/movies 0755 1000 1000 -"
    "d ${config.mySystem.poolMount}/tvseries 0755 1000 1000 -"
    "d ${config.mySystem.serviceData}/jellyfin/config 0755 1000 1000 -"
    "d ${config.mySystem.serviceData}/jellyfin/cache 0755 1000 1000 -"
  ];

  virtualisation.oci-containers.containers.jellyfin = {
    image = "ghcr.io/jellyfin/jellyfin:latest";
    autoStart = true;
    volumes = [
      "${config.mySystem.serviceData}/jellyfin/config:/config:rw"
      "${config.mySystem.serviceData}/jellyfin/cache:/cache:rw"
      "${config.mySystem.poolMount}/movies:/media/movies:ro"
      "${config.mySystem.poolMount}/tvseries:/media/tv:ro"
    ];
    environment = {
      PUID = "1000";
      PGID = "1000";
    };
    ports = [
      "8096:8096/tcp"
      "7359:7359/udp"
    ];
    extraOptions = [
      "--label-file=${config.sops.templates."jellyfin-labels".path}"
    ];
  };

  sops.templates = {
    "jellyfin-labels".content = lib.generators.toKeyValue { } {
      "traefik.enable" = "true";
      "traefik.http.routers.jellyfin.entryPoints" = "websecure";
      "traefik.http.routers.jellyfin.rule" = "Host(`jellyfin.${config.sops.placeholder."domain"}`)";
      "traefik.http.services.jellyfin.loadbalancer.server.port" = 8096;
    };
  };

  systemd.services."podman-jellyfin" = {
    restartTriggers = [
      config.sops.templates."jellyfin-labels".content
    ];
  };
}
