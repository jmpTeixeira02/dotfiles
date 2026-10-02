{
  config,
  lib,
  pkgs,
  ...
}:

let
  users = {
    joao = {
      displayName = "joao";
    };
  };
in
{
  sops.secrets = {
    "network/lldap/jwt" = {
      sopsFile = ../secrets.yaml;
    };
    "network/lldap/admin_pass" = {
      sopsFile = ../secrets.yaml;
    };
    "network/lldap/domain" = {
      sopsFile = ../secrets.yaml;
    };
  }
  // lib.listToAttrs (
    lib.concatMap (
      name:
      map
        (field: lib.nameValuePair "network/lldap/users/${name}/${field}" { sopsFile = ../secrets.yaml; })
        [
          "pass"
          "email"
        ]
    ) (lib.attrNames users)
  );

  systemd.tmpfiles.rules = [
    "d ${config.mySystem.serviceData}/lldap 0755 1000 1000 -"
  ];

  virtualisation.oci-containers.containers.lldap = {
    image = "docker.io/lldap/lldap:stable";
    autoStart = true;
    volumes = [
      "${config.mySystem.serviceData}/lldap:/data:rw"
    ]
    ++ lib.mapAttrsToList (
      name: _:
      "${config.sops.templates."lldap-user-${name}".path}:/bootstrap/user-configs/${name}.json:ro"
    ) users;
    environmentFiles = [
      config.sops.templates."lldap-env".path
    ];
    labels = {
      "traefik.enable" = "true";
      "traefik.http.routers.lldap.entryPoints" = "websecure";
      "traefik.http.routers.lldap.rule" = "Host(`lldap.${config.domain}`)";
      "traefik.http.services.lldap.loadbalancer.server.port" = "17170";
    };
  };

  sops.templates = {
    "lldap-env".content = lib.generators.toKeyValue { } {
      LLDAP_JWT_SECRET = config.sops.placeholder."network/lldap/jwt";
      LLDAP_LDAP_USER_PASS = config.sops.placeholder."network/lldap/admin_pass";
      LLDAP_LDAP_BASE_DN = config.sops.placeholder."network/lldap/domain";
      HTTP_PORT = "17170";
      LDAP_PORT = "3890";
    };
  }
  // lib.mapAttrs' (
    name: u:
    lib.nameValuePair "lldap-user-${name}" {
      content = builtins.toJSON {
        id = name;
        email = config.sops.placeholder."network/lldap/users/${name}/email";
        password = config.sops.placeholder."network/lldap/users/${name}/pass";
        displayName = u.displayName or null;
        firstName = u.firstName or null;
        lastName = u.lastName or null;
        groups = u.groups or [ ];
      };
    }
  ) users;

  systemd.services."podman-lldap" = {
    restartTriggers = [
      config.sops.templates."lldap-env".path
    ]
    ++ lib.mapAttrsToList (name: _: config.sops.templates."lldap-user-${name}".path) users;

    postStart = ''
      ADMIN_PASS="$(cat ${config.sops.secrets."network/lldap/admin_pass".path})"

       ${pkgs.podman}/bin/podman exec \
        --env-file ${config.sops.templates."lldap-env".path} \
        -e LLDAP_ADMIN_PASSWORD="$ADMIN_PASS" \
        -e DO_CLEANUP=true \
        lldap /app/bootstrap.sh
    '';
  };
}
