# Network Configuration - hosts, DNS, Tailscale
#
# Centralized network configuration for consistent addressing.
{ lib }:
{
  # ===========================================================================
  # STANDARD HOSTS
  # ===========================================================================

  hosts = {
    localhost = "127.0.0.1";
    localIPv6 = "::1";
  };

  # ===========================================================================
  # TAILSCALE CONFIGURATION
  # ===========================================================================

  tailscale = {
    # Network interface name
    interface = "tailscale0";

    # CGNAT range used by Tailscale
    cidr = "100.64.0.0/10";

    # MagicDNS suffix (customize per tailnet)
    magicDnsSuffix = ".ts.net";
  };

  # ===========================================================================
  # DNS — NextDNS via macOS Encrypted DNS profile (DoH)
  #
  # Single provider. No manual DNS servers on interfaces.
  # Profile is generated and managed by modules/darwin/network.nix
  # ===========================================================================

  dns = {
    nextdns = {
      configId = "35a3c4";
      # Device name shown in NextDNS analytics dashboard
      # URL-encoded in the DoH endpoint
      deviceName = "Hank MBP";
    };
  };
}
