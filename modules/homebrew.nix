# Homebrew configuration for macOS
# This file contains:
# - GUI applications installed via Homebrew Cask
# - Mac App Store applications
# - Apps not available in nixpkgs or requiring macOS-specific integration
{
  homebrew = {
    enable = true;

    # Auto-update on activation
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "uninstall"; # Less aggressive - won't remove apps installed outside Brewfile
    };

    # Essential taps only
    taps = [
      "nikitabobko/tap" # AeroSpace window manager
    ];

    # GUI Applications
    casks = [
      # Browsers
      "arc"
      "google-chrome"

      # Development
      "cursor"
      "orbstack"
      "proxyman"
      "tableplus"
      "warp"
      "fork" # Git GUI

      # Terminal
      "ghostty"

      # Design
      "figma"
      "obsidian"

      # Communication
      "discord"
      "slack"
      "zoom"
      "linear-linear" # Project management

      # Productivity
      "raycast"
      "1password"
      "bartender"
      "cleanmymac"
      "iina"
      "keka"
      "setapp" # Setapp app store (for ETA, etc.)

      # AI
      "claude" # Claude Desktop
      "chatgpt" # ChatGPT app

      # System Utilities
      "nikitabobko/tap/aerospace" # Window manager (from custom tap)
      "karabiner-elements" # Keyboard customization
      "hammerspoon" # macOS automation

      # Fonts (needed for terminal/editor icons)
      "font-fira-code-nerd-font"
      "font-symbols-only-nerd-font"
    ];

    # Mac App Store apps
    masApps = {
      "Xcode" = 497799835;
      "Amphetamine" = 937984704; # Keep Mac awake
      # "Pockity" = 1550027149; # Stripe dashboard - install manually from App Store
    };
  };
}
