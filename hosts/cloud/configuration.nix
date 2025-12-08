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

  # SOPS secrets configuration
  sops = {
    defaultSopsFile = ../../secrets/secrets.yaml;
    age.keyFile = "/var/lib/sops-nix/key.txt";
    secrets = {
      tailscale-auth = {
        owner = "root";
        group = "root";
        mode = "0400";
      };
      github-token = {
        owner = "hank";
        group = "users";
        mode = "0400";
      };
    };
  };

  # Tailscale configuration
  modules.nixos.services.tailscale = {
    enable = true;
    ssh = true;
    exitNode = false;
    authKeyFile = config.sops.secrets.tailscale-auth.path;
  };

  # Docker - disabled for minimal build, enable later
  # modules.nixos.services.docker = {
  #   enable = true;
  #   storageDriver = "overlay2";
  # };

  # Minimal packages - add more later
  environment.systemPackages = with pkgs; [
    git
    vim
    htop
    tmux
  ];

  # System state version
  system.stateVersion = "24.11";
}
