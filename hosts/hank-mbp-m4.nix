# MacBook Pro M4 specific configuration
# This file contains:
# - Machine-specific network configuration
# - Hardware-specific tools and optimizations
{pkgs, ...}: {
  networking.hostName = "hank-mbp-m4";
  networking.computerName = "Hank's MacBook Pro";
  networking.localHostName = "hank-mbp-m4";

  system.stateVersion = 5;

  # Tailscale is enabled via modules.darwin.tailscale (see modules/darwin/tailscale.nix)

  # Machine-specific network tools
  environment.systemPackages = with pkgs; [
    # Network diagnostics
    mtr
    iperf3
  ];
}
