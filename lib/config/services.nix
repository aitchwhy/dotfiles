# Service Definitions - URLs, health endpoints, connection strings
#
# All service URLs and endpoints are derived from ports.nix for consistency.
# This prevents split-brain configuration where URLs don't match ports.
#
# Usage:
#   let cfg = import ../../../lib/config { inherit lib; }; in
#   { clients.loki.url = cfg.services.loki.pushUrl; }
{ lib, ports }:
let
  # Default hosts
  hosts = {
    localhost = "127.0.0.1";
  };

  # Helper to build HTTP URL
  mkUrl =
    {
      host ? hosts.localhost,
      port,
      path ? "",
    }:
    "http://${host}:${toString port}${path}";

  # Helper to build service with standard fields
  mkService =
    {
      name,
      host ? hosts.localhost,
      port,
      healthPath ? "/health",
    }:
    {
      inherit
        name
        host
        port
        healthPath
        ;
      url = mkUrl { inherit host port; };
      healthUrl = mkUrl {
        inherit host port;
        path = healthPath;
      };
    };

in
{
  # ===========================================================================
  # INFRASTRUCTURE SERVICES
  # ===========================================================================

  nodeExporter = mkService {
    name = "node-exporter";
    port = ports.infrastructure.nodeExporter;
    healthPath = "/metrics";
  };

  promtail = mkService {
    name = "promtail";
    port = ports.infrastructure.promtail;
    healthPath = "/ready";
  };

  # ===========================================================================
  # DATABASE SERVICES
  # ===========================================================================

  redis = {
    name = "redis";
    host = hosts.localhost;
    port = ports.databases.redis;
    url = "redis://${hosts.localhost}:${toString ports.databases.redis}";
  };

  postgresql = {
    name = "postgresql";
    host = hosts.localhost;
    port = ports.databases.postgresql;

    # Connection string builder
    connectionString =
      {
        user,
        password ? "",
        database,
      }:
      let
        passStr = if password == "" then "" else ":${password}";
      in
      "postgresql://${user}${passStr}@${hosts.localhost}:${toString ports.databases.postgresql}/${database}";
  };

  # ===========================================================================
  # DEVELOPMENT SERVICES
  # ===========================================================================

  api = mkService {
    name = "api";
    port = ports.development.api;
    healthPath = "/health";
  };

  worker = mkService {
    name = "worker";
    port = ports.development.worker;
    healthPath = "/health";
  };

  # ===========================================================================
  # OPENTELEMETRY
  # ===========================================================================

  otelCollector = {
    name = "otel-collector";
    host = hosts.localhost;
    grpcPort = ports.otel.grpc;
    httpPort = ports.otel.http;
    grpcUrl = "grpc://${hosts.localhost}:${toString ports.otel.grpc}";
    httpUrl = mkUrl { port = ports.otel.http; };
  };

  # ===========================================================================
  # OBSERVABILITY SERVICES
  # ===========================================================================

  prometheus =
    (mkService {
      name = "prometheus";
      port = ports.observability.prometheus;
      healthPath = "/-/healthy";
    })
    // {
      pushUrl = mkUrl {
        port = ports.observability.prometheus;
        path = "/api/v1/write";
      };
    };

  grafana = mkService {
    name = "grafana";
    port = ports.observability.grafana;
    healthPath = "/api/health";
  };

  loki =
    (mkService {
      name = "loki";
      port = ports.observability.loki;
      healthPath = "/ready";
    })
    // {
      pushUrl = mkUrl {
        port = ports.observability.loki;
        path = "/loki/api/v1/push";
      };
    };
}
