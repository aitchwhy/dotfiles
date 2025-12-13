{
  lib,
  pkgs,
  ...
}:
{
  # System-level Nix configuration
  nix = {
    # On Darwin: Determinate Nix installer manages the daemon externally
    # On NixOS: Let system.nix manage nix.enable
    enable = lib.mkIf pkgs.stdenv.isDarwin false;

    # Core settings
    package = pkgs.nix;
    settings = {
      # Enable experimental features for modern development
      # Note: cgroups and auto-allocate-uids are Linux-only, darwin uses different isolation
      experimental-features = [
        "nix-command"
        "flakes"
        "ca-derivations"
      ];

      # Trust settings
      trusted-users = [ "@wheel" ] ++ (lib.optionals pkgs.stdenv.isDarwin [ "@admin" ]);

      # Binary caches - expanded for better coverage
      # To add personal cache: cachix create hank-dotfiles && cachix use hank-dotfiles
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
        # Personal cache: add key here after running `cachix create hank-dotfiles`
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
      # auto-optimise-store removed - use nix.optimise.automatic instead
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

    # Automatic garbage collection and optimization
    # Darwin: Managed by Determinate Nix installer (nix.enable = false)
    # NixOS: Configured here and in modules/nixos/system.nix
    gc = lib.mkIf pkgs.stdenv.isLinux {
      automatic = true;
      options = lib.mkDefault "--delete-older-than 7d";
    };

    # Automatic store optimization (hardlinks identical files)
    # Only on NixOS - Darwin uses Determinate Nix daemon
    optimise.automatic = lib.mkIf pkgs.stdenv.isLinux true;

    # nixbuild.net distributed builder (x86_64-linux builds)
    # Enable with: modules.home.tools.nixbuild.enable = true (for SSH config)
    # Requires NIXBUILD_TOKEN secret in GitHub Actions
    distributedBuilds = true;
    buildMachines = [
      {
        hostName = "eu.nixbuild.net";
        system = "x86_64-linux";
        maxJobs = 100;
        supportedFeatures = [
          "benchmark"
          "big-parallel"
        ];
        # SSH key configured via modules/home/tools/nixbuild.nix
      }
    ];

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

      # Post-build logging hook
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
    '';
  };

  # Nixpkgs configuration
  nixpkgs.config = {
    allowUnfree = true;
    allowBroken = false;
    contentAddressedByDefault = false;
    checkMeta = true;
  };

  # Darwin-specific settings
  ids.gids.nixbld = lib.mkIf pkgs.stdenv.isDarwin 350;

  # System-wide environment variables for Nix
  environment.variables = {
    NIX_SHELL_PRESERVE_PROMPT = "1"; # Preserve shell prompt in nix-shell
  };
}
