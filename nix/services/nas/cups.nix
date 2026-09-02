{
  config,
  lib,
  ...
}:

{
  sops = {
    secrets = {
      "domain" = {
        sopsFile = ../secrets.yaml;
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d ${config.mySystem.serviceData}/cups 0755 1000 1000 -"
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
    extraOptions = [
      "--label-file=${config.sops.templates."cups-labels".path}"
    ];
  };

  sops.templates = {
    "cups-labels".content = lib.generators.toKeyValue { } {
      "traefik.enable" = "true";
      "traefik.http.routers.cups.entryPoints" = "websecure";
      "traefik.http.routers.cups.rule" = "Host(`cups.${config.sops.placeholder."domain"}`)";
    };

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
      config.sops.templates."cups-labels".content
      config.sops.templates."cups-conf".content
    ];
  };
}
