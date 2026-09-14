{
  config,
  lib,
  ...
}:

{
  sops.secrets."domain".sopsFile = ../secrets.yaml;

  virtualisation.oci-containers.containers.homepage = {
    image = "ghcr.io/gethomepage/homepage:v1.11";
    autoStart = true;
    volumes = [
      "/var/run/podman/podman.sock:/var/run/docker.sock:ro"
      "${config.sops.templates."homepage-services.yml".path}:/app/config/services.yaml:ro"
      "${config.sops.templates."homepage-settings.yml".path}:/app/config/settings.yaml:ro"
      "${config.sops.templates."homepage-bookmarks.yml".path}:/app/config/bookmarks.yaml:ro"
      # "${config.sops.templates."homepage-widgets.yml".path}:/app/config/widgets.yaml:ro"
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
      HOMEPAGE_ALLOWED_HOSTS = "homepage.${config.sops.placeholder."domain"}";
    };

    "homepage-labels".content = lib.generators.toKeyValue { } {
      "traefik.enable" = "true";
      "traefik.http.routers.homepage.entryPoints" = "websecure";
      "traefik.http.routers.homepage.rule" = "Host(`homepage.${config.sops.placeholder."domain"}`)";
    };

    "homepage-services.yml".content = lib.generators.toYAML { } [
      {
        "Media" = [
          {
            Navidrome = {
              icon = "navidrome";
              href = "https://navidrome.${config.sops.placeholder."domain"}";
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
                  href = "https://dockhand.${config.sops.placeholder."domain"}";
                  description = "Container Management";
                };
              }
              {
                Traefik = {
                  icon = "traefik-proxy";
                  href = "https://traefik.${config.sops.placeholder."domain"}";
                  description = "Reverse Proxy";
                };
              }
              {
                DDNS-Updater = {
                  icon = "ddns-updater";
                  href = "https://ddns-updater.${config.sops.placeholder."domain"}";
                  description = "Domain Name IP Updater";
                };
              }
              {
                LLDAP = {
                  icon = "lldap";
                  href = "https://lldap.${config.sops.placeholder."domain"}";
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
                  href = "https://prowlarr.${config.sops.placeholder."domain"}";
                  description = "Indexer";
                };
              }
              {
                Lidarr = {
                  icon = "lidarr";
                  href = "https://lidarr.${config.sops.placeholder."domain"}";
                  description = "Music Management";
                };
              }
              {
                Sonarr = {
                  icon = "sonarr";
                  href = "https://sonarr.${config.sops.placeholder."domain"}";
                  description = "TV Series Management";
                };
              }
              {
                Radarr = {
                  icon = "radarr";
                  href = "https://radarr.${config.sops.placeholder."domain"}";
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
                  href = "https://torrent.${config.sops.placeholder."domain"}";
                  description = "Torrent Client";
                };
              }
              {
                Slskd = {
                  icon = "slskd";
                  href = "https://slskd.${config.sops.placeholder."domain"}";
                  description = "Soulseek Client";
                };
              }
            ];
          }
        ];
      }
    ];

    "homepage-settings.yml".content = lib.generators.toYAML { } {
      title = "Homelab Dashboard";
      theme = "dark";
      color = "neutral";
      layout = [
        {
          "Admin" = {
            style = "row";
          };
        }
        {
          "Media" = {
            style = "row";
          };
        }
      ];
    };

    "homepage-bookmarks.yml".content = lib.generators.toYAML { } { };

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
