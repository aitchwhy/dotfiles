{ config, pkgs, lib, ... }:

{
  # Nix configuration
  nix = {
    # Enable flakes and new 'nix' command
    extraOptions = ''
      experimental-features = nix-command flakes
      warn-dirty = false
      keep-outputs = true
      keep-derivations = true
      fallback = true
    '';

    # Garbage collection settings
    gc = {
      automatic = true;
      interval = { 
        Hour = 24;
        Minute = 0;
      };
      options = "--delete-older-than 30d";
    };

    # Binary cache settings
    settings = {
      # Enable binary caches
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];

      # Optimization settings
      auto-optimise-store = true;
      trusted-users = [ "@admin" ];
      max-jobs = "auto";
      cores = 0;
      sandbox = true;
    };

    # Registry settings
    registry = {
      nixpkgs.flake = pkgs.path;
    };
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Configure channels
  nixpkgs.config = {
    packageOverrides = pkgs: {
      unstable = import <nixpkgs-unstable> {
        config = config.nixpkgs.config;
      };
    };
  };

  # System packages
  environment.systemPackages = with pkgs; [
    # Basic utilities
    coreutils
    curl
    wget
    git

    # Nix tools
    nixfmt
    alejandra
    nil # Nix LSP
    
    # System tools
    gnused
    gnutar
    gawk
    
    # Development tools
    gcc
    gnumake
  ];

  # System-wide environment variables
  environment.variables = {
    # Nix configuration directory
    NIX_PATH = lib.mkForce "nixpkgs=${pkgs.path}\$\{NIX_PATH:+:$NIX_PATH}";
    
    # Editor settings
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  # System-wide shell configuration
  environment.shells = with pkgs; [
    bash
    zsh
  ];

  # Default shell
  environment.loginShell = pkgs.zsh;

  # System activation scripts
  system.activationScripts.postActivation.text = ''
    # Reload system settings
    /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
  '';
}
