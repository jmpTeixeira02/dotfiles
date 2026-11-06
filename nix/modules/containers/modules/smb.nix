{
  flake.modules.nixos.homelab-containers-smb =
    {
      config,
      lib,
      ...
    }:

    {
      sops = {
        secrets = {
          "nas/user" = {
            sopsFile = ./secrets.yaml;
          };
          "nas/pass" = {
            sopsFile = ./secrets.yaml;
          };
        };
      };

      virtualisation.oci-containers.containers.smb = {
        image = "docker.io/dockurr/samba:4.23.10@sha256:2a0452a12b7a244a22f18d0f233101bb8d4952b5500ae263905e3b9dad3bf2ae";
        autoStart = true;
        volumes = [
          "${config.mySystem.poolMount}:/storage:rw"
        ];
        environmentFiles = [
          config.sops.templates."smb-env".path
        ];
        ports = [
          "445:445"
        ];
      };

      networking.firewall.allowedTCPPorts = [
        445
      ];

      sops.templates = {
        "smb-env".content = lib.generators.toKeyValue { } {
          NAME = "NAS";
          USER = config.sops.placeholder."nas/user";
          PASS = config.sops.placeholder."nas/pass";
        };
      };

      systemd.services."podman-smb" = {
        restartTriggers = [
          config.sops.templates."smb-env".content
        ];
      };
    };
}
