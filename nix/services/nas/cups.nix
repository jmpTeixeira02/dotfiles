{
  config,
  lib,
  ...
}:

{
  systemd.tmpfiles.rules = [
    "d ${config.mySystem.serviceData}/cups 0755 homelab homelab -"
  ];

  services.avahi = {
    enable = true;
    reflector = true;
    allowInterfaces = [
      "eth0"
      "podman0"
    ];
  };

  virtualisation.oci-containers.containers.cups = {
    image = "docker.io/anujdatar/cups:latest";
    autoStart = true;
    volumes = [
      "/var/run/dbus:/var/run/dbus"
      "${config.mySystem.serviceData}/cups:/etc/cups:rw"
      "${config.sops.templates."cups-conf".path}:/etc/cups/cupsd.conf:rw"
    ];
    labels = {
      "traefik.enable" = "true";
      "traefik.http.routers.cups.entryPoints" = "websecure";
      "traefik.http.routers.cups.rule" = "Host(`cups.${config.domain}`)";
    };
  };

  sops.templates = {
    "cups-conf".content = ''
      DefaultAuthType None
      ServerAlias *
      Listen *:631
      WebInterface Yes
      Browsing Yes
      BrowseLocalProtocols dnssd
      BrowseAllow 192.168.1.0/24

      <Location />
        Order allow,deny
        Allow all
      </Location>

      <Location /admin>
        AuthType None
        Order allow,deny
        Allow all
      </Location>

      <Location /admin/conf>
        AuthType None
        Order allow,deny
        Allow all
      </Location>
    '';
  };

  systemd.services."podman-cups" = {
    restartTriggers = [
      config.sops.templates."cups-conf".content
    ];
  };
}
