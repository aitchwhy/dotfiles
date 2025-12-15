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
  # DNS SERVERS
  # ===========================================================================

  dns = {
    cloudflare = [
      "1.1.1.1"
      "1.0.0.1"
    ];
    google = [
      "8.8.8.8"
      "8.8.4.4"
    ];
    quad9 = [
      "9.9.9.9"
      "149.112.112.112"
    ];
  };
}
