{
  config,
  pkgs,
  lib,
  ...
}:
let
  ldapAuthPlugin = pkgs.fetchzip {
    url = "https://github.com/jellyfin/jellyfin-plugin-ldapauth/releases/download/v24/ldap-authentication_24.0.0.0.zip";
    hash = "sha256-yiyoLahv+tzNWB4JVPoC4fxl+gj8IoYVXv0bi2FGlmM=";
    stripRoot = false;
  };
in
{
  sops = {
    secrets = {
      "domain" = {
        sopsFile = ../secrets.yaml;
      };
      "network/lldap/admin_pass" = {
        sopsFile = ../secrets.yaml;
      };
      "network/lldap/domain" = {
        sopsFile = ../secrets.yaml;
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d ${config.mySystem.poolMount}/movies 0755 1000 1000 -"
    "d ${config.mySystem.poolMount}/tvseries 0755 1000 1000 -"
    "d ${config.mySystem.serviceData}/jellyfin/config 0755 1000 1000 -"
    "d ${config.mySystem.serviceData}/jellyfin/cache 0755 1000 1000 -"
  ];

  virtualisation.oci-containers.containers.jellyfin = {
    image = "ghcr.io/jellyfin/jellyfin:12.1";
    autoStart = true;
    volumes = [
      "${config.mySystem.serviceData}/jellyfin/config:/config:rw"
      "${config.mySystem.serviceData}/jellyfin/cache:/cache:rw"
      "${config.sops.templates."jellyfin-ldap.xml".path}:/config/plugins/configurations/LDAP-Auth.xml:rw" # Need to make rw
      "${config.mySystem.poolMount}/movies:/media/movies:ro"
      "${config.mySystem.poolMount}/tvseries:/media/tv:ro"
    ];
    environment = {
      PUID = "1000";
      PGID = "1000";
    };
    ports = [
      "8096:8096/tcp"
      "7359:7359/udp"
    ];
    extraOptions = [
      "--label-file=${config.sops.templates."jellyfin-labels".path}"
      "--health-start-period=60s"
    ];
  };

  sops.templates = {
    "jellyfin-labels".content = lib.generators.toKeyValue { } {
      "traefik.enable" = "true";
      "traefik.http.routers.jellyfin.entryPoints" = "websecure";
      "traefik.http.routers.jellyfin.rule" = "Host(`jellyfin.${config.sops.placeholder."domain"}`)";
      "traefik.http.services.jellyfin.loadbalancer.server.port" = 8096;
    };
    "jellyfin-ldap.xml" = {
      mode = "0600";
      content = ''
          <PluginConfiguration>
            <LdapUsers>
              <LdapUser> </LdapUser>
            </LdapUsers>
          <LdapServer>lldap</LdapServer>
          <LdapPort>3890</LdapPort>
          <UseSsl>false</UseSsl>
          <UseStartTls>false</UseStartTls>
          <SkipSslVerify>false</SkipSslVerify>
          <LdapBindUser>uid=admin,ou=people,${
            config.sops.placeholder."network/lldap/domain"
          }"</LdapBindUser>
          <LdapBindPassword>${config.sops.placeholder."network/lldap/admin_pass"}</LdapBindPassword>
          <LdapBaseDn>${config.sops.placeholder."network/lldap/domain"}</LdapBaseDn>
          <LdapSearchFilter />
          <LdapAdminBaseDn />
          <LdapAdminFilter>(enabledService=JellyfinAdministrator)</LdapAdminFilter>
          <EnableLdapAdminFilterMemberUid>false</EnableLdapAdminFilterMemberUid>
          <LdapSearchAttributes>uid, cn, mail</LdapSearchAttributes>
          <LdapClientCertPath />
          <LdapClientKeyPath />
          <LdapRootCaPath />
          <CreateUsersFromLdap>true</CreateUsersFromLdap>
          <AllowPassChange>false</AllowPassChange>
          <LdapUidAttribute>uid</LdapUidAttribute>
          <LdapUsernameAttribute>cn</LdapUsernameAttribute>
          <LdapPasswordAttribute>password</LdapPasswordAttribute>
          <EnableLdapProfileImageSync>false</EnableLdapProfileImageSync>
          <RemoveImagesNotInLdap>false</RemoveImagesNotInLdap>
          <LdapProfileImageAttribute>jpegphoto</LdapProfileImageAttribute>
          <LdapProfileImageFormat>Default</LdapProfileImageFormat>
          <EnableAllFolders>true</EnableAllFolders>
          <EnabledFolders> </EnabledFolders>
          <PasswordResetUrl />
        </PluginConfiguration>
      '';

    };
  };

  systemd.services."podman-jellyfin" = {
    after = [ "podman-lldap.service" ];
    requires = [ "podman-lldap.service" ];
    restartTriggers = [
      config.sops.templates."jellyfin-labels".content
      config.sops.templates."jellyfin-ldap.xml".content
    ];

    path = with pkgs; [
      curl
      jq
    ];

    preStart = ''
      PLUGIN_DIR="${config.mySystem.serviceData}/jellyfin/config/plugins/LDAP Authentication"
      if [ ! -d "$PLUGIN_DIR" ]; then
        mkdir -p "$PLUGIN_DIR"
        cp -r ${ldapAuthPlugin}/* "$PLUGIN_DIR/"
      fi
    '';

    postStart = ''
      set -euo pipefail

      JELLYFIN_URL="http://localhost:8096"
      PASS=$(cat ${config.sops.secrets."network/lldap/admin_pass".path})

      until [ "$(curl -s "$JELLYFIN_URL/System/Info/Public" | jq -r '.Version // empty' 2>/dev/null)" != "" ]; do
        sleep 1
      done

      echo "--- Jellyfin is up ---"

      isSetupWizardFinished=$(curl -s "$JELLYFIN_URL/System/Info/Public" | jq -r '.StartupWizardCompleted' 2>/dev/null || true)

        if [ "$isSetupWizardFinished" = "false" ]; then
          echo "--- Running startup wizard ---" 

          echo "--- Creating Server Name ---" # This is marked as deprecated on v12
          curl -sSf -X POST "$JELLYFIN_URL/Startup/Configuration" \
            -H "Content-Type: application/json" \
            -d "$(jq -n '{ServerName:"homelab", UICulture:"en-US", MetadataCountryCode:"US", PreferredMetadataLanguage:"en"}')"


          echo "--- Creating Admin User ---" # This is marked as deprecated on v12
          curl -sSf "$JELLYFIN_URL/Startup/User" 2>dev/null

          curl -sSf -X POST "$JELLYFIN_URL/Startup/User" \
            -H "Content-Type: application/json" \
            -d "$(jq -n --arg p "$PASS" '{Name:"admin",Password:$p}')"

          echo "--- Create Library Dir ---"
          curl -sSf -X POST "$JELLYFIN_URL/Library/VirtualFolders?collectionType=movies&name=Movies" \
            -H "Content-Type: application/json" \
            -d '{"LibraryOptions":{"AutomaticRefreshIntervalDays":30,"PathInfos":[{"Path":"/media/movies"}]}}'
          curl -sSf -X POST "$JELLYFIN_URL/Library/VirtualFolders?collectionType=tvshows&refreshLibrary=false&name=TV%20Shows" \
            -H "Content-Type: application/json" \
            -d '{"LibraryOptions":{"AutomaticRefreshIntervalDays":30,"PathInfos":[{"Path":"/media/tv"}]}}'

          echo "--- Enable RemoteAccess ---" # This is marked as deprecated on v12
          curl -sSf -X POST "$JELLYFIN_URL/Startup/RemoteAccess" \
            -H "Content-Type: application/json" \
            -d "$(jq -n '{EnableRemoteAccess:true}')"

          curl -sSf -X POST "$JELLYFIN_URL/Startup/Complete"
        fi
    '';
  };
}
