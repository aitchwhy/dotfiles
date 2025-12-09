# Darwin Tailscale configuration
# Zero-trust mesh VPN with CLI daemon
#
# Note: nix-darwin provides CLI + launchd daemon
# For GUI (menu bar), install from Mac App Store (ID: 1475387142)
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
  };

  config = mkIf cfg.enable {
    # nix-darwin Tailscale service (CLI + daemon)
    services.tailscale = {
      enable = true;
      overrideLocalDns = cfg.overrideLocalDns;
      # Skip tests to avoid socket path length issues on macOS
      package = pkgs.tailscale.overrideAttrs (old: {
        doCheck = false;
      });
    };

    # Note: Automatic authentication via sops-nix auth key is handled by
    # modules/darwin/secrets.nix when secrets/darwin.yaml exists.
    # After creating the secrets file, run:
    #   sudo tailscale up --auth-key="$(sudo cat /run/secrets/tailscale-auth)" --accept-routes
    # Or simply use the Mac App Store GUI to log in.
  };
}
