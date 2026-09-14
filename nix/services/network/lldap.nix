{ config, lib, ... }:

{
  sops = {
    secrets = {
      "network/lldap/jwt" = {
        sopsFile = ../secrets.yaml;
      };
      "network/lldap/admin_pass" = {
        sopsFile = ../secrets.yaml;
      };
      "network/lldap/domain" = {
        sopsFile = ../secrets.yaml;
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d ${config.mySystem.serviceData}/lldap 0755 1000 1000 -"
  ];

  virtualisation.oci-containers.containers.lldap = {
    image = "docker.io/lldap/lldap:stable";
    autoStart = true;
    volumes = [
      "${config.mySystem.serviceData}/lldap:/data:rw"
    ];
    environmentFiles = [
      config.sops.templates."lldap-env".path
    ];
    extraOptions = [
      "--label-file=${config.sops.templates."lldap-labels".path}"
    ];
  };

  sops.templates = {
    "lldap-env".content = lib.generators.toKeyValue { } {
      LLDAP_JWT_SECRET = config.sops.placeholder."network/lldap/jwt";
      LLDAP_LDAP_USER_PASS = config.sops.placeholder."network/lldap/admin_pass";
      LLDAP_LDAP_BASE_DN = config.sops.placeholder."network/lldap/domain";
      HTTP_PORT = "17170";
      LDAP_PORT = "3890";
    };

    "lldap-labels".content = lib.generators.toKeyValue { } {
      "traefik.enable" = "true";
      "traefik.http.routers.lldap.entryPoints" = "websecure";
      "traefik.http.routers.lldap.rule" = "Host(`lldap.${config.sops.placeholder."domain"}`)";
      "traefik.http.services.lldap.loadbalancer.server.port" = "17170";
    };
  };

  systemd.services."podman-lldap" = {
    restartTriggers = [
      config.sops.templates."lldap-env".path
      config.sops.templates."lldap-labels".path
    ];
  };
}
