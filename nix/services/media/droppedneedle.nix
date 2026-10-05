{
  config,
  pkgs,
  ...
}:

{
  sops = {
    secrets = {
      "network/lldap/admin_pass" = {
        sopsFile = ../secrets.yaml;
      };
      "media/droppedneedle/oidcSecret" = {
        sopsFile = ../secrets.yaml;
      };
      "media/slskd/apiKey" = {
        sopsFile = ../secrets.yaml;
      };
      "media/droppedneedle/acoustid" = {
        sopsFile = ../secrets.yaml;
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d ${config.mySystem.poolMount}/music 0755 1000 1000 -"
    "d ${config.mySystem.poolMount}/downloads 0755 1000 1000 -"
    "d ${config.mySystem.serviceData}/droppedneedle/config 0755 1000 1000 -"
    "d ${config.mySystem.serviceData}/droppedneedle/cache 0755 1000 1000 -"
  ];

  virtualisation.oci-containers.containers.droppedneedle = {
    image = "ghcr.io/droppedneedle/droppedneedle:latest";
    autoStart = true;
    user = "1000:1000";
    volumes = [
      "${config.mySystem.serviceData}/droppedneedle/config:/app/config"
      "${config.mySystem.serviceData}/droppedneedle/cache:/app/cache"
      "${config.mySystem.poolMount}/music:/music:rw"
      "${config.mySystem.poolMount}/downloads/slskd:/slskd-downloads:rw"
    ];
    ports = [
      "8688:8688"
    ];
    environment = {
      SLSKD_DOWNLOADS_PATH = "/slskd-downloads";
    };
    extraOptions = [
      "--add-host=auth.${config.domain}:host-gateway"
      "--add-host=droppedneedle.${config.domain}:host-gateway"
    ];
    labels = {
      "traefik.enable" = "true";
      "traefik.http.routers.droppedneedle.entryPoints" = "websecure";
      "traefik.http.routers.droppedneedle.rule" = "Host(`droppedneedle.${config.domain}`)";
    };
  };
  systemd.services."podman-droppedneedle" = {
    after = [
      "podman-jellyfin.service"
      "podman-navidrome.service"
    ];
    requires = [
      "podman-navidrome.service"
    ];

    path = with pkgs; [
      curl
      jq
    ];

    postStart = ''
      set -euo pipefail
      DROPPED_NEEDLE_URL="http://localhost:8688"
      PASS=$(cat ${config.sops.secrets."network/lldap/admin_pass".path})

      until required=$(curl -sf --max-time 2 "$DROPPED_NEEDLE_URL/api/v1/auth/setup/status" | jq -er '.required | select(type == "boolean") | tostring'); do
        sleep 2
      done

      if [ "$required" == "true" ]; then
        echo "--- Setup Admin User ---"
        curl -sSf -X POST "$DROPPED_NEEDLE_URL/api/v1/auth/setup" \
          -H "Content-Type: application/json" \
          -d "$(jq -n --arg p "$PASS" '{username:"admin",display_name:"admin",password:$p}')"
      fi

      echo "--- Get Admin Token ---"
      token=$(curl -sSf -X POST "$DROPPED_NEEDLE_URL/api/v1/auth/login" \
        -H "Content-Type: application/json" \
        -d "$(jq -n --arg p "$PASS" '{username:"admin",password:$p}')" | jq -r '.token')

      authHeader="Authorization: Bearer $token"

      echo "--- Setup Youtube ---"
      curl -sSf -X PUT "$DROPPED_NEEDLE_URL/api/v1/settings/youtube" \
        -H "Content-Type: application/json" \
        -H "$authHeader" \
        -d "$(jq -n '{enabled:"true"}')"

      echo "--- Setup OIDC ---"
      OIDC_SECRET=$(cat ${config.sops.secrets."media/droppedneedle/oidcSecret".path})

      curl -sSf -i -X PUT "$DROPPED_NEEDLE_URL/api/v1/settings/oidc" \
      -H "$authHeader" \
      -H "Content-Type: application/json" \
      -d "$(jq -n --arg secret "$OIDC_SECRET" '{
        enabled: true,
        issuer: "https://auth.${config.domain}",
        client_id: "droppedneedle",
        client_secret: $secret,
        scopes: "openid email profile",
        redirect_uri: "https://droppedneedle.${config.domain}/api/v1/auth/oidc/callback"
      }')"

      echo "--- Setup SLSKD ---"
      SLSKD_API_KEY=$(cat ${config.sops.secrets."media/slskd/apiKey".path})

      curl -sSf -i -X PUT "$DROPPED_NEEDLE_URL/api/v1/download-client/config" \
      -H "$authHeader" \
      -H "Content-Type: application/json" \
      -d "$(jq -n --arg secret "$SLSKD_API_KEY" '{
        enabled: true,
        client_type: "slskd",
        url: "http://slskd:5030",
        api_key: $secret,
      }')"
    '';
  };
}
