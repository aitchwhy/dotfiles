# Darwin OrbStack configuration
# Container runtime with full reset on rebuild for sleep/wake stability
#
# KNOWN-GOOD VERSION: OrbStack 2.0.5 (January 2026)
# - Docker 29.1.3, Compose 2.40.3, Kubernetes 1.33.5
# - Rollback: brew install --cask orbstack@2.0.5 (if issues arise)
#
# IMPORTANT: This module does a FULL DOCKER RESET on every darwin-rebuild switch.
# All containers, images, volumes, and networks are deleted (unless in preserveVolumes).
# This ensures a clean slate and prevents sleep/wake SIGKILL issues.
{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    optionalString
    concatMapStringsSep
    ;
  cfg = config.modules.darwin.orbstack;
in
{
  options.modules.darwin.orbstack = {
    enable = mkEnableOption "OrbStack container runtime";

    fullResetOnRebuild = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Delete ALL Docker data (containers, images, volumes, networks) on rebuild.
        This ensures a completely clean slate and prevents sleep/wake issues.
        WARNING: All Docker data will be lost on every darwin-rebuild switch!
      '';
    };

    # Resource limits
    memoryMiB = mkOption {
      type = types.int;
      default = 32768; # 32 GB
      description = "Memory limit in MiB";
    };

    cpuPercent = mkOption {
      type = types.int;
      default = 800; # 8 cores
      description = "CPU limit as percentage (800 = 8 cores)";
    };

    # Features
    rosetta = mkOption {
      type = types.bool;
      default = true;
      description = "Use Rosetta for Intel code emulation";
    };

    networkBridge = mkOption {
      type = types.bool;
      default = true;
      description = "Allow direct container IP access from macOS";
    };

    hideVolume = mkOption {
      type = types.bool;
      default = false;
      description = "Hide OrbStack volume from Finder";
    };

    preserveVolumes = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "postgres_data" "redis_data" ];
      description = ''
        List of Docker volume names to preserve during full reset.
        These volumes will be backed up before reset and restored after.
        Only effective when fullResetOnRebuild is true.
      '';
    };
  };

  config = mkIf cfg.enable {
    # Input validation
    assertions = [
      {
        assertion = cfg.memoryMiB >= 4096 && cfg.memoryMiB <= 131072;
        message = "OrbStack memoryMiB must be between 4096 (4GB) and 131072 (128GB)";
      }
      {
        assertion = cfg.cpuPercent >= 100 && cfg.cpuPercent <= 3200;
        message = "OrbStack cpuPercent must be between 100 (1 core) and 3200 (32 cores)";
      }
      {
        assertion = lib.mod cfg.cpuPercent 100 == 0;
        message = "OrbStack cpuPercent must be a multiple of 100 (e.g., 100, 200, 800)";
      }
    ];

    # Pre-activation: Full Docker reset before any changes
    system.activationScripts.preActivation.text = optionalString cfg.fullResetOnRebuild ''
      # OrbStack full reset for clean rebuild
      if command -v orb &>/dev/null && command -v docker &>/dev/null; then
        echo "=== OrbStack Full Reset ==="

        ${optionalString (cfg.preserveVolumes != [ ]) ''
          # Backup preserved volumes
          BACKUP_DIR="/tmp/orbstack-volume-backup-$$"
          mkdir -p "$BACKUP_DIR"
          echo "Backing up preserved volumes to $BACKUP_DIR..."
          ${concatMapStringsSep "\n" (vol: ''
            if docker volume inspect "${vol}" &>/dev/null; then
              echo "  Backing up volume: ${vol}"
              docker run --rm -v "${vol}:/source" -v "$BACKUP_DIR:/backup" alpine tar czf "/backup/${vol}.tar.gz" -C /source . 2>/dev/null || true
            fi
          '') cfg.preserveVolumes}
        ''}

        # Stop all containers first
        if docker ps -q 2>/dev/null | grep -q .; then
          echo "Stopping all containers..."
          docker stop $(docker ps -q) 2>/dev/null || true
        fi

        # Delete all Docker data (containers, images, volumes, networks)
        echo "Deleting all Docker data..."
        orb delete docker --force 2>/dev/null || true

        # Wait for cleanup to complete
        sleep 3
        echo "Docker data cleared"
      fi
    '';

    # Post-activation: Configure and restart OrbStack
    system.activationScripts.postActivation.text = ''
      # OrbStack configuration and startup
      if command -v orb &>/dev/null; then
        echo "=== Configuring OrbStack ==="

        # Apply resource configuration
        orb config set memory_mib ${toString cfg.memoryMiB} 2>/dev/null || true
        orb config set cpu ${toString (cfg.cpuPercent / 100)} 2>/dev/null || true

        # Apply feature configuration
        orb config set rosetta ${if cfg.rosetta then "true" else "false"} 2>/dev/null || true
        orb config set network_bridge ${if cfg.networkBridge then "true" else "false"} 2>/dev/null || true
        orb config set mount_hide_shared ${if cfg.hideVolume then "true" else "false"} 2>/dev/null || true

        # Start OrbStack fresh
        echo "Starting OrbStack..."
        orb start 2>/dev/null || true

        # Wait for Docker to be ready (max 60s for fresh install)
        echo "Waiting for Docker daemon..."
        for i in $(seq 1 60); do
          if docker info &>/dev/null; then
            echo "Docker ready (took ''${i}s)"
            break
          fi
          if [ "$i" -eq 60 ]; then
            echo "WARNING: Docker not ready after 60s"
          fi
          sleep 1
        done

        ${optionalString (cfg.preserveVolumes != [ ]) ''
          # Restore preserved volumes
          BACKUP_DIR="/tmp/orbstack-volume-backup-$$"
          if [ -d "$BACKUP_DIR" ]; then
            echo "Restoring preserved volumes..."
            ${concatMapStringsSep "\n" (vol: ''
              if [ -f "$BACKUP_DIR/${vol}.tar.gz" ]; then
                echo "  Restoring volume: ${vol}"
                docker volume create "${vol}" 2>/dev/null || true
                docker run --rm -v "${vol}:/target" -v "$BACKUP_DIR:/backup" alpine tar xzf "/backup/${vol}.tar.gz" -C /target 2>/dev/null || true
              fi
            '') cfg.preserveVolumes}
            rm -rf "$BACKUP_DIR"
            echo "Volume restoration complete"
          fi
        ''}

        # Show final status
        echo "=== OrbStack Status ==="
        orb config show 2>/dev/null | grep -E "(memory|cpu|rosetta)" || true
        docker info 2>/dev/null | grep -E "(Server Version|Total Memory)" || true
      else
        echo "OrbStack not installed yet (will be available after Homebrew activation)"
      fi
    '';
  };
}
