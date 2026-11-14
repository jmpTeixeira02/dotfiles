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
        image = "ghcr.io/netbirdio/netbird:0.83.1-rootless-ubi@sha256:71acb05ad4a421fac89e64a7f9cd9bac9af5812a8b91f0600690552c265bddbd";
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
