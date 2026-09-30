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
    };
  };

  systemd.tmpfiles.rules = [
    "d ${config.mySystem.poolMount}/music 0755 1000 1000 -"
    "d ${config.mySystem.poolMount}/downloads 0755 1000 1000 -"
    "d ${config.mySystem.serviceData}/aurral 0755 1000 1000 -"
  ];

  virtualisation.oci-containers.containers.aurral = {
    image = "ghcr.io/lklynet/aurral:2.10";
    autoStart = true;
    volumes = [
      "${config.mySystem.serviceData}/aurral:/config:rw,U"
      "${config.mySystem.poolMount}/music:/data:rw"
    ];
    environment = {
      PUID = "1000";
      PGID = "1000";
    };
    ports = [
      "3001:3001"
    ];
    extraOptions = [
      "--label-file=${config.sops.templates."aurral-labels".path}"
    ];
  };

  sops.templates = {
    "aurral-labels".content = lib.generators.toKeyValue { } {
      "traefik.enable" = "true";
      "traefik.http.routers.aurral.entryPoints" = "websecure";
      "traefik.http.routers.aurral.rule" = "Host(`aurral.${config.sops.placeholder."domain"}`)";
    };
  };

  systemd.services."podman-aurral" = {
    restartTriggers = [
      config.sops.templates."aurral-labels".content
    ];
  };
}
