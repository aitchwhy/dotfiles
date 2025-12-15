# Port Registry - Single Source of Truth
#
# All service ports MUST be defined here and referenced by modules.
# Hook: validate-ports.ts provides advisory guidance for compliance.
#
# Usage in NixOS modules:
#   let ports = import ../../../lib/ports.nix; in
#   { services.foo.port = ports.infrastructure.nodeExporter; }
#
# Usage in process-compose.yaml:
#   # Port from lib/ports.nix: databases.redis = 6379
#   command: redis-server --port 6379
{
  # ===========================================================================
  # INFRASTRUCTURE PORTS (NixOS services, networking)
  # ===========================================================================
  infrastructure = {
    ssh = 22;
    tailscale = 41641;
    nodeExporter = 9100;
    promtail = 9080;
  };

  # ===========================================================================
  # DATABASE PORTS
  # ===========================================================================
  databases = {
    redis = 6379;
    postgresql = 5432;
  };

  # ===========================================================================
  # DEVELOPMENT PORTS (local dev, API services)
  # ===========================================================================
  development = {
    api = 3000;
    worker = 3001;
  };

  # ===========================================================================
  # OPENTELEMETRY PORTS
  # ===========================================================================
  otel = {
    grpc = 4317;
    http = 4318;
  };

  # ===========================================================================
  # OBSERVABILITY PORTS (metrics, logging, tracing)
  # ===========================================================================
  observability = {
    prometheus = 9090;
    grafana = 3100;
    loki = 3200;
  };
}
