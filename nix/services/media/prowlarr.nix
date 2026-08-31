{
  config,
  pkgs,
  lib,
  ...
}:

let
  desiredProviders = [
    "Nyaa.si"
    "LimeTorrents"
    "The Pirate Bay"
  ];
in
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
    path = with pkgs; [
      curl
      jq
      coreutils
      gnugrep
    ];

    postStart = ''
      set -euo pipefail

      API_KEY=$(cat ${config.sops.secrets."media/prowlarr/apiKey".path})
      URL="http://localhost:9696/api/v1/indexer"

      echo "Waiting for Prowlarr API to become ready..."
      # Keep trying until we get a 200/401 response from the API
      until curl -s -f -H "X-Api-Key: $API_KEY" "$URL" > /dev/null; do
        sleep 3
      done

      echo "API is up. Fetching state..."
      EXISTING=$(curl -s -H "X-Api-Key: $API_KEY" "$URL" | jq -r '.[].name')
      SCHEMAS=$(curl -s -H "X-Api-Key: $API_KEY" "$URL/schema")

      PROVIDERS=(${lib.concatStringsSep " " (map (p: ''"${p}"'') desiredProviders)})

      for PROVIDER in "''${PROVIDERS[@]}"; do
        if ! echo "$EXISTING" | grep -q "^''${PROVIDER}$"; then
          echo "Adding provider: $PROVIDER"
          PAYLOAD=$(echo "$SCHEMAS" | jq -c ".[] | select(.name == \"$PROVIDER\") | .enable = true | .appProfileId = 1")
          
          curl -s -o /dev/null -X POST "$URL" \
            -H "X-Api-Key: $API_KEY" \
            -H "Content-Type: application/json" \
            -d "$PAYLOAD"
        fi
      done
    '';
  };
}
