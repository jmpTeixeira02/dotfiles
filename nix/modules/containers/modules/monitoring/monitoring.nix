{
  flake.modules.nixos.homelab-containers-monitoring =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      prometheusConfig = pkgs.writeText "prometheus.yml" ''
        storage:
          tsdb:
            out_of_order_time_window: 30m
      '';
      dashboardProvider = pkgs.writeText "dashboards.yaml" ''
        apiVersion: 1
        providers:
          - name: default
            type: file
            allowUiUpdates: true
            options:
              path: /var/lib/grafana-dashboards
      '';
      lokiConfig = pkgs.writeText "loki.yaml" ''
        auth_enabled: false

        server:
          http_listen_port: 3100

        common:
          instance_addr: 127.0.0.1
          path_prefix: /loki
          storage:
            filesystem:
              chunks_directory: /loki/chunks
              rules_directory: /loki/rules
          replication_factor: 1
          ring:
            kvstore:
              store: inmemory

        schema_config:
          configs:
            - from: "2024-01-01"
              store: tsdb
              object_store: filesystem
              schema: v13
              index:
                prefix: index_
                period: 24h

        limits_config:
          allow_structured_metadata: true
          retention_period: 720h

        compactor:
          working_directory: /loki/compactor
          retention_enabled: true
          delete_request_store: filesystem

        analytics:
          reporting_enabled: false
      '';
      tempoConfig = pkgs.writeText "tempo.yaml" ''
        server:
          http_listen_port: 3200

        storage:
          trace:
            backend: local
            local:
              path: /var/tempo/traces
            wal:
              path: /var/tempo/wal

        distributor:
          receivers:
            otlp:
              protocols:
                http:
                  endpoint: 0.0.0.0:4418

        usage_report:
          reporting_enabled: false
      '';
      grafanaDatasources = pkgs.writeText "datasources.yaml" ''
        apiVersion: 1
        datasources:
          - name: Prometheus
            uid: prometheus
            type: prometheus
            url: http://prometheus:9090
            isDefault: true
            jsonData:
              timeInterval: 15s
          - name: Loki
            uid: loki
            type: loki
            url: http://loki:3100
            jsonData:
              derivedFields:
                - name: TraceID
                  matcherType: label
                  matcherRegex: traceID
                  url: "$${__value.raw}"
                  datasourceUid: tempo
          - name: Tempo
            uid: tempo
            type: tempo
            url: http://tempo:3200
            jsonData:
              tracesToLogsV2:
                datasourceUid: loki
                spanStartTimeShift: "-5m"
                spanEndTimeShift: "5m"
                filterByTraceID: true
                filterBySpanID: false
              serviceMap:
                datasourceUid: prometheus
              nodeGraph:
                enabled: true
      '';
      otelConfig = pkgs.writeText "otel-config.yaml" ''
        receivers:
          otlp:
            protocols:
              http:
                endpoint: 0.0.0.0:4318
          journald:
            root_path: /host
            journalctl_path: /run/current-system/sw/bin/journalctl
            priority: info
          prometheus:
            config:
              global:
                scrape_interval: 15s
              scrape_configs:
                - job_name: node
                  static_configs:
                    - targets: ['node-exporter:9100']
                - job_name: crowdsec
                  static_configs:
                    - targets: ['crowdsec:6060']
                - job_name: cadvisor
                  static_configs:
                    - targets: ['cadvisor:8080']
        processors:
          memory_limiter:
            check_interval: 5s
            limit_mib: 256
          batch: {}
          transform/journald:
            log_statements:
              - context: log
                statements:
                  - set(resource.attributes["service.name"], body["_SYSTEMD_UNIT"]) where IsMap(body) and body["_SYSTEMD_UNIT"] != nil
                  - set(resource.attributes["service.name"], body["CONTAINER_NAME"]) where IsMap(body) and body["CONTAINER_NAME"] != nil
                  - set(body, body["MESSAGE"]) where IsMap(body) and body["MESSAGE"] != nil
        exporters:
          otlp_http/loki:
            endpoint: http://loki:3100/otlp
            tls:
              insecure: true
          otlp_http/tempo:
            endpoint: http://tempo:4418
            tls:
              insecure: true
          prometheus_remote_write:
            endpoint: http://prometheus:9090/api/v1/write
            tls:
              insecure: true
        service:
          pipelines:
            metrics:
              receivers: [otlp, prometheus]
              processors: [memory_limiter, batch]
              exporters: [prometheus_remote_write]
            logs:
              receivers: [journald]
              processors: [memory_limiter, transform/journald, batch]
              exporters: [otlp_http/loki]
            traces:
              receivers: [otlp]
              processors: [memory_limiter, batch]
              exporters: [otlp_http/tempo]
      '';
    in
    {
      sops = {
        secrets = {
          "monitoring/grafana/oidcSecret" = {
            sopsFile = ../secrets.yaml;
          };
        };
      };

      systemd.tmpfiles.rules = [
        "d ${config.mySystem.serviceData}/prometheus 0755 homelab homelab -"
        "d ${config.mySystem.serviceData}/loki 0755 homelab homelab -"
        "d ${config.mySystem.serviceData}/grafana 0755 homelab homelab -"
        "d ${config.mySystem.serviceData}/tempo 0755 homelab homelab -"
      ];

      virtualisation.oci-containers.containers = {
        cadvisor = {
          image = "ghcr.io/google/cadvisor:v0.60.6@sha256:b8e7d1093144fd088f425ff003d75a4aa405de075db78dae3bc563730b1bd07a";
          autoStart = true;
          extraOptions = [
            "--privileged"
            "--cgroupns=host"
            "--pid=host"
            "--device=/dev/kmsg"
          ];
          volumes = [
            "/:/rootfs:ro"
            "/var/run:/var/run:ro"
            "/sys:/sys:ro"
            "/sys/fs/cgroup:/sys/fs/cgroup:ro"
            "/var/lib/containers:/var/lib/containers:ro"
            "/run/podman/podman.sock:/var/run/docker.sock:ro"
          ];
          cmd = [
            "--docker_only=false"
            "--raw_cgroup_prefix_whitelist=/system.slice/podman-"
          ];
        };
        prometheus = {
          image = "docker.io/prom/prometheus:v3.16.0@sha256:e04987641b57704f408e31f6373ba4138ecf27cb4a165d24aabb6c38fddd0f06";
          autoStart = true;
          user = "1000:1000";
          cmd = [
            "--config.file=/etc/prometheus/prometheus.yml"
            "--storage.tsdb.path=/prometheus"
            "--web.enable-remote-write-receiver"
          ];
          volumes = [
            "${prometheusConfig}:/etc/prometheus/prometheus.yml:ro"
            "${config.mySystem.serviceData}/prometheus:/prometheus:rw"
          ];
        };
        "node-exporter" = {
          image = "quay.io/prometheus/node-exporter:v1.12.1@sha256:1b4e4438faca4dd7e001dd445d161a4a2091b0fededa84093b3a8dfeae1f1be0";
          autoStart = true;
          cmd = [
            "--path.rootfs=/host"
          ];
          volumes = [
            "/:/host:ro,rslave"
          ];
          extraOptions = [
            "--pid=host"
            "--network=host"
          ];
        };
        loki = {
          image = "docker.io/grafana/loki:3.7.10@sha256:b43c257ccfc925d4a50b8717cac61a3b51df8c48d01847936057e5c4075a24a7";
          autoStart = true;
          user = "1000:1000";
          volumes = [
            "${lokiConfig}:/etc/loki/config.yaml:ro"
            "${config.mySystem.serviceData}/loki:/loki:rw"
          ];
          cmd = [
            "--config.file=/etc/loki/config.yaml"
          ];
        };
        tempo = {
          image = "docker.io/grafana/tempo:3.1.1@sha256:64e2fbd56d9c2b3412a4b430a58ea59e91a670b1e75f920a0c702213ad145044";
          autoStart = true;
          user = "1000:1000";
          volumes = [
            "${tempoConfig}:/etc/tempo/config.yaml:ro"
            "${config.mySystem.serviceData}/tempo:/var/tempo:rw"
          ];
          cmd = [
            "-config.file=/etc/tempo/config.yaml"
          ];
        };
        grafana = {
          image = "docker.io/grafana/grafana:13.3.1@sha256:0615ec4fbd4072004b7d86b46ded63013a74b7d6eb1119273dd89e8fa25c13cf";
          autoStart = true;
          user = "1000:1000";
          environment = {
            GF_SERVER_ROOT_URL = "https://grafana.${config.domain}";
            GF_ANALYTICS_REPORTING_ENABLED = "false";
            GF_ANALYTICS_CHECK_FOR_UPDATES = "false";
          };
          environmentFiles = [
            config.sops.templates."grafana-auth-env".path
          ];
          volumes = [
            "${config.mySystem.serviceData}/grafana:/var/lib/grafana:rw"
            "${grafanaDatasources}:/etc/grafana/provisioning/datasources/datasources.yaml:ro"
            "${dashboardProvider}:/etc/grafana/provisioning/dashboards/dashboards.yaml:ro"
            "${./dashboards}:/var/lib/grafana-dashboards:ro"
          ];
          labels = {
            "traefik.enable" = "true";
            "traefik.http.routers.grafana.entryPoints" = "websecure";
            "traefik.http.routers.grafana.rule" = "Host(`grafana.${config.domain}`)";
            "traefik.http.services.grafana.loadbalancer.server.port" = "3000";
          };
          extraOptions = [
            "--add-host=auth.${config.domain}:host-gateway"
          ];
        };
        otel-collector = {
          image = "docker.io/otel/opentelemetry-collector-contrib:0.165.0@sha256:e40d61f10c9a617cca1ffd1be4d7e2b3a4b0f0001798ff07e58cabe82e618cea";
          autoStart = true;
          extraOptions = [
            "--user=0"
            "--add-host=node-exporter:host-gateway"
          ];
          volumes = [
            "${otelConfig}:/etc/otelcol-contrib/config.yaml:ro"
            "/:/host:ro"
            "/run/log/journal:/run/log/journal:ro"
            "/etc/machine-id:/etc/machine-id:ro"
          ];
        };
      };

      networking.firewall.interfaces."podman0".allowedTCPPorts = [ 9100 ];

      sops.templates = {
        "grafana-auth-env".content = lib.generators.toKeyValue { } {
          GF_AUTH_GENERIC_OAUTH_ENABLED = "true";
          GF_AUTH_GENERIC_OAUTH_NAME = "Authelia";
          GF_AUTH_GENERIC_OAUTH_ICON = "signin";
          GF_AUTH_GENERIC_OAUTH_CLIENT_ID = "grafana";
          GF_AUTH_GENERIC_OAUTH_CLIENT_SECRET = config.sops.placeholder."monitoring/grafana/oidcSecret";
          GF_AUTH_GENERIC_OAUTH_ID_TOKEN_ATTRIBUTE_NAME = "disabled_id_token";
          GF_AUTH_GENERIC_OAUTH_SCOPES = "openid profile email groups";
          GF_AUTH_GENERIC_OAUTH_EMPTY_SCOPES = "false";
          GF_AUTH_GENERIC_OAUTH_AUTH_URL = "https://auth.${config.domain}/api/oidc/authorization";
          GF_AUTH_GENERIC_OAUTH_TOKEN_URL = "https://auth.${config.domain}/api/oidc/token";
          GF_AUTH_GENERIC_OAUTH_API_URL = "https://auth.${config.domain}/api/oidc/userinfo";
          GF_AUTH_GENERIC_OAUTH_USE_PKCE = "true";
          GF_AUTH_GENERIC_OAUTH_LOGIN_ATTRIBUTE_PATH = "preferred_username";
          GF_AUTH_GENERIC_OAUTH_ROLE_ATTRIBUTE_PATH = "contains(groups[*], 'admin') && 'Admin' || contains(groups[*], 'editor') && 'Editor' || 'Viewer'";
          GF_AUTH_AUTO_ASSIGN_ORG_ROLE = "Viewer";
          GF_AUTH_GENERIC_OAUTH_NAME_ATTRIBUTE_PATH = "name";
          GF_AUTH_GENERIC_OAUTH_GROUPS_ATTRIBUTE_PATH = "groups";
          GF_AUTH_GENERIC_OAUTH_ALLOW_ASSIGN_GRAFANA_ADMIN = "true";
          GF_AUTH_GENERIC_OAUTH_AUTH_STYLE = "InHeader";
        };
      };

      systemd.services."podman-grafana" = {
        after = [
          "podman-prometheus.service"
          "podman-loki.service"
          "podman-tempo.service"
        ];
        wants = [
          "podman-prometheus.service"
          "podman-loki.service"
          "podman-tempo.service"
        ];
        restartTriggers = [
          config.sops.templates."grafana-auth-env".content
          "${./dashboards}"
          "${dashboardProvider}"
        ];
      };

      systemd.services."podman-otel-collector" = {
        after = [
          "podman-loki.service"
          "podman-prometheus.service"
          "podman-tempo.service"
        ];
        wants = [
          "podman-loki.service"
          "podman-prometheus.service"
          "podman-tempo.service"
        ];
        restartTriggers = [
          "${otelConfig}"
        ];
      };
    };
}
