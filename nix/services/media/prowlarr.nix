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
      "media/lidarr/apiKey" = {
        sopsFile = ../secrets.yaml;
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d ${config.mySystem.serviceData}/prowlarr 0755 1000 1000 -"
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
      INDEXER_URL="http://localhost:9696/api/v1/indexer"

      echo "Waiting for Prowlarr API to become ready..."
      until curl -s -f -H "X-Api-Key: $API_KEY" "$INDEXER_URL" > /dev/null; do
        sleep 3
      done

      EXISTING=$(curl -s -H "X-Api-Key: $API_KEY" "$INDEXER_URL" | jq -r '.[].name')
      SCHEMAS=$(curl -s -H "X-Api-Key: $API_KEY" "$INDEXER_URL/schema")
      PROVIDERS=(${lib.concatStringsSep " " (map (p: ''"${p}"'') desiredProviders)})

      for PROVIDER in "''${PROVIDERS[@]}"; do
      if ! echo "$EXISTING" | grep -q "^''${PROVIDER}$"; then
          echo "Adding provider: $PROVIDER"
          PAYLOAD=$(echo "$SCHEMAS" | jq -c ".[] | select(.name == \"$PROVIDER\") | .enable = true | .appProfileId = 1")
          
          curl -s -o /dev/null -X POST "$INDEXER_URL" \
          -H "X-Api-Key: $API_KEY" \
          -H "Content-Type: application/json" \
          -d "$PAYLOAD"
      fi
      done

      echo "Checking Prowlarr application sync for Lidarr..."

      APPLICATIONS_URL="http://localhost:9696/api/v1/applications"
      APPS=$(curl -sS -H "X-Api-Key: $API_KEY" "$APPLICATIONS_URL")

      LIDARR_EXISTS=$(echo "$APPS" | jq -r '[.[] | select(.name == "Lidarr")] | length')

        if [ "$LIDARR_EXISTS" -eq 0 ]; then
            echo "Adding Lidarr to Prowlarr applications..."

            LIDARR_API_KEY=$(cat ${config.sops.secrets."media/lidarr/apiKey".path})

            LIDARR_PAYLOAD=$(jq -n --arg apiKey "$LIDARR_API_KEY" \
            '{
                name: "Lidarr",
                syncLevel: "addOnly",
                implementation: "Lidarr",
                implementationName: "Lidarr",
                configContract: "LidarrSettings",
                fields: [
                    { name: "prowlarrUrl", value: "http://prowlarr:9696" },
                    { name: "baseUrl", value: "http://lidarr:8686" },
                    { name: "apiKey", value: $apiKey }
                ],
                tags: []
            }')

            curl -sS -f -X POST "$APPLICATIONS_URL" \
            -H "X-Api-Key: $API_KEY" \
            -H "Content-Type: application/json" \
            -d "$LIDARR_PAYLOAD"
        fi

    '';
  };
}
