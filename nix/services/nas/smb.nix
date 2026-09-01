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
      "nas/user" = {
        sopsFile = ../secrets.yaml;
      };
      "nas/pass" = {
        sopsFile = ../secrets.yaml;
      };
    };
  };

  virtualisation.oci-containers.containers.smb = {
    image = "docker.io/dockurr/samba:latest";
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
}
