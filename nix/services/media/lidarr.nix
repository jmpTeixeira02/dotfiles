{
  config,
  pkgs,
  lib,
  ...
}:

{
  sops = {
    secrets = {
      "domain" = {
        sopsFile = ../secrets.yaml;
      };
      "media/lidarr/apiKey" = {
        sopsFile = ../secrets.yaml;
      };
      "media/slskd/apiKey" = {
        sopsFile = ../secrets.yaml;
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d ${config.mySystem.poolMount}/music 0755 1000 1000 -"
    "d ${config.mySystem.poolMount}/downloads 0755 1000 1000 -"
    "d ${config.mySystem.serviceData}/lidarr 0755 1000 1000 -"
  ];

  virtualisation.oci-containers.containers.lidarr = {
    image = "lscr.io/linuxserver/lidarr:nightly";
    autoStart = true;
    volumes = [
      "${config.sops.templates."lidarr-config.xml".path}:/config/config.xml:rw"
      "${config.mySystem.serviceData}/lidarr:/config:rw,U"
      "${config.mySystem.poolMount}/music:/storage:rw"
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
      unzip
    ];

    preStart = ''
      set -euo pipefail

      PLUGIN_DIR="${config.mySystem.serviceData}/lidarr/plugins/TypNull/Tubifarry"

      if [ ! -d "$PLUGIN_DIR" ]; then
        echo "Downloading latest Slskd plugin..."
        mkdir -p "$PLUGIN_DIR"

        DOWNLOAD_URL=$(curl -s https://api.github.com/repos/TypNull/Tubifarry/releases/latest \
      |   jq -r '.assets[] | select(.name | test("net8\\.0\\.zip$")) | .browser_download_url')

        if [ -z "$DOWNLOAD_URL" ] || [ "$DOWNLOAD_URL" = "null" ]; then
          echo "ERROR: Could not find Slskd plugin release asset"
          exit 1
        fi

        curl -L -o /tmp/tubifarry-plugin.zip "$DOWNLOAD_URL"
        unzip -o /tmp/tubifarry-plugin.zip -d "$PLUGIN_DIR"
        rm -f /tmp/tubifarry-plugin.zip
        chown -R 1000:1000 "${config.mySystem.serviceData}/lidarr/plugins"
        echo "Tubifarry plugin installed."
      fi
    '';

    postStart = ''
      set -euo pipefail

      API_KEY=$(cat ${config.sops.secrets."media/lidarr/apiKey".path})
      SLSKD_API_KEY=$(cat ${config.sops.secrets."media/slskd/apiKey".path})
      URL="http://localhost:8686/api/v1"

      api_get()  { curl -s -H "X-Api-Key: $API_KEY" "$URL$1"; }
      api_post() { curl -s -o /dev/null -X POST -H "X-Api-Key: $API_KEY" \
                     -H "Content-Type: application/json" -d "$2" "$URL$1"; }
      api_put() { curl -s -o /dev/null -X PUT -H "X-Api-Key: $API_KEY" \
                     -H "Content-Type: application/json" -d "$2" "$URL$1"; }

      wait_for_lidarr() {
        echo "Waiting for Lidarr API to become ready..."
        until curl -s -f -H "X-Api-Key: $API_KEY" "$URL/system/status" > /dev/null; do
          sleep 3
        done
      }

      # Usage: has_name <endpoint> <name>  -> exit 0 if a resource with that name/path exists
      has_name() { api_get "$1" | jq -e --arg n "$2" 'any(.[]; .name == $n)' > /dev/null; }
      has_path() { api_get "$1" | jq -e --arg p "$2" 'any(.[]; .path == $p)' > /dev/null; }

      # Usage: schema_for <endpoint> <implementation>
      schema_for() { api_get "$1/schema" | jq -c --arg impl "$2" '[.[] | select(.implementation == $impl)][0]'; }

      wait_for_lidarr

      ### 1. Root folder #####################################################
      if ! has_path "/rootfolder" "/storage"; then
        echo "Adding root folder: /storage"
        QUALITY_PROFILE_ID=$(api_get "/qualityprofile" | jq '.[0].id')
        METADATA_PROFILE_ID=$(api_get "/metadataprofile" | jq '.[0].id')

        PAYLOAD=$(jq -n \
          --arg path "/storage" --arg name "Storage" \
          --argjson qId "$QUALITY_PROFILE_ID" --argjson mId "$METADATA_PROFILE_ID" \
          '{path: $path, name: $name, defaultQualityProfileId: $qId, defaultMetadataProfileId: $mId}')

        api_post "/rootfolder" "$PAYLOAD"
      fi

      ### 2. Download clients #################################################
      echo "Checking download clients..."

      if ! has_name "/downloadclient" "Slskd"; then
        echo "Adding Slskd download client..."
        PAYLOAD=$(jq -n --arg apiKey "$SLSKD_API_KEY" '{
          enable: true, priority: 1,
          name: "Slskd", implementation: "SlskdClient",
          implementationName: "Slskd", configContract: "SlskdProviderSettings",
          protocol: "SoulseekDownloadProtocol",
          fields: [
            {name: "baseUrl", value: "http://slskd:5030"},
            {name: "host", value: "slskd"},
            {name: "port", value: 5030},
            {name: "apiKey", value: $apiKey},
            {name: "useSsl", value: false}
          ]
        }')
        api_post "/downloadclient" "$PAYLOAD"

        PAYLOAD=$(jq -n '{
            host: "slskd",
            localPath: "/downloads/slskd/",
            remotePath: "/app/downloads/",
        }')
        api_post "/remotepathmapping" "$PAYLOAD"
      fi

      if ! has_name "/downloadclient" "qBittorrent"; then
        echo "Adding download client: qBittorrent"
        PAYLOAD=$(jq -n '{
          enable: true, protocol: "torrent", priority: 1,
          name: "qBittorrent", implementation: "QBittorrent",
          implementationName: "qBittorrent", configContract: "QBittorrentSettings",
          fields: [
            {name: "host", value: "torrent"},
            {name: "port", value: 8086},
            {name: "username", value: ""},
            {name: "password", value: ""},
            {name: "category", value: "lidarr"},
            {name: "useSsl", value: false}
          ]
        }')
        api_post "/downloadclient" "$PAYLOAD"

        PAYLOAD=$(jq -n '{
            host: "torrent",
            localPath: "/downloads/torrent/",
            remotePath: "/downloads/",
        }')
        api_post "/remotepathmapping" "$PAYLOAD"
      fi

      #### 3. Indexers #########################################################
      echo "Checking indexers..."
      if ! has_name "/indexer" "Slskd"; then
        echo "Adding Slskd indexer..."
        PAYLOAD=$(jq -n --arg apiKey "$SLSKD_API_KEY" '{
          enable: true, protocol: "SoulseekDownloadProtocol", priority: 1,
          name: "Slskd", implementation: "SlskdIndexer",
          implementationName: "Slskd", configContract: "SlskdSettings",
          "enableRss": false, "enableAutomaticSearch": true,
          "enableInteractiveSearch": true, "supportsSearch": true,
          fields: [
            {name: "baseUrl", value: "http://slskd:5030"},
            {name: "host", value: "slskd"},
            {name: "port", value: 5030},
            {name: "apiKey", value: $apiKey},
            {name: "useSsl", value: false}
          ]
        }')
        api_post "/indexer" "$PAYLOAD"
      fi

      ### 4. Metadata #####################
        PAYLOAD=$(jq -n --arg apiKey "$SLSKD_API_KEY" '{
            writeAudioTags": "sync",
            scrubAudioTags": true,
            embedCoverArt": true,
            id": 1
        }')

        api_put "/config/metadataProvider" "$PAYLOAD"
    '';
  };
}
