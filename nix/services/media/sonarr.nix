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
      "media/sonarr/apiKey" = {
        sopsFile = ../secrets.yaml;
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d ${config.mySystem.poolMount}/tvseries 0755 1000 1000 -"
    "d ${config.mySystem.poolMount}/downloads 0755 1000 1000 -"
    "d ${config.mySystem.serviceData}/sonarr 0755 1000 1000 -"
  ];

  virtualisation.oci-containers.containers.sonarr = {
    image = "ghcr.io/linuxserver/sonarr:latest";
    autoStart = true;
    volumes = [
      "${config.sops.templates."sonarr-config.xml".path}:/config/config.xml:rw"
      "${config.mySystem.serviceData}/sonarr:/config:rw,U"
      "${config.mySystem.poolMount}/tvseries:/storage:rw"
      "${config.mySystem.poolMount}/downloads:/downloads:rw"
    ];
    environment = {
      PUID = "1000";
      PGID = "1000";
    };
    ports = [
      "8989:8989"
    ];
    extraOptions = [
      "--label-file=${config.sops.templates."sonarr-labels".path}"
    ];
  };

  sops.templates = {
    "sonarr-labels".content = lib.generators.toKeyValue { } {
      "traefik.enable" = "true";
      "traefik.http.routers.sonarr.entryPoints" = "websecure";
      "traefik.http.routers.sonarr.rule" = "Host(`sonarr.${config.sops.placeholder."domain"}`)";
    };

    "sonarr-config.xml".content = ''
      <Config>
        <BindAddress>*</BindAddress>
        <Port>8989</Port>
        <EnableSsl>False</EnableSsl>
        <LaunchBrowser>True</LaunchBrowser>
        <ApiKey>${config.sops.placeholder."media/sonarr/apiKey"}</ApiKey>
        <AuthenticationMethod>External</AuthenticationMethod>
        <AuthenticationRequired>DisabledForLocalAddresses</AuthenticationRequired>
        <Branch>master</Branch>
        <LogLevel>debug</LogLevel>
        <SslCertPath></SslCertPath>
        <SslCertPassword></SslCertPassword>
        <UrlBase></UrlBase>
        <InstanceName>sonarr</InstanceName>
        <UpdateMechanism>Docker</UpdateMechanism>
      </Config>

    '';
  };

  systemd.services."podman-sonarr" = {
    restartTriggers = [
      config.sops.templates."sonarr-labels".content
      config.sops.templates."sonarr-config.xml".content
    ];
    path = with pkgs; [
      curl
      jq
      coreutils
      gnugrep
      unzip
    ];

    postStart = ''
      set -euo pipefail

      API_KEY=$(cat ${config.sops.secrets."media/sonarr/apiKey".path})
      URL="http://localhost:8989/api/v3"

      api_get()  { curl -s -H "X-Api-Key: $API_KEY" "$URL$1"; }
      api_post() { curl -s -o /dev/null -X POST -H "X-Api-Key: $API_KEY" \
                     -H "Content-Type: application/json" -d "$2" "$URL$1"; }
      api_put() { curl -s -o /dev/null -X PUT -H "X-Api-Key: $API_KEY" \
                     -H "Content-Type: application/json" -d "$2" "$URL$1"; }

      wait_for_sonarr() {
        echo "Waiting for sonarr API to become ready..."
        until curl -s -f -H "X-Api-Key: $API_KEY" "$URL/system/status" > /dev/null; do
          sleep 3
        done
      }

      # Usage: has_name <endpoint> <name>  -> exit 0 if a resource with that name/path exists
      has_name() { api_get "$1" | jq -e --arg n "$2" 'any(.[]; .name == $n)' > /dev/null; }
      has_path() { api_get "$1" | jq -e --arg p "$2" 'any(.[]; .path == $p)' > /dev/null; }

      # Usage: schema_for <endpoint> <implementation>
      schema_for() { api_get "$1/schema" | jq -c --arg impl "$2" '[.[] | select(.implementation == $impl)][0]'; }

      wait_for_sonarr

      ### 1. Root folder #####################################################
      if ! has_path "/rootfolder" "/storage"; then
        echo "Adding root folder: /storage"

        PAYLOAD=$(jq -n \
          '{path: "/storage"}'
        )

        api_post "/rootfolder" "$PAYLOAD"
      fi

      ### 2. Download clients #################################################
      echo "Checking download clients..."

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
            {name: "category", value: "sonarr"},
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

    '';
  };
}
