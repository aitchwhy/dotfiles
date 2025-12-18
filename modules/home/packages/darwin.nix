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
      # Container Tools (not needed on NixOS - use system Docker)
      docker-client

      # Infrastructure Tools (macOS workstation only)
      opentofu # Modern Terraform alternative
      pulumiPackages.pulumi-nodejs

      # TUI Components
      gum # TUI components for shell scripts

      # macOS Apps (migrated from Homebrew)
      iina # Video player
      keka # File archiver
    ];
  };
}
