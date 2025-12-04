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
    ];

    # CLI tools
    brews = [
      "bitwarden-cli" # Bitwarden password manager CLI
    ];

    # GUI Applications
    casks = [
      # Browsers
      "google-chrome"

      # Development
      "cursor"
      "orbstack"
      "proxyman"
      "tableplus"
      "antigravity" # Google's AI IDE
      "kaleidoscope" # Diff/merge tool

      # Terminal
      "ghostty"

      # Design
      "figma"
      "obsidian"

      # Communication
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
      "todoist-app" # Task management (renamed from todoist)
      "carbon-copy-cloner" # Backup utility
      "cleanshot" # Screenshot tool
      "a-better-finder-rename" # File renaming
      "clop" # Image/video optimizer

      # AI
      "claude" # Claude Desktop
      "chatgpt" # ChatGPT app

      # System Utilities
      "karabiner-elements" # DriverKit driver for Kanata
      "hammerspoon" # macOS automation
      "homerow" # Keyboard shortcuts for screen elements

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
