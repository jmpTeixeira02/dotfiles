{
  flake.modules.nixos.homelab-containers-dockhand =
    { config, lib, ... }:

    {
      systemd.tmpfiles.rules = [
        "d ${config.mySystem.serviceData}/dockhand 0755 homelab homelab -"
      ];

      virtualisation.oci-containers.containers.dockhand = {
        image = "docker.io/fnsys/dockhand:v1.0.57@sha256:4fd64d32728c99e5caf39b952a17d85448ee0b8ae76e0961f719ba2e19013988";
        autoStart = true;
        volumes = [
          "/var/run/podman/podman.sock:/var/run/docker.sock:ro"
          "${config.mySystem.serviceData}/dockhand:/app/data:rw,U"
        ];
        labels = {
          "traefik.enable" = "true";
          "traefik.http.routers.dockhand.entryPoints" = "websecure";
          "traefik.http.routers.dockhand.rule" = "Host(`dockhand.${config.domain}`)";
        };
      };
    };
}
