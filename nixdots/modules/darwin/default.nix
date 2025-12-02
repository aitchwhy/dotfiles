# macOS (Darwin) system configuration module aggregator
{ config, lib, pkgs, ... }:

with lib;

{
  imports = [
    # UI components
    ./ui/dock.nix
    ./ui/finder.nix

    # System settings
    ./system/defaults.nix
    ./system/keyboard.nix
    ./system/trackpad.nix
    ./system/nix-optimizations.nix

    # Application settings
    ./apps/safari.nix
    ./apps/terminal.nix
    ./apps/activity-monitor.nix
    ./apps/xcode.nix
  ];

  # Enable all darwin modules by default
  config = {
    modules.darwin = {
      dock.enable = mkDefault true;
      finder.enable = mkDefault true;
      system.enable = mkDefault true;
      system.nix-optimizations.enable = mkDefault true;
      keyboard.enable = mkDefault true;
      trackpad.enable = mkDefault true;
      safari.enable = mkDefault true;
      terminal.enable = mkDefault true;
      activityMonitor.enable = mkDefault true;
      xcode.enable = mkDefault true;
    };

    # System packages - only essential system-level tools
    environment.systemPackages = with pkgs; [
      # Core system utilities
      coreutils
      gnumake

      # macOS specific system tools
      darwin.trash
      mas # Mac App Store CLI
    ];
  };
}
