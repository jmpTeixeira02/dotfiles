{
  flake.modules.nixos.homelab-containers-seerr =
    {
      pkgs,
      config,
      lib,
      ...
    }:

    {
      systemd.tmpfiles.rules = [
        "d ${config.mySystem.serviceData}/seerr 0755 homelab homelab -"
      ];

      virtualisation.oci-containers.containers.seerr = {
        image = "ghcr.io/seerr-team/seerr:v3.5.1@sha256:d8fab675b55ad293ded98fd71efcfd46054cbad9746534ae1cc4794a88c0b3be";
        autoStart = true;
        volumes = [
          "${config.mySystem.serviceData}/seerr:/app/config:rw,U"
        ];
        ports = [
          "5055:5055"
        ];
        labels = {
          "traefik.enable" = "true";
          "traefik.http.routers.seerr.entryPoints" = "websecure";
          "traefik.http.routers.seerr.rule" = "Host(`seerr.${config.domain}`)";
        };
      };

      systemd.services."podman-seerr" = {
        after = [
          "podman-sonarr.service"
          "podman-radarr.service"
          "podman-jellyfin.service"
        ];
        requires = [
          "podman-sonarr.service"
          "podman-radarr.service"
          "podman-jellyfin.service"
        ];
      };
    };
}
