{
  config,
  ...
}:

{
  systemd.tmpfiles.rules = [
    "d ${config.mySystem.serviceData}/navidrome 0755 homelab homelab -"
    "d ${config.mySystem.poolMount}/music 0755 homelab homelab -"
  ];

  virtualisation.oci-containers.containers.navidrome = {
    image = "docker.io/deluan/navidrome:latest";
    autoStart = true;
    volumes = [
      "${config.mySystem.serviceData}/navidrome:/data:rw"
      "${config.mySystem.poolMount}/music:/music:ro"
    ];
    ports = [
      "4533:4533"
    ];
    environment = {
      ND_ENABLEUSEREDITING = "false";
      ND_EXTAUTH_TRUSTEDSOURCES = "0.0.0.0/0";
      ND_REVERSEPROXYUSERHEADER = "Remote-User";
    };
    labels = {
      "traefik.enable" = "true";
      "traefik.http.routers.navidrome.entryPoints" = "websecure";
      "traefik.http.routers.navidrome.rule" = "Host(`navidrome.${config.domain}`)";
      "traefik.http.routers.navidrome.middlewares" = "authelia@docker";

      "traefik.http.routers.navidrome-subsonic.rule" =
        "Host(`navidrome.${config.domain}`) && PathPrefix(`/rest/`) && !Query(`c`, `NavidromeUI`)";
      "traefik.http.routers.navidrome-subsonic.entrypoints" = "websecure";
      "traefik.http.routers.navidrome-subsonic.middlewares" = "authelia@docker";
    };
  };

  systemd.services."podman-navidrome" = {
    after = [ "podman-lldap.service" ];
    requires = [ "podman-lldap.service" ];
  };
}
