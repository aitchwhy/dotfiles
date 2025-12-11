# Disko disk configuration for cloud VMs
# Supports both BIOS and UEFI boot
{ lib, ... }:
{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        # Device path - will be set during deployment
        # Common values: /dev/sda, /dev/vda, /dev/nvme0n1
        device = lib.mkDefault "/dev/sda";
        content = {
          type = "gpt";
          partitions = {
            # BIOS boot partition (for legacy boot compatibility)
            boot = {
              size = "1M";
              type = "EF02"; # BIOS boot
            };

            # EFI System Partition
            ESP = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [
                  "defaults"
                  "umask=0077"
                ];
              };
            };

            # Root partition (remainder of disk)
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
                mountOptions = [
                  "defaults"
                  "noatime"
                  "discard"
                ];
              };
            };
          };
        };
      };
    };
  };
}
