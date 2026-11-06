{
  flake.modules.nixos.homelab-containers-netbird =
    {
      config,
      lib,
      ...
    }:

    {
      sops = {
        secrets = {
          "network/netbirdToken" = {
            sopsFile = ./secrets.yaml;
          };
        };
      };

      systemd.tmpfiles.rules = [
        "d ${config.mySystem.serviceData}/netbird 0755 homelab homelab -"
      ];

      virtualisation.oci-containers.containers.netbird = {
        image = "ghcr.io/netbirdio/netbird:0.82.0-rootless-ubi@sha256:738b60b647c4556e46270d5d1662d40215d2c28fa0496bb087997dbdd8c380f2";
        autoStart = true;
        volumes = [
          "${config.mySystem.serviceData}/netbird:/config:rw"
        ];
        environmentFiles = [
          config.sops.templates."netbird-env".path
        ];
      };

      sops.templates = {
        "netbird-env".content = lib.generators.toKeyValue { } {
          NB_SETUP_KEY = config.sops.placeholder."network/netbirdToken";
        };
      };

      systemd.services."podman-netbird" = {
        restartTriggers = [
          config.sops.templates."netbird-env".path
        ];
      };
    };
}
