# macOS (Darwin) system configuration module aggregator
{ config, lib, pkgs, ... }:

with lib;

{
  imports = [
    # UI
    ./dock.nix
    ./finder.nix

    # System
    ./system.nix
    ./keyboard.nix
    ./trackpad.nix
    ./kanata.nix

    # Applications
    ./safari.nix
    ./terminal.nix
    ./activity-monitor.nix
    ./xcode.nix

    # Activation scripts (apps without Homebrew casks)
    ./activation/wispr-flow.nix
  ];

  # Enable all darwin modules by default
  config = {
    modules.darwin = {
      dock.enable = mkDefault true;
      finder.enable = mkDefault true;
      system.enable = mkDefault true;
      keyboard.enable = mkDefault true;
      trackpad.enable = mkDefault true;
      kanata.enable = mkDefault true;
      safari.enable = mkDefault true;
      terminal.enable = mkDefault true;
      activityMonitor.enable = mkDefault true;
      xcode.enable = mkDefault true;

      # Apps (activation scripts)
      apps.wisprFlow.enable = mkDefault true;
    };

    # System packages - only essential system-level tools
    environment.systemPackages = with pkgs; [
      coreutils
      gnumake
      darwin.trash
      mas
    ];
  };
}
