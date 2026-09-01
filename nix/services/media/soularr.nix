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
      "media/slskd/apiKey" = {
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
    "d ${config.mySystem.serviceData}/soularr 0755 1000 1000 -"
    "d ${config.mySystem.poolMount}/downloads/slskd 0755 1000 1000 -"
  ];

  virtualisation.oci-containers.containers = {
    slskd = {
      image = "docker.io/slskd/slskd:latest";
      autoStart = true;
      volumes = [
        "${config.mySystem.serviceData}/slskd:/app/data:rw,U"
        "${config.mySystem.poolMount}/downloads/slskd:/app/downloads:rw,U"
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
    soularr = {
      image = "docker.io/mrusse08/soularr:latest";
      autoStart = true;
      dependsOn = [ "slskd" ];
      volumes = [
        "${config.sops.templates."soularr-config".path}:/data/config.ini:rw"
        "${config.mySystem.serviceData}/soularr:/data:rw,U"
        "${config.mySystem.poolMount}/downloads/slskd:/downloads:rw"
      ];
      environment = {
        PUID = "1000";
        PGID = "1000";
        SCRIPT_INTERVAL = "300";
      };
    };
  };

  sops.templates = {
    "soularr-config".content = ''
      [Lidarr]
      api_key = ${config.sops.placeholder."media/lidarr/apiKey"}
      host_url = http://lidarr:8686
      download_dir = /downloads
      disable_sync = False

      [Slskd]
      api_key = ${config.sops.placeholder."media/slskd/apiKey"}
      host_url = http://slskd:5030
      url_base = /
      download_dir = /downloads
      delete_searches = False
      stalled_timeout = 3600
    '';

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

  systemd.services."podman-soularr" = {
    restartTriggers = [
      config.sops.templates."soularr-config".content
      config.sops.templates."slskd-env".content
      config.sops.templates."slskd.yml".content
    ];
  };
}
