# Darwin Tailscale configuration
# Zero-trust mesh VPN with CLI daemon (nix-darwin managed)
#
# Architecture:
#   - CLI + daemon: nix-darwin services.tailscale
#   - No Mac App Store GUI (conflicts with daemon)
#   - Auth: sops-nix managed key at /run/secrets/tailscale-auth
#   - Hostname: matches networking.hostName from hosts/*.nix
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    ;
  cfg = config.modules.darwin.tailscale;

  # Get hostname from networking config (set in hosts/*.nix)
  hostname = config.networking.hostName;

  # Auth key path from sops-nix
  authKeyPath = "/run/secrets/tailscale-auth";
in
{
  options.modules.darwin.tailscale = {
    enable = mkEnableOption "Tailscale VPN";

    useAuthKey = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Use sops-nix managed auth key for automatic authentication.
        Requires modules.darwin.secrets.enable = true and
        secrets/darwin.yaml to contain tailscale-auth.
      '';
    };

    overrideLocalDns = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Override local DNS with Tailscale's MagicDNS.
        Useful when your local network DNS is unreliable.
      '';
    };

    acceptRoutes = mkOption {
      type = types.bool;
      default = true;
      description = "Accept advertised routes from other nodes.";
    };
  };

  config = mkIf cfg.enable {
    # nix-darwin Tailscale service (CLI + daemon)
    services.tailscale = {
      enable = true;
      overrideLocalDns = cfg.overrideLocalDns;
      # Skip tests to avoid socket path length issues on macOS
      package = pkgs.tailscale.overrideAttrs {
        doCheck = false;
      };
    };

    # Automatic authentication via activation script
    # Runs on every darwin-rebuild switch when auth key exists
    system.activationScripts.postActivation.text = mkIf cfg.useAuthKey ''
      # Tailscale auto-authentication
      if [ -f "${authKeyPath}" ]; then
        echo "Configuring Tailscale..."

        # Wait for tailscaled to be ready (max 10 seconds)
        for _ in $(seq 1 10); do
          if /run/current-system/sw/bin/tailscale status &>/dev/null; then
            break
          fi
          sleep 1
        done

        # Check current state
        current_status=$(/run/current-system/sw/bin/tailscale status --json 2>/dev/null | ${pkgs.jq}/bin/jq -r '.BackendState // "Unknown"' || echo "Unknown")

        if [ "$current_status" = "Running" ]; then
          echo "Tailscale already connected"
        else
          echo "Authenticating Tailscale with hostname ${hostname}..."
          # Use --reset to clear any conflicting non-default settings
          /run/current-system/sw/bin/tailscale up \
            --auth-key="$(cat ${authKeyPath})" \
            --hostname="${hostname}" \
            ${lib.optionalString cfg.acceptRoutes "--accept-routes"} \
            --reset \
            || echo "Tailscale auth failed (may need manual login)"
        fi
      else
        echo "Warning: Tailscale auth key not found at ${authKeyPath}"
        echo "Run: sops secrets/darwin.yaml to add tailscale-auth"
      fi
    '';
  };
}
