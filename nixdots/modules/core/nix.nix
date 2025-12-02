{ config, lib, pkgs, ... }:
{
  # System-level Nix configuration
  nix = {
    # Core settings
    package = pkgs.nix;
    settings = {
      # Enable experimental features for modern development
      experimental-features = [
        "nix-command"
        "flakes"
        "ca-derivations"
        "auto-allocate-uids"
        "cgroups"
      ];

      # Trust settings
      trusted-users = [ "@wheel" ] ++ (lib.optionals pkgs.stdenv.isDarwin [ "@admin" ]);

      # Binary caches - expanded for better coverage
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://devenv.cachix.org"
        "https://cuda-maintainers.cachix.org"
        "https://nixpkgs-python.cachix.org"
        "https://nixpkgs-unfree.cachix.org"
        "https://numtide.cachix.org"
        "https://nix-on-droid.cachix.org"
        "https://mic92.cachix.org"
      ];

      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
        "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
        "nixpkgs-python.cachix.org-1:hxjI7pFxTyuTHn2NkvWCrAUcNZLNS3ZAvfYNuYifcEU="
        "nixpkgs-unfree.cachix.org-1:hqvoInulhbV4nJ9yJOEr+4wxhDV4xq2d1DK7S6Nj6rs="
        "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
        "nix-on-droid.cachix.org-1:56snoMJTXmDRC1Ei24CmKoUqvHJ9XCp+nidK7qkMQrU="
        "mic92.cachix.org-1:gi8IhgiT3CYZnJsaW7fxznzTkMUOn1RY4GmXdT/nXYQ="
      ];

      # Performance tuning
      max-jobs = "auto";
      cores = 0; # Use all available cores
      max-substitution-jobs = 128; # Parallel downloads
      http-connections = 128; # Concurrent HTTP connections

      # Build settings
      sandbox = true;
      sandbox-fallback = false; # Fail rather than disable sandbox
      auto-optimise-store = true; # Deduplicate store files
      min-free = 5368709120; # 5GB minimum free space
      max-free = 10737418240; # 10GB to free when running GC

      # Developer experience
      keep-outputs = true; # Keep build outputs for debugging
      keep-derivations = true; # Keep .drv files
      fallback = true; # Build from source if binary cache fails
      warn-dirty = false; # Don't warn about dirty git trees in flakes
      accept-flake-config = true; # Accept flake configurations

      # Error handling
      log-lines = 50; # Show more context on errors
      show-trace = true; # Show full error traces

      # Flake settings
      flake-registry = "https://github.com/NixOS/flake-registry/raw/master/flake-registry.json";

      # Network settings
      connect-timeout = 5; # Faster timeout for unresponsive substituters
      download-attempts = 5; # Retry failed downloads
      stalled-download-timeout = 90; # Wait longer for stalled downloads
      http2 = true; # Enable HTTP/2 for better performance

      # Security
      allowed-users = [ "*" ]; # All users can use Nix
      require-sigs = true; # Require signatures on substitutes

      # Build user settings (Darwin)
      build-users-group = lib.mkIf pkgs.stdenv.isDarwin "nixbld";

      # Additional performance settings
      narinfo-cache-negative-ttl = 3600; # Cache missing paths for 1 hour
      narinfo-cache-positive-ttl = 86400; # Cache found paths for 24 hours

      # Connection pooling for better performance
      keep-env-derivations = true;
      keep-failed = true; # Keep failed builds for debugging

      # Build performance
      build-poll-interval = 1; # Check build status more frequently
    };

    # Garbage collection - balanced for development and caching
    gc = {
      automatic = true;
      options = "--delete-older-than 30d --max-freed $((100 * 1024**3))"; # 30 days or 100GB max
      dates = lib.mkIf pkgs.stdenv.isLinux "weekly";
      interval = lib.mkIf pkgs.stdenv.isDarwin {
        Hour = 3;
        Minute = 0;
        Weekday = 0; # Sunday
      };
    };

    # Store optimization
    optimise = {
      automatic = true;
      dates = lib.mkIf pkgs.stdenv.isLinux [ "weekly" ];
      interval = lib.mkIf pkgs.stdenv.isDarwin {
        Hour = 4;
        Minute = 0;
        Weekday = 0; # Sunday
      };
    };

    # Extra Nix configuration
    extraOptions = ''
      # Improve build performance
      builders-use-substitutes = true

      # Better diff output
      diff-hook = ${pkgs.diffutils}/bin/diff -u

      # Prevent Nix from hogging all resources
      max-silent-time = 3600  # 1 hour
      timeout = 86400  # 24 hours max build time

      # Better error messages
      pure-eval = false  # Allow access to env vars in repl
      restrict-eval = false  # Allow unrestricted evaluation

      # Flake UX improvements
      bash-prompt-prefix = (nix:$name)\040

      # Cache warming hooks
      pre-build-hook = 
      post-build-hook = ${pkgs.writeScript "nix-post-build-hook" ''
        #!/bin/sh
        set -euf
        export IFS=' '
        
        # Log builds for cache analysis
        if [ -w /tmp ] || [ -w /var/tmp ]; then
          LOG_DIR="''${TMPDIR:-/tmp}"
          echo "Built: $OUT_PATHS" >> "$LOG_DIR/nix-builds.log" 2>/dev/null || true
        fi
      ''}

      # Additional experimental features
      plugin-files =
    '';

    # Configure Nix daemon
    daemonIOLowPriority = true;
    daemonCPUSchedPolicy = lib.mkIf pkgs.stdenv.isLinux "idle";
  };

  # Nixpkgs configuration
  nixpkgs = {
    config = {
      allowUnfree = true;
      allowBroken = false;

      # Package overrides for better defaults
      packageOverrides = _pkgs: {
        # Add any global package overrides here
      };

      # Permit specific insecure packages if needed
      permittedInsecurePackages = [
        # "package-name-version"
      ];

      # Additional config
      contentAddressedByDefault = false; # Not ready for prime time
      checkMeta = true; # Check package metadata
    };

    # System features
    overlays = [
      # Add any global overlays here
    ];
  };

  # Darwin-specific settings
  ids.gids.nixbld = lib.mkIf pkgs.stdenv.isDarwin 350;

  # System-wide environment variables for Nix
  environment.variables = {
    NIX_SHELL_PRESERVE_PROMPT = "1"; # Preserve shell prompt in nix-shell
  };
}
