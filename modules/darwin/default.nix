# macOS (Darwin) system configuration module aggregator
{
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkDefault;
in
{
  imports = [
    # UI
    ./dock.nix
    ./finder.nix

    # System
    ./system.nix
    ./keyboard.nix
    ./screenshots.nix
    ./spaces.nix
    ./window-manager.nix
    ./input-devices.nix
    ./tailscale.nix
    ./colima.nix
    ./secrets.nix
    ./login-items.nix

    # Services
    ./services/evolution-agent.nix

    # Apple Applications
    ./terminal.nix
    ./activity-monitor.nix
    ./xcode.nix
    ./safari.nix
    ./mail.nix
    ./calendar.nix
    ./control-center.nix
    ./communication.nix

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
      screenshots.enable = mkDefault true;
      screenshots.disableSystemHotkeys = mkDefault true; # Free Cmd+Shift+3/4/5 for CleanShot X
      spaces.enable = mkDefault true;
      windowManager.enable = mkDefault true;
      inputDevices.enable = mkDefault true;
      tailscale.enable = mkDefault true;
      colima.enable = mkDefault false; # Replaced by OrbStack
      secrets.enable = mkDefault true;
      terminal.enable = mkDefault true;
      activityMonitor.enable = mkDefault true;
      xcode.enable = mkDefault true;
      safari.enable = mkDefault true;
      mail.enable = mkDefault true;
      calendar.enable = mkDefault true;
      controlCenter.enable = mkDefault true;
      communication.enable = mkDefault true;
      loginItems.enable = mkDefault true;

      # Services
      evolutionAgent.enable = mkDefault true;

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
