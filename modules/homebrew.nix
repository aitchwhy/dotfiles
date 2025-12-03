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

    # CLI tools
    brews = [
      "bitwarden-cli" # Bitwarden password manager CLI
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
      "antigravity" # Google's AI IDE
      "kaleidoscope" # Diff/merge tool

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
      "superhuman" # Email client
      "fathom" # AI meeting recorder

      # Productivity
      "raycast"
      "1password"
      "bitwarden" # Password manager
      "bartender"
      "cleanmymac"
      "iina"
      "keka"
      "setapp" # Setapp app store (Clop, LookAway, Downie, etc.)
      "fantastical" # Calendar (Flexibits)
      "cardhop" # Contacts (Flexibits)
      "todoist" # Task management
      "carbon-copy-cloner" # Backup utility
      "cleanshot" # Screenshot tool
      "a-better-finder-rename" # File renaming
      "clop" # Image/video optimizer

      # AI
      "claude" # Claude Desktop
      "chatgpt" # ChatGPT app

      # System Utilities
      "nikitabobko/tap/aerospace" # Window manager (from custom tap)
      "karabiner-elements" # Keyboard customization
      "hammerspoon" # macOS automation

      # Window/Gesture Management
      "swish" # Trackpad window gestures
      # "dropover" # Removed - cask no longer available

      # QuickLook Plugins (preview files in Finder)
      "qlmarkdown" # Markdown preview
      "syntax-highlight" # Code syntax highlighting
      "quicklook-json" # JSON preview
      "quicklook-csv" # CSV preview
      "qlstephen" # Plain text files without extension
      "qlvideo" # Video thumbnails/preview
      "webpquicklook" # WebP image preview
      "suspicious-package" # PKG installer preview

      # Fonts (needed for terminal/editor icons)
      "font-fira-code-nerd-font"
      "font-symbols-only-nerd-font"
    ];

    # Mac App Store apps
    masApps = {
      "Xcode" = 497799835;
      "Amphetamine" = 937984704; # Keep Mac awake
      "rcmd" = 1596283165; # App switcher (MAS only - no Homebrew cask)
      # "Pockity" = 1550027149; # Stripe dashboard - install manually from App Store
    };
  };
}
