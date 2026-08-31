# dockhand.nix
{ config, lib, ... }:

{
  sops.secrets."domain".sopsFile = ../secrets.yaml;
  systemd.tmpfiles.rules = [
    "d ${config.mySystem.serviceData}/dockhand 0755 root root -"
  ];

  virtualisation.oci-containers.containers.dockhand = {
    image = "docker.io/fnsys/dockhand:latest";
    autoStart = true;
    volumes = [
      "/var/run/podman/podman.sock:/var/run/docker.sock:ro"
      "${config.mySystem.serviceData}/dockhand:/app/data:rw,U"
    ];
    extraOptions = [
      "--label-file=${config.sops.templates."dockhand-labels".path}"
    ];
  };

  sops.templates = {
    "dockhand-labels".content = lib.generators.toKeyValue { } {
      "traefik.enable" = "true";
      "traefik.http.routers.dockhand.entryPoints" = "websecure";
      "traefik.http.routers.dockhand.rule" = "Host(`dockhand.${config.sops.placeholder."domain"}`)";
    };

  };
}
