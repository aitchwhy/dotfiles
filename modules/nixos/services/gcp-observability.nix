# Google Cloud Observability configuration
# Ships metrics and logs to Google Cloud Monitoring and Logging
# Docs: https://cloud.google.com/monitoring/docs
{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit
    (lib)
    mkOption
    types
    mkIf
    mkEnableOption
    ;

  cfg = config.modules.nixos.services.gcp-observability;
in {
  options.modules.nixos.services.gcp-observability = {
    enable = mkEnableOption "Google Cloud observability agents";

    projectId = mkOption {
      type = types.str;
      description = "Google Cloud project ID for metrics/logs";
      example = "my-project-123";
    };

    credentialsFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to GCP service account JSON key (from sops-nix)";
    };

    metrics = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable metrics collection via OpenTelemetry Collector";
      };

      collectionInterval = mkOption {
        type = types.str;
        default = "60s";
        description = "How often to collect metrics";
      };
    };

    logs = {
      enable = mkOption {
        type = types.bool;
        default = false; # Disabled: requires Loki or GCP Ops Agent setup
        description = "Enable log shipping via Promtail";
      };

      maxAge = mkOption {
        type = types.str;
        default = "12h";
        description = "Maximum age of journal entries to ship";
      };
    };

    nodeExporter = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Prometheus Node Exporter for system metrics";
      };

      port = mkOption {
        type = types.port;
        default = 9100;
        description = "Port for Node Exporter";
      };
    };
  };

  config = mkIf cfg.enable {
    # Set GCP credentials environment variable
    environment.variables = mkIf (cfg.credentialsFile != null) {
      GOOGLE_APPLICATION_CREDENTIALS = toString cfg.credentialsFile;
    };

    # Prometheus Node Exporter for system metrics
    services.prometheus.exporters.node = mkIf cfg.nodeExporter.enable {
      enable = true;
      port = cfg.nodeExporter.port;
      enabledCollectors = [
        "cpu"
        "diskstats"
        "filesystem"
        "loadavg"
        "meminfo"
        "netdev"
        "stat"
        "systemd"
        "processes"
        "vmstat"
      ];
      # Only listen on localhost and Tailscale
      listenAddress = "127.0.0.1";
    };

    # OpenTelemetry Collector for metrics to GCP
    # Note: nixpkgs may not have otelcol-contrib with GCP exporter
    # Using a systemd service with the official binary instead
    systemd.services.otel-collector = mkIf cfg.metrics.enable {
      description = "OpenTelemetry Collector for GCP";
      wantedBy = ["multi-user.target"];
      after = ["network-online.target"];
      wants = ["network-online.target"];

      environment = mkIf (cfg.credentialsFile != null) {
        GOOGLE_APPLICATION_CREDENTIALS = toString cfg.credentialsFile;
      };

      serviceConfig = {
        Type = "simple";
        User = "otel-collector";
        Group = "otel-collector";
        DynamicUser = true;
        ExecStart = "${pkgs.opentelemetry-collector-contrib}/bin/otelcol-contrib --config=/etc/otel-collector/config.yaml";
        Restart = "always";
        RestartSec = "10s";

        # Security hardening
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        PrivateDevices = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
      };
    };

    # OTel Collector configuration file
    environment.etc."otel-collector/config.yaml" = mkIf cfg.metrics.enable {
      text = ''
        receivers:
          prometheus:
            config:
              scrape_configs:
                - job_name: 'node-exporter'
                  scrape_interval: ${cfg.metrics.collectionInterval}
                  static_configs:
                    - targets: ['localhost:${toString cfg.nodeExporter.port}']
                  relabel_configs:
                    - source_labels: [__address__]
                      target_label: instance
                      replacement: 'cloud-nixos'

          hostmetrics:
            collection_interval: ${cfg.metrics.collectionInterval}
            scrapers:
              cpu:
              disk:
              filesystem:
              load:
              memory:
              network:
              process:

        processors:
          batch:
            timeout: 10s
            send_batch_size: 1000

          memory_limiter:
            check_interval: 1s
            limit_mib: 256

          resourcedetection:
            detectors: [env, system]
            timeout: 2s

        exporters:
          googlecloud:
            project: ${cfg.projectId}
            metric:
              prefix: custom.googleapis.com/nixos
            retry_on_failure:
              enabled: true
              initial_interval: 5s
              max_interval: 30s
              max_elapsed_time: 300s

          logging:
            loglevel: warn

        service:
          pipelines:
            metrics:
              receivers: [prometheus, hostmetrics]
              processors: [memory_limiter, batch, resourcedetection]
              exporters: [googlecloud, logging]
      '';
    };

    # Promtail for log shipping to Google Cloud Logging
    # Note: Google Cloud Logging has native journal support via Ops Agent
    # This is a fallback using Promtail → Cloud Logging API
    services.promtail = mkIf cfg.logs.enable {
      enable = true;
      configuration = {
        server = {
          http_listen_port = 9080;
          grpc_listen_port = 0;
        };

        positions = {
          filename = "/var/lib/promtail/positions.yaml";
        };

        # Push to local Loki or use GCP's logging endpoint
        # For GCP Logging, you'd use the google-cloud-logging client
        # This config is for local aggregation
        clients = [
          {
            # FIXME: Promtail cannot directly push to GCP Cloud Logging.
            # Options to fix:
            # 1. Install Google Cloud Ops Agent (recommended): https://cloud.google.com/logging/docs/agent/ops-agent
            # 2. Run Loki locally and export to GCP: https://grafana.com/docs/loki/latest/
            # 3. Use Vector instead of Promtail with GCP sink: https://vector.dev/
            # For now, logs.enable defaults to false
            url = "http://localhost:3100/loki/api/v1/push";
          }
        ];

        scrape_configs = [
          {
            job_name = "journal";
            journal = {
              json = false;
              max_age = cfg.logs.maxAge;
              labels = {
                job = "systemd-journal";
                host = "cloud-nixos";
              };
            };
            relabel_configs = [
              {
                source_labels = ["__journal__systemd_unit"];
                target_label = "unit";
              }
              {
                source_labels = ["__journal_priority_keyword"];
                target_label = "level";
              }
            ];
          }
        ];
      };
    };

    # Firewall: Only expose metrics on Tailscale interface
    networking.firewall.interfaces.tailscale0 = mkIf cfg.nodeExporter.enable {
      allowedTCPPorts = [cfg.nodeExporter.port];
    };

    # Install additional observability tools
    environment.systemPackages = with pkgs; [
      # Metrics inspection
      prometheus
      # Log tailing
      lnav
    ];
  };
}
