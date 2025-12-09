# NixOS Tailscale configuration
# Zero-trust mesh VPN for secure remote access
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkDefault
    mkOption
    types
    mkIf
    ;
in
{
  options.modules.nixos.services.tailscale = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Tailscale VPN";
    };

    authKeyFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to file containing Tailscale auth key (from sops-nix)";
    };

    exitNode = mkOption {
      type = types.bool;
      default = false;
      description = "Advertise as exit node";
    };

    ssh = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Tailscale SSH";
    };
  };

  config = mkIf config.modules.nixos.services.tailscale.enable {
    # Tailscale service
    services.tailscale = {
      enable = true;
      useRoutingFeatures = "both";

      # Auth key for automatic authentication
      authKeyFile = config.modules.nixos.services.tailscale.authKeyFile;

      # Extra arguments
      extraUpFlags = [
        "--ssh"
      ]
      ++ (if config.modules.nixos.services.tailscale.exitNode then [ "--advertise-exit-node" ] else [ ]);
    };

    # Trust Tailscale interface in firewall
    networking.firewall = {
      trustedInterfaces = [ "tailscale0" ];
      allowedUDPPorts = [ 41641 ];
    };

    # Enable IP forwarding if acting as exit node
    boot.kernel.sysctl = mkIf config.modules.nixos.services.tailscale.exitNode {
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
    };

    # Tailscale CLI
    environment.systemPackages = [ pkgs.tailscale ];

    # Systemd settings for Tailscale
    systemd.services.tailscaled = {
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
    };
  };
}
