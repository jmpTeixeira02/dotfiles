{
  config,
  pkgs,
  lib,
  ...
}:

let
  # Now an attribute set to define specific tags per provider
  desiredProviders = [
    {
      name = "Nyaa.si";
    }
    {
      name = "LimeTorrents";
    }
    {
      name = "The Pirate Bay";
    }
    {
      name = "YTS";
    }
    {
      name = "1337x";
      tags = [ "flaresolverr" ];
    }
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
      "media/sonarr/apiKey" = {
        sopsFile = ../secrets.yaml;
      };
      "media/radarr/apiKey" = {
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
      TAGS_URL="http://localhost:9696/api/v1/tag"

      echo "Waiting for Prowlarr API to become ready..."
      until curl -s -f -H "X-Api-Key: $API_KEY" "$INDEXER_URL" > /dev/null; do
        sleep 3
      done

      #### 0. Ensure Flaresolverr Tag Exists (For the Proxy itself) ######################
      FS_TAG_ID=$(curl -sS -X GET "$TAGS_URL" -H "X-Api-Key: $API_KEY" \
          | jq -r 'try (.[] | select(.label == "flaresolverr") | .id) catch empty')

      if [ -z "$FS_TAG_ID" ] || [ "$FS_TAG_ID" = "null" ]; then
          echo "Creating Tag flaresolverr"
          PAYLOAD=$(jq -n  '{ label: "flaresolverr" }')

          RESPONSE=$(curl -sS -X POST "$TAGS_URL" \
          -H "X-Api-Key: $API_KEY" \
          -H "Content-Type: application/json" \
          -d "$PAYLOAD")

          FS_TAG_ID=$(echo "$RESPONSE" | jq -r '.id // .[0].id')
      fi

      #### 1. Add Indexer Proxy ######################
      INDEXER_PROXY_URL="http://localhost:9696/api/v1/indexerProxy"
      INDEXER_PROXIES=$(curl -sS -H "X-Api-Key: $API_KEY" "$INDEXER_PROXY_URL")

      FLARESOLVERR_EXISTS=$(echo "$INDEXER_PROXIES" | jq -r '[.[] | select(.name == "FlareSolverr")] | length')
        if [ "$FLARESOLVERR_EXISTS" -eq 0 ]; then
            echo "Adding Flaresolverr to Prowlarr Indexer Proxies..."

            PAYLOAD=$(jq -n --argjson tagID "$FS_TAG_ID" \
            '{
                name: "FlareSolverr",
                syncLevel: "fullSync",
                implementation: "FlareSolverr",
                implementationName: "FlareSolverr",
                configContract: "FlareSolverrSettings",
                fields: [
                    { name: "host", value: "http://flaresolverr:8191" }
                ],
                tags: [$tagID]
            }')

            curl -sS -f -X POST "$INDEXER_PROXY_URL" \
            -H "X-Api-Key: $API_KEY" \
            -H "Content-Type: application/json" \
            -d "$PAYLOAD"
        fi

      #### 2. Add Providers with Custom Tags ######################
      EXISTING=$(curl -s -H "X-Api-Key: $API_KEY" "$INDEXER_URL" | jq -r '.[].name')
      SCHEMAS=$(curl -s -H "X-Api-Key: $API_KEY" "$INDEXER_URL/schema")

      # Convert the Nix provider list to JSON for jq parsing
      PROVIDERS_JSON='${builtins.toJSON desiredProviders}'

      # Extract all unique tags declared across all providers in the Nix config
      UNIQUE_TAGS=$(echo "$PROVIDERS_JSON" | jq -r '.[].tags[]?' | sort -u)

      # Build a JSON map of "TagName" -> TagID
      TAG_MAP="{}"
      for tag in $UNIQUE_TAGS; do
        TAG_ID=$(curl -sS -X GET "$TAGS_URL" -H "X-Api-Key: $API_KEY" | jq -r --arg t "$tag" 'try (.[] | select(.label == $t) | .id) catch empty')
        
        if [ -z "$TAG_ID" ] || [ "$TAG_ID" = "null" ]; then
           echo "Creating Tag: $tag"
           PAYLOAD=$(jq -n --arg t "$tag" '{ label: $t }')
           RESPONSE=$(curl -sS -X POST "$TAGS_URL" -H "X-Api-Key: $API_KEY" -H "Content-Type: application/json" -d "$PAYLOAD")
           TAG_ID=$(echo "$RESPONSE" | jq -r '.id // .[0].id')
        fi
        
        # Append to our bash JSON map mapping TagName -> TagID
        TAG_MAP=$(echo "$TAG_MAP" | jq --arg t "$tag" --arg id "$TAG_ID" '.[$t] = ($id | tonumber)')
      done

      # Loop over the providers and apply specific configurations and tags
      echo "$PROVIDERS_JSON" | jq -c '.[]' | while read -r providerObj; do
        PROVIDER_NAME=$(echo "$providerObj" | jq -r '.name')
        
        if ! echo "$EXISTING" | grep -q "^$PROVIDER_NAME$"; then
           echo "Adding provider: $PROVIDER_NAME"
           
           # Get the specific TagIDs for this provider by querying our TAG_MAP
           TAG_IDS=$(echo "$providerObj" | jq -c --argjson map "$TAG_MAP" '[.tags[]? | $map[.]]')
           
           # Generate the payload with the correct tags attached
           PAYLOAD=$(echo "$SCHEMAS" | jq -c --arg name "$PROVIDER_NAME" --argjson tags "$TAG_IDS" \
             '.[] | select(.name == $name) | .enable = true | .appProfileId = 1 | .tags = $tags')
            
          curl -s -o /dev/null -X POST "$INDEXER_URL" \
          -H "X-Api-Key: $API_KEY" \
          -H "Content-Type: application/json" \
          -d "$PAYLOAD"
        fi
      done

      #### 3. Add Apps ######################
      echo "Checking Prowlarr application sync for Lidarr, Sonarr, Radarr..."

      APPLICATIONS_URL="http://localhost:9696/api/v1/applications"
      APPS=$(curl -sS -H "X-Api-Key: $API_KEY" "$APPLICATIONS_URL")

      LIDARR_EXISTS=$(echo "$APPS" | jq -r '[.[] | select(.name == "Lidarr")] | length')
        if [ "$LIDARR_EXISTS" -eq 0 ]; then
            echo "Adding Lidarr to Prowlarr applications..."

            LIDARR_API_KEY=$(cat ${config.sops.secrets."media/lidarr/apiKey".path})

            LIDARR_PAYLOAD=$(jq -n --arg apiKey "$LIDARR_API_KEY" \
            '{
                name: "Lidarr",
                syncLevel: "fullSync",
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
      SONARR_EXISTS=$(echo "$APPS" | jq -r '[.[] | select(.name == "Sonarr")] | length')
        if [ "$SONARR_EXISTS" -eq 0 ]; then
            echo "Adding Sonarr to Prowlarr applications..."
            SONARR_API_KEY=$(cat ${config.sops.secrets."media/sonarr/apiKey".path})

            SONARR_PAYLOAD=$(jq -n --arg apiKey "$SONARR_API_KEY" \
            '{
                name: "Sonarr",
                syncLevel: "fullSync",
                implementation: "Sonarr",
                implementationName: "Sonarr",
                configContract: "SonarrSettings",
                fields: [
                    { name: "prowlarrUrl", value: "http://prowlarr:9696" },
                    { name: "baseUrl", value: "http://sonarr:8989" },
                    { name: "apiKey", value: $apiKey }
                ],
                tags: []
            }')

            curl -sS -f -X POST "$APPLICATIONS_URL" \
            -H "X-Api-Key: $API_KEY" \
            -H "Content-Type: application/json" \
            -d "$SONARR_PAYLOAD"
        fi
      RADARR_EXISTS=$(echo "$APPS" | jq -r '[.[] | select(.name == "Radarr")] | length')
        if [ "$RADARR_EXISTS" -eq 0 ]; then
            echo "Adding Radarr to Prowlarr applications..."
            RADARR_API_KEY=$(cat ${config.sops.secrets."media/radarr/apiKey".path})

            RADARR_PAYLOAD=$(jq -n --arg apiKey "$RADARR_API_KEY" \
            '{
                name: "Radarr",
                syncLevel: "fullSync",
                implementation: "Radarr",
                implementationName: "Radarr",
                configContract: "RadarrSettings",
                fields: [
                    { name: "prowlarrUrl", value: "http://prowlarr:9696" },
                    { name: "baseUrl", value: "http://radarr:7878" },
                    { name: "apiKey", value: $apiKey }
                ],
                tags: []
            }')

            curl -sS -f -X POST "$APPLICATIONS_URL" \
            -H "X-Api-Key: $API_KEY" \
            -H "Content-Type: application/json" \
            -d "$RADARR_PAYLOAD"
        fi

    '';
  };
}
