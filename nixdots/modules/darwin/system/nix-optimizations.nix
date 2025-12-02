{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.darwin.system.nix-optimizations;
in
{
  options.modules.darwin.system.nix-optimizations = {
    enable = mkEnableOption "Darwin-specific Nix optimizations for caching and performance";
  };

  config = mkIf cfg.enable {
    nix = {
      # macOS-specific optimizations
      settings = {
        # Local binary cache for offline work
        substituters = mkAfter [
          "file:///var/cache/nix-binary-cache"
        ];

        # Optimize for Apple Silicon
        system-features = [ "nixos-test" "benchmark" "big-parallel" "kvm" "apple-virt" ];

        # macOS-specific build settings
        sandbox = true;
        sandbox-fallback = false;

        # Increase limits for better performance on modern Macs
        narinfo-cache-positive-ttl = 86400; # 24 hours
        narinfo-cache-negative-ttl = 3600; # 1 hour

        # Network optimization for macOS
        http2 = true;

        # Store optimization
        auto-optimise-store = true;
        min-free = 5 * 1024 * 1024 * 1024; # 5GB
        max-free = 50 * 1024 * 1024 * 1024; # 50GB

        # Build cache settings
        keep-failed = true;
        keep-going = true;

        # Parallel building
        max-silent-time = 3600; # 1 hour
        timeout = 86400; # 24 hours
      };

      # Garbage collection configuration
      gc = {
        automatic = true;
        interval = { Weekday = 7; }; # Weekly on Sunday
        options = "--delete-older-than 30d";
      };

      # Store optimization
      optimise = {
        automatic = true;
        dates = [ "weekly" ];
      };

      # Extra options for macOS
      extraOptions = ''
        # Enable content-addressed derivations
        experimental-features = nix-command flakes ca-derivations
        
        # Increase daemon priority on macOS
        build-cores = 0
        
        # Better error messages
        show-trace = true
        
        # Cache build logs
        compress-build-log = true
        
        # macOS-specific security settings
        allowed-impure-host-deps = /System/Library /usr/lib /dev /bin/sh
        
        # Enable post-build-hook for cache population
        post-build-hook = ${pkgs.writeScript "nix-post-build-hook" ''
          #!/bin/sh
          set -euf
          export IFS=' '
          
          # Copy to local binary cache if it exists
          if [ -d /var/cache/nix-binary-cache ]; then
            echo "Copying $OUT_PATHS to local binary cache..." >&2
            exec ${config.nix.package}/bin/nix copy --to file:///var/cache/nix-binary-cache $OUT_PATHS
          fi
        ''}
      '';
    };

    # Create local binary cache directory
    system.activationScripts.postUserActivation.text = mkAfter ''
      echo "Setting up local Nix binary cache..." >&2
      if [ ! -d /var/cache/nix-binary-cache ]; then
        sudo mkdir -p /var/cache/nix-binary-cache
        sudo chown -R $(whoami):staff /var/cache/nix-binary-cache
        sudo chmod -R 755 /var/cache/nix-binary-cache
      fi
    '';

    # Environment variables for better performance
    environment.variables = {
      NIX_CONNECT_TIMEOUT = "10";
      NIX_STALLED_DOWNLOAD_TIMEOUT = "300";
    };

    # Launchd job for periodic cache warming
    launchd.daemons.nix-cache-warmer = {
      script = ''
        ${config.nix.package}/bin/nix-store --realise --add-root /var/cache/nix-gcroots/darwin-system \
          ${config.system.build.toplevel}
        
        ${config.nix.package}/bin/nix-store --realise --add-root /var/cache/nix-gcroots/home-manager \
          /nix/var/nix/profiles/per-user/*/home-manager || true
      '';

      serviceConfig = {
        StartCalendarInterval = [
          { Hour = 3; Minute = 0; } # Daily at 3 AM
        ];
        StandardOutPath = "/var/log/nix-cache-warmer.log";
        StandardErrorPath = "/var/log/nix-cache-warmer.log";
      };
    };
  };
}
