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
      "media/lidarr/apiKey" = {
        sopsFile = ../secrets.yaml;
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d ${config.mySystem.poolMount}/lidarr 0755 1000 1000 -"
  ];

  virtualisation.oci-containers.containers.lidarr = {
    image = "lscr.io/linuxserver/lidarr:latest";
    autoStart = true;
    volumes = [
      "${config.sops.templates."lidarr-config.xml".path}:/config/config.xml:rw"
      "${config.mySystem.serviceData}/lidarr:/config:rw,U"
      "${config.mySystem.poolMount}/lidarr:/storage:rw"
      "${config.mySystem.poolMount}/downloads:/downloads:rw"
    ];
    environment = {
      PUID = "1000";
      PGID = "1000";
    };
    ports = [
      "8686:8686"
    ];
    extraOptions = [
      "--label-file=${config.sops.templates."lidarr-labels".path}"
    ];
  };

  sops.templates = {
    "lidarr-labels".content = lib.generators.toKeyValue { } {
      "traefik.enable" = "true";
      "traefik.http.routers.lidarr.entryPoints" = "websecure";
      "traefik.http.routers.lidarr.rule" = "Host(`lidarr.${config.sops.placeholder."domain"}`)";
    };

    "lidarr-config.xml".content = ''
      <Config>
        <BindAddress>*</BindAddress>
        <Port>8686</Port>
        <SslPort>6868</SslPort>
        <EnableSsl>False</EnableSsl>
        <LaunchBrowser>True</LaunchBrowser>
        <ApiKey>${config.sops.placeholder."media/lidarr/apiKey"}</ApiKey>
        <AuthenticationMethod>External</AuthenticationMethod>
        <AuthenticationRequired>DisabledForLocalAddresses</AuthenticationRequired>
        <Branch>master</Branch>
        <LogLevel>debug</LogLevel>
        <SslCertPath></SslCertPath>
        <SslCertPassword></SslCertPassword>
        <UrlBase></UrlBase>
        <InstanceName>Lidarr</InstanceName>
        <UpdateMechanism>Docker</UpdateMechanism>
      </Config>

    '';
  };

  systemd.services."podman-lidarr" = {
    restartTriggers = [
      config.sops.templates."lidarr-labels".content
      config.sops.templates."lidarr-config.xml".content
    ];
    path = with pkgs; [
      curl
      jq
      coreutils
      gnugrep
    ];

    postStart = ''
      set -euo pipefail

      API_KEY=$(cat ${config.sops.secrets."media/lidarr/apiKey".path})
      URL="http://localhost:8686/api/v1"

      echo "Waiting for Lidarr API to become ready..."
      until curl -s -f -H "X-Api-Key: $API_KEY" "$URL/system/status" > /dev/null; do
        sleep 3
      done

      echo "API is up. Checking root folders..."
      EXISTING_FOLDERS=$(curl -s -H "X-Api-Key: $API_KEY" "$URL/rootfolder" | jq -r '.[].path')

      if ! echo "$EXISTING_FOLDERS" | grep -q "^/storage$"; then
        echo "Adding root folder: /storage"
        
        # Fetch default quality and metadata profile IDs automatically
        QUALITY_PROFILE_ID=$(curl -s -H "X-Api-Key: $API_KEY" "$URL/qualityprofile" | jq '.[0].id')
        METADATA_PROFILE_ID=$(curl -s -H "X-Api-Key: $API_KEY" "$URL/metadataprofile" | jq '.[0].id')

        PAYLOAD=$(jq -n \
          --arg path "/storage" \
          --arg name "Storage" \
          --argjson qId "$QUALITY_PROFILE_ID" \
          --argjson mId "$METADATA_PROFILE_ID" \
          '{path: $path, name: $name, defaultQualityProfileId: $qId, defaultMetadataProfileId: $mId}')

        curl -s -o /dev/null -X POST "$URL/rootfolder" \
          -H "X-Api-Key: $API_KEY" \
          -H "Content-Type: application/json" \
          -d "$PAYLOAD"
      fi

      echo "Checking download clients..."
      EXISTING_CLIENTS=$(curl -s -H "X-Api-Key: $API_KEY" "$URL/downloadclient" | jq -r '.[].name')

      if ! echo "$EXISTING_CLIENTS" | grep -q "^qBittorrent$"; then
        echo "Adding download client: qBittorrent"
        PAYLOAD=$(jq -n '{
          enable: true,
          protocol: "torrent",
          priority: 1,
          name: "qBittorrent",
          implementation: "QBittorrent",
          implementationName: "qBittorrent",
          configContract: "QBittorrentSettings",
          fields: [
            {name: "host", value: "torrent"},
            {name: "port", value: 8086},
            {name: "username", value: ""},
            {name: "password", value: ""},
            {name: "category", value: "lidarr"},
            {name: "useSsl", value: false}
          ]
        }')

        curl -s -o /dev/null -X POST "$URL/downloadclient" \
          -H "X-Api-Key: $API_KEY" \
          -H "Content-Type: application/json" \
          -d "$PAYLOAD"
      fi
    '';
  };
}
