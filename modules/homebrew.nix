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
      "steipete/tap" # Required for RepoBar
    ];

    # CLI tools (most in home.packages via Nix)
    # OrbStack provides docker, docker-compose, and credential helpers
    brews = [
      "depot" # Docker build acceleration
    ];

    # GUI Applications (Homebrew Casks)
    casks = [
      # ─────────────────────────────────────────────────────────────
      # Browsers
      # ─────────────────────────────────────────────────────────────
      "google-chrome"

      # ─────────────────────────────────────────────────────────────
      # Development
      # ─────────────────────────────────────────────────────────────
      "claude-code" # Claude CLI
      "cursor" # AI-first code editor
      "orbstack" # Docker runtime (replaces Docker Desktop/Colima)
      "proxyman" # HTTP debugging proxy
      "tableplus" # Database GUI
      "antigravity" # Google's AI IDE
      "kaleidoscope" # Diff/merge tool
      "marta" # Dual-pane file manager
      "yaak" # API client (Postman alternative)
      "steipete/tap/repobar" # GitHub repo browser for menu bar

      # ─────────────────────────────────────────────────────────────
      # AI & LLM
      # ─────────────────────────────────────────────────────────────
      "claude" # Claude Desktop
      "chatgpt" # ChatGPT app
      "ollama-app" # Local LLM runner
      "granola" # AI meeting notes

      # ─────────────────────────────────────────────────────────────
      # Design & Creative
      # ─────────────────────────────────────────────────────────────
      "figma"
      "obsidian" # Knowledge base / notes

      # ─────────────────────────────────────────────────────────────
      # Documents & Files
      # ─────────────────────────────────────────────────────────────
      "google-drive" # Cloud storage sync
      "pdf-expert" # PDF editor

      # ─────────────────────────────────────────────────────────────
      # Communication
      # ─────────────────────────────────────────────────────────────
      "slack"
      "zoom"
      "linear-linear" # Project management
      "superhuman" # Email client
      "fathom" # AI meeting recorder

      # ─────────────────────────────────────────────────────────────
      # Productivity
      # ─────────────────────────────────────────────────────────────
      "notion" # Workspace for notes, docs, wikis
      "raycast" # Launcher (Spotlight replacement)
      "bitwarden" # Password manager (primary)
      "bartender" # Menu bar organizer
      "setapp" # App subscription (manages: Clop, LookAway, Downie, Base, SnapMotion)
      "fantastical" # Calendar (Flexibits)
      "cardhop" # Contacts (Flexibits)
      "todoist-app" # Task management
      "sunsama" # Daily planner
      "carbon-copy-cloner" # Backup utility
      "cleanshot" # Screenshot tool
      "a-better-finder-rename" # Batch file renaming

      # ─────────────────────────────────────────────────────────────
      # Media
      # ─────────────────────────────────────────────────────────────
      "spotify"
      "rekordbox" # DJ software

      # ─────────────────────────────────────────────────────────────
      # Remote Desktop
      # ─────────────────────────────────────────────────────────────
      "jump-desktop-connect" # Remote desktop client

      # ─────────────────────────────────────────────────────────────
      # Utilities
      # ─────────────────────────────────────────────────────────────
      "tailscale" # VPN mesh network (GUI + CLI)
      "imazing" # iOS device manager
      "kiwix" # Offline Wikipedia
      "qflipper" # Flipper Zero companion

      # ─────────────────────────────────────────────────────────────
      # System Utilities
      # ─────────────────────────────────────────────────────────────
      "homerow" # Keyboard shortcuts for screen elements
      "betterdisplay" # Display management: HiDPI, DDC brightness, resolution scaling
      "swish" # Trackpad gesture control
      "keymapp" # ZSA keyboard firmware flasher (Voyager)

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
      "suspicious-package" # PKG installer preview
    ];

    # Mac App Store apps (requires `mas` CLI)
    # Use: mas search "App Name" to find IDs
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
      # Productivity
      # ─────────────────────────────────────────────────────────────
      "Amphetamine" = 937984704; # Keep Mac awake
      "rcmd" = 1596283165; # App switcher
      "Drafts" = 1435957248; # Quick capture
      "Bear" = 1091189122; # Markdown notes
      "Paste" = 967805235; # Clipboard manager
      "Flow" = 1423210932; # Pomodoro timer
      "Dropover" = 1355679052; # Drag-and-drop shelf

      # ─────────────────────────────────────────────────────────────
      # Networking
      # ─────────────────────────────────────────────────────────────
      # Tailscale: Installed via Homebrew cask (see casks section)
      # GUI menubar app + CLI tools at /Applications/Tailscale.app

      # ─────────────────────────────────────────────────────────────
      # Utilities
      # ─────────────────────────────────────────────────────────────
      "CleanMyMac" = 1339170533; # System cleaner
      "Duplicate File Finder" = 1032755628;
      "LanScan" = 472226235; # Network scanner
      "Klack" = 6446206067; # Mechanical keyboard sounds
      "Rapidmg" = 6451349778; # DMG mounter

      # ─────────────────────────────────────────────────────────────
      # Development
      # ─────────────────────────────────────────────────────────────
      "System Designer" = 1102494854; # macOS UI mockups
      "MermaidEditor" = 1581312955; # Diagram editor

      # ─────────────────────────────────────────────────────────────
      # Communication
      # ─────────────────────────────────────────────────────────────
      "KakaoTalk" = 869223134; # Korean messenger

      # ─────────────────────────────────────────────────────────────
      # Media & Creative
      # ─────────────────────────────────────────────────────────────
      "Kindle" = 302584613;
      "Whisper Transcription" = 1668083311; # Audio transcription
      "CapCut" = 1500855883; # Video editor

      # ─────────────────────────────────────────────────────────────
      # Travel & Lifestyle
      # ─────────────────────────────────────────────────────────────
      "Flighty" = 1358823008; # Flight tracker
      "Tripsy" = 1429967544; # Travel planner

      # ─────────────────────────────────────────────────────────────
      # Finance
      # ─────────────────────────────────────────────────────────────
      "Copilot" = 1447330651; # Budget tracker
      "Cake Wallet" = 1334702542; # Crypto wallet
    };
  };
}
