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
      "network/authelia/jwt" = {
        sopsFile = ../secrets.yaml;
      };
      "network/authelia/session" = {
        sopsFile = ../secrets.yaml;
      };
      "network/authelia/storage_key" = {
        sopsFile = ../secrets.yaml;
      };
      "network/lldap/admin_pass" = {
        sopsFile = ../secrets.yaml;
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d ${config.mySystem.serviceData}/authelia 0755 1000 1000 -"
  ];

  virtualisation.oci-containers.containers.authelia = {
    image = "docker.io/authelia/authelia";
    autoStart = true;
    volumes = [
      "${config.sops.templates."authelia.yml".path}:/config/configuration.yml:rw,U"
      "${config.mySystem.serviceData}/authelia:/config:rw"
    ];
    environmentFiles = [
      config.sops.templates."authelia-env".path
    ];
    extraOptions = [
      "--label-file=${config.sops.templates."authelia-labels".path}"
    ];
  };

  sops.templates = {
    "authelia-env".content = lib.generators.toKeyValue { } {
      PUID = "1000";
      PGID = "1000";
      AUTHELIA_JWT_SECRET = config.sops.placeholder."network/authelia/jwt";
      AUTHELIA_SESSION_SECRET = config.sops.placeholder."network/authelia/session";
      AUTHELIA_STORAGE_ENCRYPTION_KEY = config.sops.placeholder."network/authelia/storage_key";
      AUTHELIA_AUTHENTICATION_BACKEND_LDAP_PASSWORD = config.sops.placeholder."network/lldap/admin_pass";
    };

    "authelia-labels".content = lib.generators.toKeyValue { } {
      "traefik.enable" = "true";
      "traefik.http.routers.authelia.entryPoints" = "websecure";
      "traefik.http.routers.authelia.rule" = "Host(`auth.${config.sops.placeholder."domain"}`)";

      "traefik.http.middlewares.authelia.forwardAuth.address" =
        "http://authelia:9091/api/authz/forward-auth";
      "traefik.http.middlewares.authelia.forwardAuth.trustForwardHeader" = "true";
      "traefik.http.middlewares.authelia.forwardAuth.authResponseHeaders" =
        "Remote-User,Remote-Groups,Remote-Email,Remote-Name";
    };

    "authelia.yml".content = lib.generators.toYAML { } {
      theme = "dark";

      server = {
        address = "tcp://0.0.0.0:9091";
      };

      log = {
        level = "info";
      };

      authentication_backend = {
        ldap = {
          implementation = "lldap";
          address = "ldap://lldap:3890";
          base_dn = config.sops.placeholder."network/lldap/domain";
          user = "uid=admin,ou=people,${config.sops.placeholder."network/lldap/domain"}";
          password = "$AUTHELIA_AUTHENTICATION_BACKEND_LDAP_PASSWORD";
        };
      };

      session = {
        cookies = [
          {
            domain = config.sops.placeholder."domain";
            authelia_url = "https://auth.${config.sops.placeholder."domain"}";
            default_redirection_url = "https://homepage.${config.sops.placeholder."domain"}";
            expiration = "1h";
            inactivity = "5m";
          }
        ];
      };

      storage = {
        local = {
          path = "/config/db.sqlite3";
        };
      };

      notifier = {
        filesystem = {
          filename = "/config/notifications.txt";
        };
      };

      access_control = {
        default_policy = "deny";
        rules = [
          {
            domain = "auth.${config.sops.placeholder."domain"}";
            policy = "bypass";
          }
          {
            domain = "*.${config.sops.placeholder."domain"}";
            policy = "one_factor";
          }
        ];
      };
    };
  };

  systemd.services."podman-authelia" = {
    after = [ "podman-lldap.service" ];
    requires = [ "podman-lldap.service" ];

    restartTriggers = [
      config.sops.templates."authelia-env".path
      config.sops.templates."authelia-labels".path
      config.sops.templates."authelia.yml".path
    ];
  };
}
