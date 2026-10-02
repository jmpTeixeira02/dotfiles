{ config, lib, ... }:

let
  oidcProviders = [
    {
      providerId = "authelia";
      providerName = "Authelia";
      providerIconUrl = "https://www.authelia.com/images/branding/logo-cropped.png";
      clientId = "papra";
      clientSecret = config.sops.placeholder."other/papra/oidcSecret";
      type = "oidc";
      discoveryUrl = "https://auth.${config.domain}/.well-known/openid-configuration";
      scopes = [
        "openid"
        "profile"
        "email"
      ];
    }
  ];
in
{
  sops.secrets = {
    "other/papra/authSecret".sopsFile = ../secrets.yaml;
    "other/papra/oidcSecret".sopsFile = ../secrets.yaml;
  };

  systemd.tmpfiles.rules = [
    "d ${config.mySystem.serviceData}/papra 0755 1000 1000 -"
  ];

  virtualisation.oci-containers.containers.papra = {
    image = "ghcr.io/papra-hq/papra:latest";
    autoStart = true;
    volumes = [
      "${config.mySystem.serviceData}/papra:/app/app-data:rw,U"
    ];
    environmentFiles = [
      config.sops.templates."papra-env".path
    ];
    extraOptions = [
      "--label-file=${config.sops.templates."papra-labels".path}"
      "--add-host=auth.${config.domain}:host-gateway"
      "--add-host=papra.${config.domain}:host-gateway"
    ];
  };

  sops.templates = {
    "papra-env".content = ''
      APP_BASE_URL=https://papra.${config.domain}
      AUTH_SECRET=${config.sops.placeholder."other/papra/authSecret"}
      AUTH_IS_REGISTRATION_ENABLED=true
      AUTH_PROVIDERS_EMAIL_IS_ENABLED=false
      AUTH_PROVIDERS_CUSTOMS=${lib.generators.toJSON { } oidcProviders}
    '';

    "papra-labels".content = lib.generators.toKeyValue { } {
      "traefik.enable" = "true";
      "traefik.http.routers.papra.entryPoints" = "websecure";
      "traefik.http.routers.papra.rule" = "Host(`papra.${config.domain}`)";
    };

    "papra-flags".content = ''
      "--add-host=auth.${config.domain}:host-gateway"
      "--add-host=papra.${config.domain}:host-gateway"
    '';
  };

  systemd.services."podman-papra" = {
    restartTriggers = [
      config.sops.templates."papra-env".content
      config.sops.templates."papra-labels".content
      config.sops.templates."papra-flags".content
    ];
  };
}
