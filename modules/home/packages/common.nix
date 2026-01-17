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
      # Note: terraform/opentofu removed - using Pulumi only for IaC
      ++ (optionals cfg.enableKubernetes [
        kubectl
        kubectx
        kubernetes-helm
        k9s
        pulumi
        pulumi-esc # ESC CLI for secrets/config management
      ])
      # Container Tools
      ++ [
        dive
      ]
      # Programming Languages & Tools
      ++ (optionals cfg.enableLanguages [
        # Node.js 25 Current (EOL June 2026)
        nodejs_25
        nodePackages.pnpm
        yarn-berry
        bun

        # Python - uv manages Python versions and tools (run: uv python install && uv tool install ruff)
        uv

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
        pgcli # Enhanced PostgreSQL CLI with autocomplete
        drizzle-kit # Drizzle ORM CLI + Studio GUI
        redis
        usql
      ])
      # API Development (xh in development.nix replaces httpie)
      ++ [
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
        bitwarden-cli
      ]
      # Cloud Storage
      ++ [
        rclone # rsync for cloud storage (Google Drive, S3, etc.)
      ]
      # Code Quality & Formatting
      ++ [
        # Shell
        shellcheck
        shfmt

        # Nix (nixfmt is RFC-style by default in January 2026)
        nixfmt
        deadnix
        statix

        # Multi-language
        treefmt

        # Linters (moved from Mason for full Nix reproducibility)
        markdownlint-cli # Markdown linting
        yamllint # YAML linting
        hadolint # Dockerfile linting
        biome # JS/TS/JSON formatting + linting
      ]
      # Development Tools
      ++ (optionals cfg.enableNixTools [
        cachix
        devenv
        nixd
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
        ralph-claude-code # Autonomous AI development loop
        agent-browser # AI browser automation CLI (run `agent-browser install` on first use)
      ]
      # GitHub
      ++ [
        gh
      ];

    # Declarative uv setup - installs Python and tools after uv is available
    home.activation.setupUvTools = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      UV="/etc/profiles/per-user/${config.home.username}/bin/uv"

      if [ -x "$UV" ]; then
        echo "Setting up Python environment via uv..."

        # Install Python 3.14 and set as default
        "$UV" python install 3.14 --default 2>/dev/null || true

        # Install Python tools (ruff for linting/formatting)
        "$UV" tool install ruff@latest 2>/dev/null || true

        echo "uv setup complete: Python 3.14 + ruff"
      fi
    '';
  };
}
