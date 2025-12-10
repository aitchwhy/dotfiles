# NixOS Docker configuration
# Container runtime for development
{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit
    (lib)
    mkDefault
    mkOption
    types
    mkIf
    ;
in {
  options.modules.nixos.services.docker = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Docker container runtime";
    };

    storageDriver = mkOption {
      type = types.str;
      default = "overlay2";
      description = "Docker storage driver";
    };
  };

  config = mkIf config.modules.nixos.services.docker.enable {
    # Docker daemon
    virtualisation.docker = {
      enable = true;
      storageDriver = config.modules.nixos.services.docker.storageDriver;

      # Auto-prune old images
      autoPrune = {
        enable = true;
        dates = "weekly";
        flags = ["--all"];
      };

      # Daemon configuration
      daemon.settings = {
        # Use local DNS
        dns = [
          "1.1.1.1"
          "8.8.8.8"
        ];

        # Logging
        log-driver = "json-file";
        log-opts = {
          max-size = "10m";
          max-file = "3";
        };

        # Features
        features = {
          buildkit = true;
        };

        # Default address pools for containers
        default-address-pools = [
          {
            base = "172.17.0.0/12";
            size = 24;
          }
        ];
      };
    };

    # Docker CLI tools
    environment.systemPackages = with pkgs; [
      docker-compose
      docker-buildx
      dive # Docker image explorer
      lazydocker # TUI for Docker
    ];

    # Docker group (already defined in users.nix)
    # users.groups.docker = {};

    # Rootless Docker option (more secure but less compatible)
    # virtualisation.docker.rootless = {
    #   enable = true;
    #   setSocketVariable = true;
    # };
  };
}
