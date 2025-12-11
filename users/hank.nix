# User-specific configuration
# This file contains:
# - Personal development tools and language toolchains
# - Cloud platform CLIs and infrastructure tools
# - User-specific Git configuration
# - Personal productivity tools
{ pkgs, ... }:
{
  # Import home modules
  imports = [ ../modules/home ];

  # User identity
  home = {
    username = "hank";
    homeDirectory = "/Users/hank";
    stateVersion = "26.05";
  };

  # Git configuration
  modules.home.tools.git = {
    userName = "Hank Lee";
    userEmail = "hank.lee.qed@gmail.com";
  };

  # User-specific packages
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
    opentofu # Modern Terraform alternative
    terragrunt
    pulumi
    pulumiPackages.pulumi-nodejs

    # Container Tools
    docker-client
    dive

    # Programming Languages & Tools
    # Node.js - using latest current (not LTS)
    nodejs
    nodePackages.pnpm
    yarn-berry
    bun

    # Python - using uv for fast package management
    python314
    uv
    ruff
    poetry

    # Go
    go
    gopls
    golangci-lint

    # Rust - via rustup for toolchain management
    rustup

    # Database Clients (PostgreSQL 18+, SQLite/Turso - NO MySQL)
    postgresql_18
    mongosh
    redis
    usql

    # API Development
    httpie
    grpcurl
    # Note: yaak (Postman alternative) is installed via Homebrew cask

    # Documentation
    glow
    pandoc
    tldr # Community-maintained man page summaries

    # Media Processing
    ffmpeg-full
    imagemagick

    # macOS Apps (migrated from Homebrew)
    iina # Video player
    keka # File archiver

    # Security Tools
    sops
    age
    gnupg
    _1password-cli
    bitwarden-cli # Password manager CLI (migrated from Homebrew)

    # Code Quality & Formatting
    # Shell
    shellcheck
    shfmt

    # Nix (nixfmt-rfc-style is the December 2025 standard)
    nixfmt-rfc-style
    deadnix
    statix

    # Multi-language
    dprint
    treefmt

    # Development Tools
    # Nix-specific
    cachix
    devenv
    nixd
    nil
    nix-tree
    tree-sitter # Required for LazyVim 15.x treesitter parser compilation
    nix-output-monitor
    nix-diff

    # Additional CLI Tools
    mkcert # Local HTTPS certs
    ngrok # Expose local servers
    caddy # Modern web server
    gum # TUI components for rx config editor

    # GitHub
    gh
    act # Run GitHub Actions locally
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
