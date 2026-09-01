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
      "email" = {
        sopsFile = ../secrets.yaml;
      };
      "network/desecToken" = {
        sopsFile = ../secrets.yaml;
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d ${config.mySystem.serviceData}/traefik/certs 0755 1000 1000 -"
  ];

  virtualisation.oci-containers.containers.traefik = {
    image = "docker.io/traefik:latest";
    autoStart = true;
    ports = [
      "80:80"
      "443:443"
    ];
    volumes = [
      "/var/run/podman/podman.sock:/var/run/docker.sock:ro"
      "${config.sops.templates."traefik.yml".path}:/etc/traefik/traefik.yml:ro"
      "${config.mySystem.serviceData}/traefik/certs:/var/traefik/certs:rw,U"
    ];
    environmentFiles = [
      config.sops.templates."traefik-env".path
    ];
    extraOptions = [
      "--label-file=${config.sops.templates."traefik-labels".path}"
    ];
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  sops.templates = {
    "traefik-env".content = lib.generators.toKeyValue { } {
      DESEC_TOKEN = config.sops.placeholder."network/desecToken";
      DESEC_POLLING_INTERVAL = "75";
      DESEC_PROPAGATION_TIMEOUT = "300";
    };

    "traefik-labels".content = lib.generators.toKeyValue { } {
      "traefik.enable" = "true";
      "traefik.http.routers.traefik.entryPoints" = "websecure";
      "traefik.http.routers.traefik.rule" = "Host(`traefik.${config.sops.placeholder."domain"}`)";
      "traefik.http.routers.traefik.service" = "api@internal";
    };

    "traefik.yml".content = lib.generators.toYAML { } {
      global = {
        checkNewVersion = false;
        sendAnonymousUsage = false;
      };

      log = {
        level = "DEBUG";
      };

      api = {
        dashboard = true;
        insecure = true;
      };

      entryPoints = {
        web = {
          address = ":80";
          http = {
            redirections = {
              entryPoint = {
                to = "websecure";
                scheme = "https";
              };
            };
          };
        };
        websecure = {
          address = ":443";
          http = {
            tls = {
              certResolver = "desec";
              domains = [
                {
                  main = config.sops.placeholder."domain";
                  sans = [
                    "*.${config.sops.placeholder."domain"}"
                  ];
                }
              ];
            };
            middlewares = [
              "authelia@docker"
            ];
          };
        };
      };

      providers = {
        docker = {
          endpoint = "unix:///var/run/docker.sock";
          exposedByDefault = false;
        };
        file = {
          filename = "/etc/traefik/dynamic.yml";
        };
      };

      certificatesResolvers = {
        desec = {
          acme = {
            email = config.sops.placeholder."email";
            storage = "/var/traefik/certs/desec.json";
            caServer = "https://acme-v02.api.letsencrypt.org/directory";
            # caServer = "https://acme-staging-v02.api.letsencrypt.org/directory"; # Staging
            dnsChallenge = {
              provider = "desec";
              resolvers = [
                "ns1.desec.io:53"
                "ns2.desec.org:53"
              ];
            };
          };
        };
      };
    };
  };

  systemd.services."podman-traefik" = {
    restartTriggers = [
      config.sops.templates."traefik-env".content
      config.sops.templates."traefik-labels".content
      config.sops.templates."traefik.yml".content
    ];
  };

}
