# Homebrew configuration for macOS
# Single source of truth for GUI applications
# - Homebrew Casks: GUI apps not in nixpkgs
# - Mac App Store: Apps only available via MAS
# - Setapp apps are managed by Setapp.app itself
{
  homebrew = {
    enable = true;

    # Auto-update on activation
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "uninstall"; # Remove apps not in config
    };

    # Taps (formula repositories)
    taps = [
      "depot/tap" # Required for Depot CLI
    ];

    # CLI tools (most in home.packages via Nix)
    # OrbStack provides docker, docker-compose, and credential helpers
    brews = [
      "depot" # Docker build acceleration
    ];

    # GUI Applications (Homebrew Casks)
    # Only apps actively used in the last 2 weeks
    casks = [
      # ─────────────────────────────────────────────────────────────
      # Browsers
      # ─────────────────────────────────────────────────────────────
      "google-chrome"

      # ─────────────────────────────────────────────────────────────
      # Development
      # ─────────────────────────────────────────────────────────────
      "claude-code" # Claude CLI - actively using
      "cursor" # AI-first code editor - keep for development
      "kaleidoscope" # Diff/merge tool

      # ─────────────────────────────────────────────────────────────
      # AI & LLM
      # ─────────────────────────────────────────────────────────────
      "claude" # Claude Desktop - actively using

      # ─────────────────────────────────────────────────────────────
      # Design & Creative
      # ─────────────────────────────────────────────────────────────
      "obsidian" # Knowledge base / notes

      # ─────────────────────────────────────────────────────────────
      # Documents & Files
      # ─────────────────────────────────────────────────────────────
      "google-drive" # Cloud storage sync - just fixed
      "pdf-expert" # PDF editor

      # ─────────────────────────────────────────────────────────────
      # Communication
      # ─────────────────────────────────────────────────────────────
      "slack"

      # ─────────────────────────────────────────────────────────────
      # Productivity
      # ─────────────────────────────────────────────────────────────
      "raycast" # Launcher (Spotlight replacement) - settings in modules/home/apps/raycast.nix
      # Note: Wispr Flow managed via modules/darwin/activation/wispr-flow.nix (not Homebrew)
      "bartender" # Menu bar organizer
      "setapp" # App subscription (manages: Clop, LookAway, Downie, Base, SnapMotion)
      "cleanshot" # Screenshot tool - actively using with Hazel
      "a-better-finder-rename" # Batch file renaming
      "hazel" # Automated file organization - just configured

      # ─────────────────────────────────────────────────────────────
      # Media
      # ─────────────────────────────────────────────────────────────
      "rekordbox" # DJ software

      # ─────────────────────────────────────────────────────────────
      # Remote Desktop
      # ─────────────────────────────────────────────────────────────
      "jump-desktop-connect" # Remote desktop client

      # ─────────────────────────────────────────────────────────────
      # Utilities
      # ─────────────────────────────────────────────────────────────
      "tailscale-app" # VPN mesh network (GUI + CLI)

      # ─────────────────────────────────────────────────────────────
      # System Utilities
      # ─────────────────────────────────────────────────────────────
      "betterdisplay" # Display management: HiDPI, DDC brightness, resolution scaling

      # ─────────────────────────────────────────────────────────────
      # QuickLook Plugins
      # ─────────────────────────────────────────────────────────────
      "qlmarkdown" # Markdown preview
      "syntax-highlight" # Code syntax highlighting
      "quicklook-json" # JSON preview
      "quicklook-csv" # CSV preview
      "qlstephen" # Plain text files without extension
      "qlvideo" # Video thumbnails/preview
      "webpquicklook" # WebP image preview
    ];

    # Mac App Store apps (requires `mas` CLI)
    # Use: mas search "App Name" to find IDs
    # Only apps actively used in the last 2 weeks
    masApps = {
      # ─────────────────────────────────────────────────────────────
      # Apple Apps
      # ─────────────────────────────────────────────────────────────
      "Xcode" = 497799835;
      "Keynote" = 409183694;
      "Pages" = 409201541;
      "Numbers" = 409203825;
      "Apple Configurator" = 1037126344;

      # ─────────────────────────────────────────────────────────────
      # Utilities
      # ─────────────────────────────────────────────────────────────
      "Rapidmg" = 6451349778; # DMG mounter
    };
  };
}
