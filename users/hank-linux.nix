# Linux user configuration
# This file adapts the macOS configuration for NixOS/Linux
# Disables macOS-specific modules while keeping cross-platform tools
{ pkgs, ... }:
{
  # Import home modules
  imports = [ ../modules/home ];

  # User identity (Linux paths)
  home = {
    username = "hank";
    homeDirectory = "/home/hank";
    stateVersion = "26.05";
  };

  # Git configuration
  modules.home.tools.git = {
    userName = "Hank Lee";
    userEmail = "hank.lee.qed@gmail.com";
  };

  # Disable macOS-specific modules
  modules.home.apps = {
    ghostty.enable = false; # Uses macOS-specific binary
    kanata.enable = false; # Keyboard remapper (macOS DriverKit)
    bartender.enable = false; # macOS menu bar organizer
    raycast.enable = false; # macOS launcher
    homerow.enable = false; # macOS keyboard shortcuts
    betterdisplay.enable = false; # macOS display management (DDC, HiDPI)
    keyboardLayout.enable = false; # macOS keyboard layout
    defaultApps.enable = false; # macOS default app associations
    cursor.enable = false; # macOS GUI editor (use remote SSH instead)
    claude.enable = false; # Claude Desktop (macOS GUI app)

    # Keep cross-platform modules
    agents.enable = true; # AI agent configs (Claude Code, Gemini CLI)
    misc.enable = true;
  };

  # Packages managed by modules/home/packages/
  # - common.nix: Cross-platform tools (cloud, k8s, languages, databases)
  # - linux.nix: Linux-specific (xclip, wl-clipboard)

  # Language-specific configurations
  home.sessionVariables = {
    GOPATH = "$HOME/go";
    CARGO_HOME = "$HOME/.cargo";
    RUSTUP_HOME = "$HOME/.rustup";
    PNPM_HOME = "$HOME/.pnpm";
  };

  home.sessionPath = [
    "$GOPATH/bin"
    "$CARGO_HOME/bin"
    "$PNPM_HOME"
    "$HOME/.local/bin"
  ];
}
