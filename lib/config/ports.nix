# Port Registry - Single Source of Truth
#
# All service ports MUST be defined here and referenced by modules.
# Port conflicts are detected at evaluation time via assertions.
#
# Usage in NixOS modules:
#   let cfg = import ../../../lib/config { inherit lib; }; in
#   { services.foo.port = cfg.ports.infrastructure.nodeExporter; }
#
# Usage in docker-compose.yml:
#   environment:
#     - API_PORT=3000  # From lib/config/ports.nix: development.api
{ lib }:
let
  # ===========================================================================
  # PORT DEFINITIONS
  # ===========================================================================
  ports = {
    # -------------------------------------------------------------------------
    # INFRASTRUCTURE PORTS (NixOS services, networking)
    # -------------------------------------------------------------------------
    infrastructure = {
      ssh = 22;
      tailscale = 41641;
      nodeExporter = 9100;
      promtail = 9080;
    };

    # -------------------------------------------------------------------------
    # DATABASE PORTS
    # -------------------------------------------------------------------------
    databases = {
      redis = 6379;
      postgresql = 5432;
    };

    # -------------------------------------------------------------------------
    # DEVELOPMENT PORTS (local dev, API services)
    # -------------------------------------------------------------------------
    development = {
      api = 3000;
      worker = 3001;
    };

    # -------------------------------------------------------------------------
    # OPENTELEMETRY PORTS
    # -------------------------------------------------------------------------
    otel = {
      grpc = 4317;
      http = 4318;
    };

    # -------------------------------------------------------------------------
    # OBSERVABILITY PORTS (metrics, logging, tracing)
    # -------------------------------------------------------------------------
    observability = {
      prometheus = 9090;
      grafana = 3100;
      loki = 3200;
    };
  };

  # ===========================================================================
  # PORT VALIDATION
  # ===========================================================================

  # Flatten nested port attrset into list of { path, port } records
  # e.g., { otel.grpc = 4317 } -> [{ path = "otel.grpc"; port = 4317; }]
  flattenPorts =
    prefix: attrs:
    lib.flatten (
      lib.mapAttrsToList (
        name: value:
        let
          newPrefix = if prefix == "" then name else "${prefix}.${name}";
        in
        if builtins.isAttrs value && !(value ? __toString) then
          flattenPorts newPrefix value
        else
          [
            {
              path = newPrefix;
              port = value;
            }
          ]
      ) attrs
    );

  # All ports as flat list
  flatPorts = flattenPorts "" ports;

  # Group ports by their value to detect duplicates
  portGroups = builtins.groupBy (p: toString p.port) flatPorts;

  # Find duplicates (groups with more than one entry)
  duplicates = lib.filterAttrs (_: v: builtins.length v > 1) portGroups;

  # Format duplicate error message for assertion
  formatDuplicates = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (
      port: paths: "  Port ${port}: ${lib.concatMapStringsSep ", " (p: p.path) paths}"
    ) duplicates
  );

in
{
  # Export ports with same structure as before (backwards compatible)
  inherit ports;

  # Flat list for iteration/inspection
  inherit flatPorts;

  # Compile-time assertions for nix flake check
  assertions = [
    {
      assertion = duplicates == { };
      message = ''
        Port conflict detected in lib/config/ports.nix!
        The following ports are assigned to multiple services:
        ${formatDuplicates}

        Fix by assigning unique ports to each service.
      '';
    }
  ];
}
