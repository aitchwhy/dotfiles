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
    swish.enable = false; # macOS trackpad gestures
    aerospace.enable = false; # macOS tiling window manager
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

  # User-specific packages (Linux-compatible subset)
  home.packages = with pkgs; [
    # Cloud Platforms
    awscli2
    azure-cli
    flyctl
    (google-cloud-sdk.withExtraComponents [
      google-cloud-sdk.components.gke-gcloud-auth-plugin
    ])

    # Kubernetes & Infrastructure
    kubectl
    kubectx
    kubernetes-helm
    k9s
    terraform
    terragrunt
    pulumi

    # Container Tools (docker-client not needed on NixOS - use system Docker)
    docker-compose
    dive

    # Programming Languages & Tools
    nodejs
    nodePackages.pnpm
    yarn-berry
    bun

    # Python
    python314
    uv
    ruff
    poetry

    # Go
    go
    gopls
    golangci-lint

    # Rust
    rustup

    # Database Clients (PostgreSQL 18+, SQLite/Turso - NO MySQL)
    postgresql_18
    mongosh
    redis
    usql

    # API Development
    httpie
    grpcurl

    # Documentation
    glow
    pandoc
    tldr

    # Media Processing
    ffmpeg-full
    imagemagick

    # Security Tools
    sops
    age
    gnupg
    _1password-cli
    bitwarden-cli

    # Code Quality & Formatting
    shellcheck
    shfmt
    nixfmt-rfc-style
    alejandra
    deadnix
    statix
    dprint
    treefmt

    # Development Tools
    cachix
    devenv
    nixd
    nil
    nix-tree
    tree-sitter
    nix-output-monitor
    nix-diff

    # Additional CLI Tools
    mkcert
    ngrok
    caddy

    # GitHub
    gh
    act

    # Linux-specific tools
    xclip # Clipboard support
    wl-clipboard # Wayland clipboard
  ];

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
