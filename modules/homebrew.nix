# Homebrew configuration for macOS
# Single source of truth for GUI applications and most CLI tools
# - Homebrew Brews: CLI tools (avoids Nix Python/build issues on macOS)
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

    # Force-upgrade casks that have auto_updates (Claude, Slack, etc.)
    greedyCasks = true;

    # CLI tools
    # OrbStack provides docker, docker-compose, and credential helpers
    brews = [
      # Build & Deploy
      "depot" # Docker build acceleration
      "mas" # Required for masApps management

      # Cloud Platforms
      "awscli"
      "azure-cli"

      # Kubernetes & Infrastructure
      "kubectl"
      "kubectx"
      "helm"
      "k9s"
      "pulumi"
      "dive" # Docker image analyzer

      # Programming Languages & Tools
      "pnpm"
      "uv"
      "go"
      "gopls"
      "golangci-lint"
      "rustup"

      # Databases
      "postgresql@18"
      "pgcli"
      "redis"

      # API Development
      "grpcurl"

      # Documentation
      "glow"
      "pandoc"
      "tlrc"

      # Media Processing
      "ffmpeg"
      "imagemagick"
      "yt-dlp"

      # Security
      "sops"
      "age"
      "gnupg"
      "bitwarden-cli"

      # Cloud Storage
      "rclone"

      # Code Quality (non-Nix)
      "shellcheck"
      "shfmt"
      "markdownlint-cli"
      "yamllint"
      "hadolint"
      "biome"

      # CLI Tools
      "fclones"
      "mkcert"
      "caddy"
      "gh"
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
      "ngrok" # Expose local servers
      "orbstack" # Container runtime (Docker/Lima replacement)

      # ─────────────────────────────────────────────────────────────
      # AI & LLM
      # ─────────────────────────────────────────────────────────────
      "claude" # Claude Desktop - actively using
      "granola" # AI-powered notepad for meetings

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
      "superhuman" # Email client
      "zoom" # Video conferencing

      # ─────────────────────────────────────────────────────────────
      # Productivity
      # ─────────────────────────────────────────────────────────────
      "homerow" # Keyboard navigation for every screen element - Opt+Shift+Space
      "raycast" # Launcher (Spotlight replacement) - settings in modules/home/apps/raycast.nix
      "wispr-flow" # Voice dictation
      "bartender" # Menu bar organizer
      "setapp" # App subscription (manages: Paste, Clop, LookAway, Downie, Base, SnapMotion)
      "cleanshot" # Screenshot tool - actively using with Hazel
      "a-better-finder-rename" # Batch file renaming
      "hazel" # Automated file organization - just configured
      "todoist-app" # Task manager
      "bitwarden" # Password manager
      "cardhop" # Contacts app (Flexibits)
      "fantastical" # Calendar app - settings in modules/home/apps/fantastical.nix
      "linear-linear" # Project management & issue tracking

      # ─────────────────────────────────────────────────────────────
      # Media
      # ─────────────────────────────────────────────────────────────
      "rekordbox" # DJ software
      "spotify" # Music streaming

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
      "swish" # Trackpad gestures and window management

      # ─────────────────────────────────────────────────────────────
      # QuickLook Plugins
      # ─────────────────────────────────────────────────────────────
      "qlvideo" # Video thumbnails/preview
    ];

    # Mac App Store apps (requires `mas` CLI)
    # Use: mas search "App Name" to find IDs
    # Only apps actively used in the last 2 weeks
    masApps = {
      # ─────────────────────────────────────────────────────────────
      # Apple Apps
      # ─────────────────────────────────────────────────────────────
      "Keynote" = 409183694;
      "Pages" = 409201541;
      "Numbers" = 409203825;

      # ─────────────────────────────────────────────────────────────
      # Communication
      # ─────────────────────────────────────────────────────────────
      "KakaoTalk" = 869223134; # Korean messaging app

      # ─────────────────────────────────────────────────────────────
      # Travel
      # ─────────────────────────────────────────────────────────────
      "Tripsy" = 1429967544; # Travel planner
      "Flighty" = 1358823008; # Flight tracking

      # ─────────────────────────────────────────────────────────────
      # Food & Cooking
      # ─────────────────────────────────────────────────────────────
      "Mela – Recipe Manager" = 1568924476; # Cooking recipes

      # ─────────────────────────────────────────────────────────────
      # Utilities
      # ─────────────────────────────────────────────────────────────
      "rcmd" = 1596283165; # Right Command keyboard shortcuts
      "Dropover - Easier Drag & Drop" = 1355679052; # Drag & drop shelf
      "Whisper Transcription" = 1668083311; # Audio transcription

    };
  };
}
