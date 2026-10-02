{
  config,
  lib,
  ...
}:

{
  sops = {
    secrets = {
      "network/netbirdToken" = {
        sopsFile = ../secrets.yaml;
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d ${config.mySystem.serviceData}/netbird 0755 1000 1000 -"
  ];

  virtualisation.oci-containers.containers.netbird = {
    image = "ghcr.io/netbirdio/netbird:0.79.0-rootless-ubi";
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
}
