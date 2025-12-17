# Cross-platform packages (shared between macOS and Linux)
# Extracted from users/hank.nix and users/hank-linux.nix
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf optionals;
  cfg = config.modules.home.packages;
in
{
  config = mkIf cfg.enable {
    home.packages =
      with pkgs;
      # Cloud Platforms (Google Cloud primary - no Cloudflare/Fly.io)
      (optionals cfg.enableCloudPlatforms [
        awscli2
        azure-cli
        (google-cloud-sdk.withExtraComponents [
          google-cloud-sdk.components.gke-gcloud-auth-plugin
        ])
      ])
      # Kubernetes & Infrastructure
      ++ (optionals cfg.enableKubernetes [
        kubectl
        kubectx
        kubernetes-helm
        k9s
        terraform
        terragrunt
        pulumi
        pulumi-esc # ESC CLI for secrets/config management
      ])
      # Container Tools
      ++ [
        dive
      ]
      # Programming Languages & Tools
      ++ (optionals cfg.enableLanguages [
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
      ])
      # Database Clients (PostgreSQL 18+, SQLite/Turso - NO MySQL)
      ++ (optionals cfg.enableDatabases [
        postgresql_18
        mongosh
        redis
        usql
      ])
      # API Development
      ++ [
        httpie
        grpcurl
      ]
      # Documentation
      ++ [
        glow
        pandoc
        tldr # Community-maintained man page summaries
      ]
      # Media Processing
      ++ [
        ffmpeg-full
        imagemagick
      ]
      # Security Tools
      ++ [
        sops
        age
        gnupg
        _1password-cli
        bitwarden-cli
      ]
      # Code Quality & Formatting
      ++ [
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
      ]
      # Development Tools
      ++ (optionals cfg.enableNixTools [
        cachix
        devenv
        nixd
        nil
        nix-tree
        tree-sitter # Required for LazyVim 15.x treesitter parser compilation
        nix-output-monitor
        nix-diff
      ])
      # Additional CLI Tools
      ++ [
        mkcert # Local HTTPS certs
        ngrok # Expose local servers
        caddy # Modern web server
      ]
      # GitHub
      ++ [
        gh
        act # Run GitHub Actions locally
      ];
  };
}
