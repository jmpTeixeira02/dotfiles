{
  config,
  lib,
  ...
}:

{
  sops.secrets."domain".sopsFile = ../secrets.yaml;

  systemd.tmpfiles.rules = [
    "d ${config.mySystem.poolMount}/downloads 0755 1000 1000 -"
  ];

  virtualisation.oci-containers.containers.torrent = {
    image = "lscr.io/linuxserver/qbittorrent:latest";
    autoStart = true;
    volumes = [
      "${config.sops.templates."torrent.conf".path}:/config/qBittorrent/qBittorrent.conf:rw,U"
      "${config.mySystem.poolMount}/downloads:/downloads:rw,U"
    ];
    ports = [
      "6881:6881"
    ];
    environment = {
      PUID = "1000";
      PGID = "1000";
      WEBUI_PORT = "8086";
      TORRENTING_PORT = "6881";
    };
    extraOptions = [
      "--label-file=${config.sops.templates."torrent-labels".path}"
    ];
  };

  sops.templates = {
    "torrent-labels".content = lib.generators.toKeyValue { } {
      "traefik.enable" = "true";
      "traefik.http.routers.torrent.entryPoints" = "websecure";
      "traefik.http.routers.torrent.rule" = "Host(`torrent.${config.sops.placeholder."domain"}`)";
      "traefik.http.services.torrent.loadbalancer.server.port" = 8086;
    };

    "torrent.conf".content = ''
      [Preferences]
      WebUI\Address=*
      WebUI\ReverseProxySupportEnabled=true
      WebUI\TrustedReverseProxiesList=10.88.0.0/16, 10.89.0.0/16
      WebUI\AuthSubnetWhitelist=192.168.1.0/24, 172.19.0.0/16, 10.88.0.0/16, 10.89.0.0/16
      WebUI\AuthSubnetWhitelistEnabled=true
      WebUI\LocalHostAuth=false
    '';
  };

  systemd.services."podman-torrent" = {
    restartTriggers = [
      config.sops.templates."torrent-labels".content
      config.sops.templates."torrent.conf".content
    ];
  };

}
