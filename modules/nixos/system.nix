# NixOS system configuration
# Boot, networking, and core system settings
{
  config,
  lib,
  ...
}: let
  inherit (lib) mkDefault mkOption types;
in {
  options.modules.nixos.system = {
    hostname = mkOption {
      type = types.str;
      default = "cloud-dev";
      description = "System hostname";
    };
  };

  config = {
    # Networking
    networking = {
      hostName = config.modules.nixos.system.hostname;
      useDHCP = mkDefault true;

      # Firewall is configured in security.nix
      firewall.enable = true;
    };

    # Boot configuration (for cloud VMs)
    boot = {
      loader = {
        # GRUB for cloud VMs (supports both BIOS and UEFI)
        grub = {
          enable = mkDefault true;
          device = mkDefault "nodev";
          efiSupport = mkDefault true;
          efiInstallAsRemovable = mkDefault true;
        };
        efi.canTouchEfiVariables = mkDefault false;
      };

      # Kernel parameters for cloud
      kernelParams = [
        "console=ttyS0"
        "console=tty1"
      ];

      # Clean /tmp on boot
      tmp.cleanOnBoot = true;
    };

    # Systemd settings
    systemd = {
      # Manager settings
      settings.Manager = {
        # Watchdog for automatic recovery
        RuntimeWatchdogSec = "30s";
        RebootWatchdogSec = "10m";
        # Service timeout
        DefaultTimeoutStopSec = "30s";
      };
    };

    # Services
    services = {
      # Enable QEMU guest agent for cloud VMs
      qemuGuest.enable = mkDefault true;

      # Time synchronization
      chrony.enable = true;

      # Disable X11/Wayland for headless server
      xserver.enable = false;
    };

    # Zram swap (useful for cloud VMs with limited RAM)
    zramSwap = {
      enable = true;
      algorithm = "zstd";
      memoryPercent = 50;
    };

    # Nix daemon configuration
    nix = {
      enable = true;

      # Automatic garbage collection
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 30d";
      };

      # Automatic store optimization
      optimise = {
        automatic = true;
        dates = ["weekly"];
      };
    };
  };
}
