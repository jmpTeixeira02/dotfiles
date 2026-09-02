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
    "d ${config.mySystem.serviceData}/navidrome 0755 1000 1000 -"
    "d ${config.mySystem.poolMount}/music 0755 1000 1000 -"
  ];

  virtualisation.oci-containers.containers.navidrome = {
    image = "docker.io/deluan/navidrome:latest";
    autoStart = true;
    volumes = [
      "${config.mySystem.serviceData}/navidrome:/data:rw"
      "${config.mySystem.poolMount}/music:/music:ro"
    ];
    environment = {
      ND_ENABLEUSEREDITING = "false";
      ND_EXTAUTH_TRUSTEDSOURCES = "0.0.0.0/0";
      ND_REVERSEPROXYUSERHEADER = "Remote-User";
    };
    extraOptions = [
      "--label-file=${config.sops.templates."navidrome-labels".path}"
    ];
  };

  sops.templates = {
    "navidrome-labels".content = lib.generators.toKeyValue { } {
      "traefik.enable" = "true";
      "traefik.http.routers.navidrome.entryPoints" = "websecure";
      "traefik.http.routers.navidrome.rule" = "Host(`navidrome.${config.sops.placeholder."domain"}`)";
      "traefik.http.routers.navidrome.middlewares" = "authelia@docker";

      "traefik.http.routers.navidrome-subsonic.rule" = "Host(`navidrome.${
        config.sops.placeholder."domain"
      }`) && PathPrefix(`/rest/`) && !Query(`c`, `NavidromeUI`)";
      "traefik.http.routers.navidrome-subsonic.entrypoints" = "websecure";
      "traefik.http.routers.navidrome-subsonic.middlewares" = "authelia@docker";
    };
  };

  systemd.services."podman-navidrome" = {
    restartTriggers = [
      config.sops.templates."navidrome-labels".content
    ];
  };
}
