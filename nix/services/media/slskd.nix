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
      "media/slskd/user" = {
        sopsFile = ../secrets.yaml;
      };
      "media/slskd/pass" = {
        sopsFile = ../secrets.yaml;
      };
      "media/lidarr/apiKey" = {
        sopsFile = ../secrets.yaml;
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d ${config.mySystem.serviceData}/slskd 0755 1000 1000 -"
    "d ${config.mySystem.poolMount}/downloads/slskd 0755 1000 1000 -"
  ];

  virtualisation.oci-containers.containers = {
    slskd = {
      image = "docker.io/slskd/slskd:latest";
      autoStart = true;
      volumes = [
        "${config.mySystem.serviceData}/slskd:/app/data:rw,U"
        "${config.mySystem.poolMount}/downloads/slskd:/app/downloads:rw"
        "${config.sops.templates."slskd.yml".path}:/app/slskd.yml:rw,U"
      ];
      environmentFiles = [
        config.sops.templates."slskd-env".path
      ];
      ports = [
        "5030:5030"
        "5031:5031"
        "50300:50300"
      ];
    };
  };

  sops.templates = {
    "slskd-labels".content = lib.generators.toKeyValue { } {
      "traefik.enable" = "true";
      "traefik.http.routers.slskd.entryPoints" = "websecure";
      "traefik.http.routers.slskd.rule" = "Host(`slskd.${config.sops.placeholder."domain"}`)";
    };
    "slskd.yml".content = lib.generators.toYAML { } {
      web = {
        authentication = {
          disabled = true;
        };
      };
      soulseek = {
        username = config.sops.placeholder."media/slskd/user";
        password = config.sops.placeholder."media/slskd/pass";
      };
    };

    "slskd-env".content = lib.generators.toKeyValue { } {
      SLSKD_REMOTE_CONFIGURATION = "false";
    };
  };

  systemd.services."podman-slskd" = {
    restartTriggers = [
      config.sops.templates."slskd-labels".content
      config.sops.templates."slskd-env".content
      config.sops.templates."slskd.yml".content
    ];
  };
}
