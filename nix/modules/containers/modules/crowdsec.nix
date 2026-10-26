{
  flake.modules.nixos.homelab-containers-crowdsec =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    let
      acquis = pkgs.writeText "acquis.yaml" ''
        filenames:
          - /var/log/traefik/access.log
        labels:
          type: traefik
        ---
        filenames:
          - /var/log/authelia/authelia.log
        labels:
          type: authelia
      '';
    in
    {
      systemd.tmpfiles.rules = [
        "d ${config.mySystem.serviceData}/crowdsec 0755 homelab homelab -"
        "d ${config.mySystem.serviceData}/crowdsec/config 0755 homelab homelab -"
        "d ${config.mySystem.serviceData}/crowdsec/data 0755 homelab homelab -"
      ];
      virtualisation.oci-containers.containers.crowdsec = {
        image = "docker.io/crowdsecurity/crowdsec:latest";
        autoStart = true;
        environment = {
          COLLECTIONS = "crowdsecurity/traefik crowdsecurity/linux crowdsecurity/appsec-virtual-patching crowdsecurity/appsec-generic-rules crowdsecurity/http-cve crowdsecurity/base-http-scenarios LePresidente/authelia";
        };
        volumes = [
          "${config.mySystem.serviceData}/crowdsec/config:/etc/crowdsec:rw"
          "${config.mySystem.serviceData}/crowdsec/data:/var/lib/crowdsec/data:rw"
          "${config.mySystem.serviceData}/traefik/logs:/var/logs/traefik:ro"
          "${config.mySystem.serviceData}/authelia/logs:/var/logs/authelia:ro"
          "${acquis}:/etc/crowdsec/acquis.yaml:ro"
        ];
        labels = {
          "traefik.enable" = "true";
          "traefik.http.routers.dockhand.entryPoints" = "websecure";
          "traefik.http.routers.dockhand.rule" = "Host(`crowdsec.${config.domain}`)";
        };
        environmentFiles = [
          config.sops.templates."crowdsec-env".path
        ];
      };
      sops.templates."crowdsec-env".content = lib.generators.toKeyValue { } {
        BOUNCER_KEY_traefik = config.sops.placeholder."crowdsec/traefik";
      };
    };
}
