# Colima container runtime for macOS Tahoe
# Uses Apple Virtualization.framework (VZ) + VirtioFS for native performance
# Replaces OrbStack which has Tahoe 26.1 stability issues (GitHub #2222)
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
    ;
  cfg = config.modules.darwin.colima;
in
{
  options.modules.darwin.colima = {
    enable = mkEnableOption "Colima container runtime with VZ";

    cpu = mkOption {
      type = types.int;
      default = 6;
      description = "Number of CPU cores for the VM";
    };

    memory = mkOption {
      type = types.int;
      default = 16;
      description = "Memory in GB for the VM";
    };

    disk = mkOption {
      type = types.int;
      default = 60;
      description = "Disk size in GB for the VM";
    };

    networkAddress = mkOption {
      type = types.bool;
      default = true;
      description = "Enable routable container IP addresses (like OrbStack)";
    };
  };

  config = mkIf cfg.enable {
    # Input validation
    assertions = [
      {
        assertion = cfg.cpu >= 1 && cfg.cpu <= 16;
        message = "Colima cpu must be between 1 and 16";
      }
      {
        assertion = cfg.memory >= 2 && cfg.memory <= 64;
        message = "Colima memory must be between 2GB and 64GB";
      }
      {
        assertion = cfg.disk >= 10 && cfg.disk <= 500;
        message = "Colima disk must be between 10GB and 500GB";
      }
    ];

    # Pre-activation: Stop OrbStack if migrating
    system.activationScripts.preActivation.text = ''
      # Migration cleanup: Stop OrbStack if present
      if command -v orb &>/dev/null; then
        echo "=== OrbStack Migration Cleanup ==="
        orb stop 2>/dev/null || true
      fi
    '';

    # Post-activation: Configure and start Colima
    system.activationScripts.postActivation.text = ''
      echo "=== Colima Container Runtime ==="

      if ! command -v colima &>/dev/null; then
        echo "Colima not installed yet - run darwin-rebuild switch"
        exit 0
      fi

      # Check if Colima is already running with correct config
      if colima status 2>/dev/null | grep -q "Running"; then
        echo "Colima already running"
        docker info &>/dev/null && echo "✓ Docker ready"
        exit 0
      fi

      # Start Colima with VZ + VirtioFS
      echo "Starting Colima VZ..."
      colima start \
        --vm-type vz \
        --mount-type virtiofs \
        ${optionalString cfg.networkAddress "--network-address"} \
        --cpu ${toString cfg.cpu} \
        --memory ${toString cfg.memory} \
        --disk ${toString cfg.disk} \
        2>&1 || {
          echo "ERROR: Colima start failed"
          exit 1
        }

      # Wait for Docker to be ready
      echo "Waiting for Docker daemon..."
      for i in $(seq 1 60); do
        if docker info &>/dev/null; then
          echo "✓ Docker ready (took ''${i}s)"
          break
        fi
        if [ "$i" -eq 60 ]; then
          echo "WARNING: Docker not ready after 60s"
        fi
        sleep 1
      done

      # Show status
      echo "=== Colima Status ==="
      colima status 2>/dev/null || true
    '';
  };
}
