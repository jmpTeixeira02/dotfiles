{
  flake.modules.nixos.homelab-containers-dockhand =
    { config, lib, ... }:

    {
      systemd.tmpfiles.rules = [
        "d ${config.mySystem.serviceData}/dockhand 0755 homelab homelab -"
      ];

      virtualisation.oci-containers.containers.dockhand = {
        image = "docker.io/fnsys/dockhand:v1.0.60@sha256:b8aed678af7563680d561db297fe513857c9adc263cc39e373c3434f0d1532e2";
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
