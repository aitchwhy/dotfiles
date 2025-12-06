# User-specific configuration
# This file contains:
# - Personal development tools and language toolchains
# - Cloud platform CLIs and infrastructure tools
# - User-specific Git configuration
# - Personal productivity tools
{pkgs, ...}: {
  # Import home modules
  imports = [../modules/home];

  # User identity
  home = {
    username = "hank";
    homeDirectory = "/Users/hank";
    stateVersion = "24.11";
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
    terragrunt
    pulumi

    # Container Tools
    docker-client
    docker-compose
    dive

    # Programming Languages & Tools
    # Node.js - using latest LTS
    nodejs_22
    nodePackages.pnpm
    yarn-berry
    bun

    # Python - using uv for fast package management
    python312
    uv
    ruff
    poetry

    # Go
    go
    gopls
    golangci-lint

    # Rust - via rustup for toolchain management
    rustup

    # Database Clients
    postgresql_16
    mysql84
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

    # Nix (nixfmt-rfc-style is the new standard, nixpkgs-fmt is deprecated)
    nixfmt-rfc-style
    alejandra
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
