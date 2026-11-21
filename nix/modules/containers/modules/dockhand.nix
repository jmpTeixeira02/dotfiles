{
  flake.modules.nixos.homelab-containers-dockhand =
    { config, lib, ... }:

    {
      systemd.tmpfiles.rules = [
        "d ${config.mySystem.serviceData}/dockhand 0755 homelab homelab -"
      ];

      virtualisation.oci-containers.containers.dockhand = {
        image = "docker.io/fnsys/dockhand:v1.0.58@sha256:515c6e0f28cf3922c51a2dfd3463b972880e40418c2464b1bc91b8a3afe66c7f";
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
