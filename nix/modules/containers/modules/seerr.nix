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
        image = "ghcr.io/seerr-team/seerr:v3.5.2@sha256:aadee014b40e28cf9aa4928bc9d1183a6eb08f8c44d543cddc9efdcb16549be2";
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
