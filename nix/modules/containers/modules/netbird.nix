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
        image = "ghcr.io/netbirdio/netbird:0.83.2-rootless-ubi@sha256:aeab13429452dd8b310f7ece6756eadd0da5a48f925ceeb5270ee8587a30f9e5";
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
