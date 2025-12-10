# NixOS security configuration
# Firewall, fail2ban, and system hardening
{
  lib,
  ...
}:
let
  inherit (lib) mkDefault;
in
{
  config = {
    # Firewall configuration
    networking.firewall = {
      enable = true;
      allowPing = true;

      # Only allow SSH (Tailscale handles secure access)
      allowedTCPPorts = [ 22 ];
      allowedUDPPorts = [
        41641 # Tailscale
      ];

      # Trust Tailscale interface
      trustedInterfaces = [ "tailscale0" ];

      # Log dropped packets (useful for debugging)
      logRefusedConnections = mkDefault false;
    };

    # Fail2ban for SSH brute-force protection
    services.fail2ban = {
      enable = true;
      maxretry = 5;
      bantime = "1h";
      bantime-increment = {
        enable = true;
        maxtime = "48h";
        factor = "4";
      };
      jails = {
        sshd = {
          settings = {
            enabled = true;
            port = "ssh";
            filter = "sshd";
            maxretry = 3;
            findtime = "10m";
            bantime = "1h";
          };
        };
      };
    };

    # Security hardening
    security = {
      # Audit logging
      auditd.enable = false; # Disable for cloud (noisy)
      audit.enable = false;

      # Sudo configuration
      sudo = {
        enable = true;
        wheelNeedsPassword = true;
        extraRules = [
          {
            groups = [ "wheel" ];
            commands = [
              {
                command = "/run/current-system/sw/bin/nixos-rebuild";
                options = [ "NOPASSWD" ];
              }
              {
                command = "/run/current-system/sw/bin/systemctl";
                options = [ "NOPASSWD" ];
              }
            ];
          }
        ];
      };

      # Polkit
      polkit.enable = true;

      # Hardened kernel parameters
      protectKernelImage = true;
    };

    # Boot security
    boot = {
      # Disable kernel module loading after boot
      kernelModules = [ ];
      extraModulePackages = [ ];

      # Kernel hardening
      kernel.sysctl = {
        # Network hardening
        "net.ipv4.conf.all.rp_filter" = 1;
        "net.ipv4.conf.default.rp_filter" = 1;
        "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
        "net.ipv4.conf.all.accept_redirects" = 0;
        "net.ipv4.conf.default.accept_redirects" = 0;
        "net.ipv4.conf.all.secure_redirects" = 0;
        "net.ipv4.conf.default.secure_redirects" = 0;
        "net.ipv6.conf.all.accept_redirects" = 0;
        "net.ipv6.conf.default.accept_redirects" = 0;

        # Disable IP forwarding (not a router)
        "net.ipv4.ip_forward" = 0;
        "net.ipv6.conf.all.forwarding" = 0;
      };
    };

    # Environment hardening
    environment.memoryAllocator.provider = "libc"; # scudo causes issues
  };
}
