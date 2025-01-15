{ config, pkgs, lib, ... }: {
  nix = {
    settings = {
      # Enable flakes and new 'nix' command
      experimental-features = [ "nix-command" "flakes" ];
      
      # Maximize build parallelization
      max-jobs = "auto";
      cores = 0;
      
      # Keep build dependencies around
      keep-derivations = true;
      keep-outputs = true;
      
      # Cache settings
      substituters = [
        "https://cache.nixos.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ];
      
      # Trusted users
      trusted-users = [ "@admin" ];
      
      # Optimization settings
      auto-optimise-store = true;
      warn-dirty = false;
    };

    # Garbage collection settings
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };

    # Registry settings
    registry.nixpkgs.flake = pkgs.nixpkgs;

    # Set path
    nixPath = [ 
      "nixpkgs=${pkgs.nixpkgs}"
      "/nix/var/nix/profiles/per-user/root/channels"
    ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Auto upgrade nix package and the daemon service
  services.nix-daemon.enable = true;
}