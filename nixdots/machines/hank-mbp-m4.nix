# MacBook Pro M4 specific configuration
# This file contains:
# - Machine-specific network configuration
# - Hardware-specific tools and optimizations
# - Machine-specific services (e.g., Tailscale)
{ pkgs, ... }:
{
  networking.hostName = "hank-mbp-m4";
  networking.computerName = "Hank's MacBook Pro";
  networking.localHostName = "hank-mbp-m4";

  system.stateVersion = 4;

  # Tailscale VPN
  services.tailscale.enable = true;

  # Machine-specific network tools
  environment.systemPackages = with pkgs; [
    # Network diagnostics
    mtr
    iperf3
  ];
}
