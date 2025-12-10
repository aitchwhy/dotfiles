# NixOS user configuration
# User accounts and groups
{
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkDefault;
in {
  config = {
    # User accounts
    users.users.hank = {
      isNormalUser = true;
      description = "Hank Lee";
      home = "/home/hank";
      shell = pkgs.zsh;
      extraGroups = [
        "wheel" # sudo access
        "docker" # Docker access
        "networkmanager" # Network management
      ];

      # SSH authorized keys (can be overridden in host config)
      openssh.authorizedKeys.keys = [
        # Add your SSH public keys here, or use sops-nix
      ];
    };

    # Disable root login
    users.users.root.hashedPassword = "!"; # Locked

    # Enable mutable users for initial setup
    users.mutableUsers = mkDefault true;

    # Default shell
    programs.zsh.enable = true;

    # Groups
    users.groups = {
      docker = {};
    };

    # Home directory permissions
    security.pam.loginLimits = [
      {
        domain = "@wheel";
        type = "soft";
        item = "nofile";
        value = "524288";
      }
      {
        domain = "@wheel";
        type = "hard";
        item = "nofile";
        value = "1048576";
      }
    ];
  };
}
