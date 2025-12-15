# NixOS SSH server configuration
# Hardened OpenSSH settings
{ lib, ... }:
let
  # Centralized configuration - see lib/config/
  cfg' = import ../../../lib/config { inherit lib; };
  ports = cfg'.ports;
in
{
  config = {
    services.openssh = {
      enable = true;

      settings = {
        # Security settings
        PasswordAuthentication = false;
        PermitRootLogin = "no";
        PubkeyAuthentication = true;
        X11Forwarding = false;
        PermitEmptyPasswords = false;
        ChallengeResponseAuthentication = false;

        # Use strong algorithms only
        KexAlgorithms = [
          "curve25519-sha256"
          "curve25519-sha256@libssh.org"
          "diffie-hellman-group16-sha512"
          "diffie-hellman-group18-sha512"
        ];
        Ciphers = [
          "chacha20-poly1305@openssh.com"
          "aes256-gcm@openssh.com"
          "aes128-gcm@openssh.com"
        ];
        Macs = [
          "hmac-sha2-512-etm@openssh.com"
          "hmac-sha2-256-etm@openssh.com"
        ];

        # Session settings
        ClientAliveInterval = 300;
        ClientAliveCountMax = 2;
        MaxAuthTries = 3;
        MaxSessions = 10;
        LoginGraceTime = 30;
      };

      # Extra configuration
      extraConfig = ''
        # Restrict to specific users
        AllowUsers hank

        # Disable unused features
        AllowAgentForwarding yes
        AllowTcpForwarding yes
        GatewayPorts no
        PermitTunnel no

        # Banner (optional)
        # Banner /etc/ssh/banner

        # Logging
        LogLevel VERBOSE
        SyslogFacility AUTH
      '';

      # Listen on all interfaces (Tailscale will handle security)
      ports = [ ports.infrastructure.ssh ];
      openFirewall = true;
    };

    # SSH client configuration
    programs.ssh = {
      startAgent = true;
      extraConfig = ''
        # Keep connections alive
        ServerAliveInterval 60
        ServerAliveCountMax 3

        # Reuse connections
        ControlMaster auto
        ControlPath ~/.ssh/sockets/%r@%h-%p
        ControlPersist 600

        # Security
        HashKnownHosts yes
        StrictHostKeyChecking ask
      '';
    };

    # Create SSH socket directory
    systemd.tmpfiles.rules = [
      "d /home/hank/.ssh/sockets 0700 hank users -"
    ];
  };
}
