# Library exports for dotfiles
#
# MIGRATION: lib/config/ is the new centralized configuration
#
# Old pattern (DEPRECATED):
#   let lib' = import ../lib; in lib'.ports.infrastructure.ssh
#
# New pattern (RECOMMENDED):
#   let cfg = import ../lib/config { inherit lib; }; in cfg.ports.infrastructure.ssh
#
# The new pattern provides:
#   - cfg.ports.* - Same port access as before
#   - cfg.services.* - Service URLs and health endpoints
#   - cfg.network.* - Network configuration
#   - cfg.assertions - Port conflict validation
#
# lib.ports is kept for backwards compatibility during migration.
{
  lib ? import <nixpkgs/lib>,
}:
{
  # DEPRECATED: Use import ./config { inherit lib; } instead
  # Kept for backwards compatibility during migration
  ports = import ./ports.nix;

  # New centralized config (requires lib argument)
  # Usage: let cfg = import ../lib/config { inherit lib; };
  config = import ./config { inherit lib; };
}
