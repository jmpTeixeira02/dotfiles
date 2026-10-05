{ config, lib, ... }:

{
  systemd.tmpfiles.rules = [
    "d ${config.mySystem.serviceData}/dockhand 0755 homelab homelab -"
  ];

  virtualisation.oci-containers.containers.dockhand = {
    image = "docker.io/fnsys/dockhand:latest";
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
}
