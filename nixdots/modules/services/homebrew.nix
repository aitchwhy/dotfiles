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
      cleanup = "zap"; # Remove unneeded files and downloads
    };

    # Essential taps only
    taps = [
      "homebrew/cask-versions" # For beta versions
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

      # Design
      "figma"
      "obsidian"

      # Communication
      "discord"
      "slack"
      "zoom"

      # Productivity
      "raycast"
      "1password"
      "bartender"
      "cleanmymac"
      "iina"
      "keka"
    ];

    # Mac App Store apps
    masApps = {
      "Xcode" = 497799835;
      "Amphetamine" = 937984704; # Keep Mac awake
      "Pockity" = 1550027149; # Stripe dashboard
    };
  };
}
