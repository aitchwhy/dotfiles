# Cloud development server configuration
# Target: Vultr/Hetzner/DigitalOcean VPS in US East
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    ./disk-config.nix
  ];

  # System identification
  modules.nixos.system.hostname = "cloud";

  # Tailscale configuration
  modules.nixos.services.tailscale = {
    enable = true;
    ssh = true;
    exitNode = false;
    # Auth key provided via sops-nix at deployment time
    # authKeyFile = config.sops.secrets.tailscale-auth.path;
  };

  # Docker configuration
  modules.nixos.services.docker = {
    enable = true;
    storageDriver = "overlay2";
  };

  # SOPS secrets configuration
  # Uncomment when secrets are set up:
  # sops = {
  #   defaultSopsFile = ../../secrets/secrets.yaml;
  #   age.keyFile = "/var/lib/sops-nix/key.txt";
  #   secrets = {
  #     tailscale-auth = {
  #       owner = "root";
  #       group = "root";
  #       mode = "0400";
  #     };
  #     github-token = {
  #       owner = "hank";
  #       group = "users";
  #       mode = "0400";
  #     };
  #   };
  # };

  # Cloud-specific settings
  boot = {
    # Most cloud providers use GRUB
    loader.grub = {
      enable = true;
      device = "nodev";
      efiSupport = true;
      efiInstallAsRemovable = true;
    };
  };

  # Network configuration
  networking = {
    useDHCP = true;
    interfaces = { }; # Let DHCP configure interfaces
  };

  # Development tools (in addition to modules/nixos packages)
  environment.systemPackages = with pkgs; [
    # Claude Code dependencies
    nodejs_22
    bun

    # Language toolchains
    python312
    uv
    go

    # Additional development tools
    lazygit
    delta
    eza
    bat
    zoxide

    # Persistent session tools
    zellij
    mosh
  ];

  # Enable user lingering for persistent user services
  systemd.tmpfiles.rules = [
    "f /var/lib/systemd/linger/hank 0644 root root -"
  ];

  # Increase limits for development
  boot.kernel.sysctl = {
    "fs.inotify.max_user_watches" = 524288;
    "fs.inotify.max_user_instances" = 1024;
  };

  # System state version
  system.stateVersion = "24.11";
}
