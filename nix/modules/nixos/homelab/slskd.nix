{
  flake.modules.nixos.containers =
    {
      config,
      pkgs,
      lib,
      ...
    }:

    {
      sops = {
        secrets = {
          "media/slskd/user" = {
            sopsFile = ./secrets.yaml;
          };
          "media/slskd/pass" = {
            sopsFile = ./secrets.yaml;
          };
        };
      };

      systemd.tmpfiles.rules = [
        "d ${config.mySystem.serviceData}/slskd 0755 homelab homelab -"

        "d ${config.mySystem.poolMount}/downloads/slskd 0755 homelab homelab -"
        "d ${config.mySystem.poolMount}/music 0755 homelab homelab -"
      ];

      virtualisation.oci-containers.containers.slskd = {
        image = "docker.io/slskd/slskd:latest";
        autoStart = true;
        user = "1000:1000";
        volumes = [
          "${config.mySystem.serviceData}/slskd:/app:rw"
          "${config.mySystem.poolMount}/downloads/slskd:/app/downloads:rw"
          "${config.mySystem.poolMount}/music:/music:ro"
          "${config.sops.templates."slskd.yml".path}:/app/slskd.yml:rw"
        ];
        environmentFiles = [
          config.sops.templates."slskd-env".path
        ];
        ports = [
          "5030:5030"
          "5031:5031"
          "50300:50300"
        ];
        labels = {
          "traefik.enable" = "true";
          "traefik.http.routers.slskd.entryPoints" = "websecure";
          "traefik.http.routers.slskd.rule" = "Host(`slskd.${config.domain}`)";
        };
      };

      sops.templates = {
        "slskd.yml" = {
          owner = "homelab";
          group = config.users.users.homelab.group;
          mode = "0400";
          content = lib.generators.toYAML { } {
            web = {
              authentication = {
                disabled = true;
              };
            };
            shares = {
              directories = [
                "/music"
              ];
            };
            soulseek = {
              username = config.sops.placeholder."media/slskd/user";
              password = config.sops.placeholder."media/slskd/pass";
            };
          };
        };

        "slskd-env".content = lib.generators.toKeyValue { } {
          SLSKD_REMOTE_CONFIGURATION = "false";
        };
      };

      systemd.services."podman-slskd" = {
        restartTriggers = [
          config.sops.templates."slskd-env".content
          config.sops.templates."slskd.yml".content
        ];
      };
    };
}
