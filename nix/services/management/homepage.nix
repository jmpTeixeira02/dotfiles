{
  config,
  lib,
  ...
}:

{
  systemd.tmpfiles.rules = [
    "d ${config.mySystem.serviceData}/homepage 0755 1000 1000 -"
  ];

  virtualisation.oci-containers.containers.homepage = {
    image = "ghcr.io/gethomepage/homepage:latest";
    autoStart = true;
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
    extraOptions = [
      "--label-file=${config.sops.templates."homepage-labels".path}"
    ];
  };

  sops.templates = {
    "homepage-env".content = lib.generators.toKeyValue { } {
      HOMEPAGE_ALLOWED_HOSTS = "homepage.${config.domain}";
      PUID = "1000";
      PGID = "1000";
    };

    "homepage-labels".content = lib.generators.toKeyValue { } {
      "traefik.enable" = "true";
      "traefik.http.routers.homepage.entryPoints" = "websecure";
      "traefik.http.routers.homepage.rule" = "Host(`homepage.${config.domain}`)";
    };

    "homepage-services.yml" = {
      owner = "homelab";
      content = lib.generators.toYAML { } [
        {
          "Media" = [
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
              Navidrome = {
                icon = "navidrome";
                href = "https://navidrome.${config.domain}";
                description = "Music Player";
              };
            }
          ];
        }
        {
          "Admin" = [
            {
              "Management" = [
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
                  Lidarr = {
                    icon = "lidarr";
                    href = "https://lidarr.${config.domain}";
                    description = "Music Management";
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
            Media = {
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
      config.sops.templates."homepage-labels".content
      config.sops.templates."homepage-services.yml".content
      config.sops.templates."homepage-settings.yml".content
      config.sops.templates."homepage-bookmarks.yml".content
    ];
  };

}
