{
  config,
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
      "users" = {
        format = "yaml";
        sopsFile = ./secrets.yaml;
        key = ""; # Leaves key empty to use the whole file
      };
    };
  };

  virtualisation.oci-containers.containers.authelia = {
    image = "docker.io/authelia/authelia";
    autoStart = true;
    volumes = [
      "${config.sops.templates."authelia.yml".path}:/config/configuration.yml:ro"
      "${config.sops.secrets."users".path}:/config/users.yml:ro"
    ];
    environmentFiles = [
      config.sops.templates."authelia-env".path
    ];
    extraOptions = [
      "--label-file=${config.sops.templates."authelia-labels".path}"
    ];
  };

  sops.templates = {
    "authelia-env".content = ''
      TZ = "Europe/Lisbon"
      PUID = 1000
      PGID = 1000
      AUTHELIA_JWT_SECRET=${config.sops.placeholder."network/authelia/jwt"}
      AUTHELIA_SESSION_SECRET=${config.sops.placeholder."network/authelia/session"}
      AUTHELIA_STORAGE_ENCRYPTION_KEY=${config.sops.placeholder."network/authelia/storage_key"}
    '';

    "authelia-labels".content = ''
      traefik.enable=true
      traefik.http.routers.authelia.entryPoints=websecure
      traefik.http.routers.authelia.rule=Host(`auth.${config.sops.placeholder."domain"}`)

      traefik.http.middlewares.authelia.forwardAuth.address=http://authelia:9091/api/authz/forward-auth
      traefik.http.middlewares.authelia.forwardAuth.trustForwardHeader=true
      traefik.http.middlewares.authelia.forwardAuth.authResponseHeaders=Remote-User,Remote-Groups,Remote-Email,Remote-Name
    '';

    "authelia.yml".content = ''
      theme: dark

      server:
        address: tcp://0.0.0.0:9091

      log:
        level: info

      authentication_backend:
        file:
          path: /config/users.yml
          password:
            algorithm: argon2id

      session:
        cookies:
          - domain: ${config.sops.placeholder."domain"}
            authelia_url: https://auth.${config.sops.placeholder."domain"}
            default_redirection_url: https://homepage.${config.sops.placeholder."domain"}
            expiration: 1h
            inactivity: 5m

      storage:
        local:
          path: /config/db.sqlite3

      notifier:
        filesystem:
          filename: /config/notifications.txt

      access_control:
        default_policy: deny
        rules:
          - domain: auth.${config.sops.placeholder."domain"}
            policy: bypass
          - domain: "*.${config.sops.placeholder."domain"}"
            policy: one_factor
    '';

  };

}
