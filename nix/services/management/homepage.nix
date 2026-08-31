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
    };
  };

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
    "homepage-env".content = ''
      HOMEPAGE_ALLOWED_HOSTS=homepage.${config.sops.placeholder."domain"}
    '';

    "homepage-labels".content = ''
      traefik.enable=true
      traefik.http.routers.homepage.entryPoints=websecure
      traefik.http.routers.homepage.rule=Host(`homepage.${config.sops.placeholder."domain"}`)
    '';

    "homepage-services.yml".content = ''
      - Network Stack:
          - Traefik:
              icon: traefik-proxy
              href: https://traefik.${config.sops.placeholder."domain"}.
              description: Traefik
          - DDNS-Updater:
              icon: ddns-updater
              href: https://ddns-updater.${config.sops.placeholder."domain"}.
              description: DDNS-Updater
    '';

    "homepage-settings.yml".content = ''
      title: Homelab Dashboard

      theme: dark
      color: neutral
    '';

    "homepage-bookmarks.yml".content = "";

  };

}
