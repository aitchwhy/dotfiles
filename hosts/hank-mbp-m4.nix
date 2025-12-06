# MacBook Pro M4 specific configuration
# This file contains:
# - Machine-specific network configuration
# - Hardware-specific tools and optimizations
# - Machine-specific services (e.g., Tailscale)
{pkgs, ...}: {
  networking.hostName = "hank-mbp-m4";
  networking.computerName = "Hank's MacBook Pro";
  networking.localHostName = "hank-mbp-m4";

  system.stateVersion = 5;

  # Tailscale VPN - Use pre-built package from cache to avoid test failures
  # nixpkgs has a known issue with socket path lengths during tailscale tests
  services.tailscale.enable = true;
  services.tailscale.package = pkgs.tailscale.overrideAttrs (old: {
    doCheck = false;
  });

  # Machine-specific network tools
  environment.systemPackages = with pkgs; [
    # Network diagnostics
    mtr
    iperf3
  ];
}
