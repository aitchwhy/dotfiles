{ config, pkgs, lib, ... }:

{
  nix = {
    settings = {
      # Enable flakes and new 'nix' command
      experimental-features = [ "nix-command" "flakes" ];
      
      # Avoid unwanted garbage collection when using nix-direnv
      keep-outputs = true;
      keep-derivations = true;
      
      # Avoid linking issues on Darwin
      auto-optimise-store = false;
      
      # Binary cache configuration
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
      
      # Trusted users for nix operations
      trusted-users = [ "@admin" ];
      
      # Maximum number of concurrent jobs
      max-jobs = "auto";
      
      # Enable system features
      system-features = [ "big-parallel" "kvm" "nixos-test" ];
      
      # Garbage collection settings
      auto-optimise-store = true;
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 30d";
      };
    };

    # Configure registry
    registry.nixpkgs.flake = pkgs.nixpkgs;

    # Nix path
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
