# Centralized Configuration - Entry Point
#
# Single source of truth for all configuration values.
# Import this module to access ports, services, and network config.
#
# Usage in modules:
#   let cfg = import ../../../lib/config { inherit lib; };
#   {
#     services.foo.port = cfg.ports.infrastructure.nodeExporter;
#     clients.loki.url = cfg.services.loki.pushUrl;
#   }
#
# Port conflict detection runs at evaluation time via assertions.
# Use cfg.assertions in your module system to enable validation.
{ lib }:
let
  # Load port definitions with validation
  portsModule = import ./ports.nix { inherit lib; };

  # Load network configuration
  network = import ./network.nix { inherit lib; };

  # Load service definitions (depends on ports)
  services = import ./services.nix {
    inherit lib;
    ports = portsModule.ports;
  };

in
{
  # Re-export ports with same structure as lib/ports.nix (backwards compatible)
  inherit (portsModule) ports;

  # Service definitions with URLs and health endpoints
  inherit services;

  # Network configuration
  inherit network;

  # Assertions for compile-time validation (use in module system)
  inherit (portsModule) assertions;

  # Flat port list for inspection
  inherit (portsModule) flatPorts;
}
