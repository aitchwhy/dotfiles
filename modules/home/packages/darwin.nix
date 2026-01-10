# macOS-only packages
# These packages are either:
# - macOS-specific applications (iina, keka)
# - Only needed on macOS workstation (docker-client, opentofu)
# - macOS-specific tooling (gum for TUI prompts)
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.modules.home.packages;
in
{
  config = mkIf (cfg.enable && pkgs.stdenv.isDarwin) {
    home.packages = with pkgs; [
      # Container Tools: Colima provides docker runtime via Homebrew brews
      # (colima, docker, docker-credential-helper)
      # Note: docker-compose removed - use `docker compose` (v2 built-in)

      # Infrastructure Tools (macOS workstation only)
      # Note: opentofu removed - using Pulumi only for IaC
      pulumiPackages.pulumi-nodejs

      # TUI Components
      gum # TUI components for shell scripts

      # macOS Apps (migrated from Homebrew)
      iina # Video player
      keka # File archiver

      # Health Data Tools (ADR-011)
      mywhoop # WHOOP API CLI client
    ];
  };
}
