{
  flake.modules.nixos.homelab-containers-dockhand =
    { config, lib, ... }:

    {
      systemd.tmpfiles.rules = [
        "d ${config.mySystem.serviceData}/dockhand 0755 homelab homelab -"
      ];

      virtualisation.oci-containers.containers.dockhand = {
        image = "docker.io/fnsys/dockhand@sha256:332eef2f7dacdb4429e22bbb70723eb0b6f5686bbbc86ecdef4b10edb6d87c6c";
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
