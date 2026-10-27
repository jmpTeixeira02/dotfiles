{
  flake.modules.nixos.homelab-containers-traefik =
    {
      config,
      lib,
      ...
    }:

    {
      sops = {
        secrets = {
          "email" = {
            sopsFile = ./secrets.yaml;
          };
          "network/desecToken" = {
            sopsFile = ./secrets.yaml;
          };
          "crowdsec/traefik" = {
            sopsFile = ./secrets.yaml;
          };
        };
      };

      systemd.tmpfiles.rules = [
        "d ${config.mySystem.serviceData}/traefik 0755 homelab homelab -"
        "d ${config.mySystem.serviceData}/traefik/certs 0755 homelab homelab -"
        "d ${config.mySystem.serviceData}/traefik/logs 0755 homelab homelab -"
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
          "${config.sops.templates."traefik-dynamic.yml".path}:/etc/traefik/dynamic.yml:ro" # NEW
          "${config.mySystem.serviceData}/traefik:/var/traefik:rw"
          "${config.mySystem.serviceData}/traefik/logs:/var/logs/traefik:rw"
        ];
        environmentFiles = [
          config.sops.templates."traefik-env".path
        ];
        labels = {
          "traefik.enable" = "true";
          "traefik.http.routers.traefik.entryPoints" = "websecure";
          "traefik.http.routers.traefik.rule" = "Host(`traefik.${config.domain}`)";
          "traefik.http.routers.traefik.service" = "api@internal";
        };
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

        "traefik-dynamic.yml".content = lib.generators.toYAML { } {
          http.middlewares = {
            crowdsec.plugin.bouncer = {
              enabled = true;
              crowdsecMode = "live";
              crowdsecLapiScheme = "http";
              crowdsecLapiHost = "crowdsec:8080";
              crowdsecLapiKey = config.sops.placeholder."crowdsec/traefik";
            };
            geoblock.plugin.geoblock = {
              silentStartUp = false;
              allowLocalRequests = true;
              logLocalRequests = false;
              logAllowedRequests = false;
              logApiRequests = true;
              api = "https://get.geojs.io/v1/ip/country/{ip}";
              apiTimeoutMs = 750;
              cacheSize = 15;
              cacheTtlSeconds = 0;
              forceMonthlyUpdate = true;
              blackListMode = false;
              countries = [ "PT" ];
              allowUnknownCountries = false;
              unknownCountryApiResponse = "nil";
              addCountryHeader = false;
              httpStatusCodeDeniedRequest = 403;
            };
          };
        };

        "traefik.yml".content = lib.generators.toYAML { } {
          global = {
            checkNewVersion = false;
            sendAnonymousUsage = false;
          };

          log = {
            level = "INFO";
            filePath = "/var/logs/traefik/traefik.log";
          };

          api = {
            dashboard = true;
          };

          entryPoints = {
            web = {
              address = ":80";
              http = {
                aliasHeadersStrategy = "delete";
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
                aliasHeadersStrategy = "delete";
                tls = {
                  certResolver = "desec";
                  domains = [
                    {
                      main = config.domain;
                      sans = [
                        "*.${config.domain}"
                      ];
                    }
                  ];
                };
                middlewares = [
                  "crowdsec@file"
                  "geoblock@file"
                  "authelia@docker"
                ];
              };
            };
          };

          experimental.plugins = {
            bouncer = {
              moduleName = "github.com/maxlerebourg/crowdsec-bouncer-traefik-plugin";
              version = "v1.7.1";
            };
            geoblock = {
              moduleName = "github.com/PascalMinder/geoblock";
              version = "v0.3.8";
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

          metrics = {
            otlp = {
              addEntryPointsLabels = true;
              addRoutersLabels = true;
              addServicesLabels = true;
              http.endpoint = "http://otel-collector:4318/v1/metrics";
            };
          };

          tracing = {
            otlp.http.endpoint = "http://otel-collector:4318/v1/traces";
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
        after = [
          "podman-authelia.service"
          "podman-crowdsec.service"
        ];
        requires = [
          "podman-authelia.service"
          "podman-crowdsec.service"
        ];
        restartTriggers = [
          config.sops.templates."traefik-env".content
          config.sops.templates."traefik.yml".content
          config.sops.templates."traefik-dynamic.yml".content
        ];
      };

    };
}
