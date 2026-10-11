{
  flake.modules.nixos.containers =
    {
      config,
      lib,
      ...
    }:

    {
      systemd.tmpfiles.rules = [
        "d ${config.mySystem.serviceData}/homepage 0755 homelab homelab -"
      ];

      virtualisation.oci-containers.containers.homepage = {
        image = "ghcr.io/gethomepage/homepage:latest";
        autoStart = true;
        user = "1000:1000";
        volumes = [
          "/var/run/podman/podman.sock:/var/run/docker.sock:ro"
          "${config.sops.templates."homepage-settings.yml".path}:/app/config/settings.yaml:rw"
          "${config.sops.templates."homepage-services.yml".path}:/app/config/services.yaml:rw"
          "${config.sops.templates."homepage-bookmarks.yml".path}:/app/config/bookmarks.yaml:rw"
          "${config.mySystem.serviceData}/homepage:/app/config:rw"
          # "${config.sops.templates."homepage-widgets.yml".path}:/app/config/widgets.yaml:rw"
        ];
        environmentFiles = [
          config.sops.templates."homepage-env".path
        ];
        labels = {
          "traefik.enable" = "true";
          "traefik.http.routers.homepage.entryPoints" = "websecure";
          "traefik.http.routers.homepage.rule" = "Host(`homepage.${config.domain}`)";
        };
      };

      sops.templates = {
        "homepage-env".content = lib.generators.toKeyValue { } {
          HOMEPAGE_ALLOWED_HOSTS = "homepage.${config.domain}";
        };

        "homepage-services.yml" = {
          owner = "homelab";
          content = lib.generators.toYAML { } [
            {
              Applications = [
                {
                  Jellyfin = {
                    icon = "jellyfin";
                    href = "https://jellyfin.${config.domain}";
                    description = "Video Player";
                  };
                }
                {
                  Seerr = {
                    icon = "seerr";
                    href = "https://seerr.${config.domain}";
                    description = "Movie/TV Series Request";
                  };
                }
                {
                  DroppedNeedle = {
                    icon = "droppedneedle";
                    href = "https://droppedneedle.${config.domain}";
                    description = "Music Request";
                  };
                }
                {
                  Navidrome = {
                    icon = "navidrome";
                    href = "https://navidrome.${config.domain}";
                    description = "Music Player";
                  };
                }
                {
                  Papra = {
                    icon = "papra";
                    href = "https://papra.${config.domain}";
                    description = "Document Manager";
                  };
                }
              ];
            }
            {
              Admin = [
                {
                  Management = [
                    {
                      Dockhand = {
                        icon = "dockhand";
                        href = "https://dockhand.${config.domain}";
                        description = "Container Management";
                      };
                    }
                    {
                      Traefik = {
                        icon = "traefik-proxy";
                        href = "https://traefik.${config.domain}";
                        description = "Reverse Proxy";
                      };
                    }
                    {
                      DDNS-Updater = {
                        icon = "ddns-updater";
                        href = "https://ddns-updater.${config.domain}";
                        description = "Domain Name IP Updater";
                      };
                    }
                    {
                      LLDAP = {
                        icon = "lldap";
                        href = "https://lldap.${config.domain}";
                        description = "User Management";
                      };
                    }
                  ];
                }
                {
                  "ARR Stack" = [
                    {
                      Prowlarr = {
                        icon = "prowlarr";
                        href = "https://prowlarr.${config.domain}";
                        description = "Indexer";
                      };
                    }
                    {
                      Sonarr = {
                        icon = "sonarr";
                        href = "https://sonarr.${config.domain}";
                        description = "TV Series Management";
                      };
                    }
                    {
                      Radarr = {
                        icon = "radarr";
                        href = "https://radarr.${config.domain}";
                        description = "Movie Management";
                      };
                    }
                  ];
                }
                {
                  "Download Clients" = [
                    {
                      qBitTorrent = {
                        icon = "qbittorrent";
                        href = "https://torrent.${config.domain}";
                        description = "Torrent Client";
                      };
                    }
                    {
                      Slskd = {
                        icon = "slskd";
                        href = "https://slskd.${config.domain}";
                        description = "Soulseek Client";
                      };
                    }
                  ];
                }
              ];
            }
          ];
        };

        "homepage-settings.yml" = {
          owner = "homelab";
          content = lib.generators.toYAML { } {
            title = "Homelab Dashboard";
            theme = "dark";
            color = "neutral";
            layout = [
              {
                Applications = {
                  style = "row";
                  columns = 4;
                  icon = "mdi-play";
                };
              }
              {
                Admin = {
                  icon = "mdi-settings";
                  style = "row";
                  columns = 3;

                  "ARR Stack" = {
                    style = "column";
                    columns = 1;
                  };

                  "Download Clients" = {
                    style = "column";
                    columns = 1;
                  };

                  Management = {
                    style = "column";
                    columns = 1;
                  };
                };
              }
            ];
          };
        };

        "homepage-bookmarks.yml" = {
          owner = "homelab";
        };

      };

      systemd.services."podman-homepage" = {
        restartTriggers = [
          config.sops.templates."homepage-env".content
          config.sops.templates."homepage-services.yml".content
          config.sops.templates."homepage-settings.yml".content
          config.sops.templates."homepage-bookmarks.yml".content
        ];
      };

    };
}
