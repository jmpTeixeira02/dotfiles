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
      "media/prowlarr/apiKey" = {
        sopsFile = ../secrets.yaml;
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d ${config.mySystem.serviceData}/prowlarr 0755 root root -"
  ];

  virtualisation.oci-containers.containers.prowlarr = {
    image = "lscr.io/linuxserver/prowlarr:latest";
    autoStart = true;
    volumes = [
      "${config.sops.templates."prowlarr-config.xml".path}:/config/config.xml:rw,U"
      "${config.mySystem.serviceData}/prowlarr:/config:rw,U"
    ];
    environment = {
      PUID = "1000";
      PGID = "1000";
    };
    ports = [
      "9696:9696"
    ];
    extraOptions = [
      "--label-file=${config.sops.templates."prowlarr-labels".path}"
    ];
  };

  sops.templates = {
    "prowlarr-labels".content = lib.generators.toKeyValue { } {
      "traefik.enable" = "true";
      "traefik.http.routers.prowlarr.entryPoints" = "websecure";
      "traefik.http.routers.prowlarr.rule" = "Host(`prowlarr.${config.sops.placeholder."domain"}`)";
    };

    "prowlarr-config.xml".content = ''
      <Config>
        <BindAddress>*</BindAddress>
        <Port>9696</Port>
        <SslPort>6969</SslPort>
        <EnableSsl>False</EnableSsl>
        <LaunchBrowser>True</LaunchBrowser>
        <ApiKey>${config.sops.placeholder."media/prowlarr/apiKey"}</ApiKey>
        <AuthenticationMethod>External</AuthenticationMethod>
        <AuthenticationRequired>DisabledForLocalAddresses</AuthenticationRequired>
        <Branch>master</Branch>
        <LogLevel>debug</LogLevel>
        <SslCertPath></SslCertPath>
        <SslCertPassword></SslCertPassword>
        <UrlBase></UrlBase>
        <InstanceName>Prowlarr</InstanceName>
        <UpdateMechanism>Docker</UpdateMechanism>
      </Config>
    '';
  };

  systemd.services."podman-prowlarr" = {
    restartTriggers = [
      config.sops.templates."prowlarr-labels".content
      config.sops.templates."prowlarr-config.xml".content
    ];
  };
}
