# Universal Project Factory - Centralized Version Management
# Frozen: December 2025
# Updated: 2025-12-07
#
# This is the single source of truth for all version numbers.
# Consumed by:
#   - flake.nix (via specialArgs)
#   - modules/home/apps/factory.nix (generates versions.json)
#   - config/factory/src/schema/versions.ts (imports versions.json)
#
# Version format: Exact versions for reproducibility (no ranges)
{
  # ===========================================================================
  # RUNTIME
  # ===========================================================================
  runtime = {
    bun = "1.3.4"; # Anthropic-acquired, latest stable
    node = "22.12.0"; # LTS
    uv = "0.5.1"; # Python manager (Rust)
    volta = "2.0.1"; # Tool manager (Rust)
  };

  # ===========================================================================
  # TYPESCRIPT ECOSYSTEM
  # ===========================================================================
  typescript = {
    typescript = "5.9.3";
    effect = "3.12.4"; # Functional standard library
    effect-cli = "0.50.0";
    effect-platform = "0.72.0";
    effect-platform-node = "0.66.0";
    effect-schema = "0.76.0";
    zod = "3.25.1";
    biome = "2.3.8"; # Lint + format
  };

  # ===========================================================================
  # FRONTEND
  # ===========================================================================
  frontend = {
    react = "19.2.1";
    react-dom = "19.2.1";
    xstate = "5.19.0"; # Actor model state machines
    tanstack-router = "1.140.0";
    tanstack-query = "5.62.0";
    tailwindcss = "4.1.0";
  };

  # ===========================================================================
  # BACKEND
  # ===========================================================================
  backend = {
    hono = "4.10.7"; # Standards-based server
    drizzle-orm = "0.45.0";
    temporal = "1.1.0"; # Durable workflows
  };

  # ===========================================================================
  # INFRASTRUCTURE
  # ===========================================================================
  infra = {
    pulumi = "4.15.0"; # IaC (TypeScript)
    flyctl = "0.3.64";
    turso-cli = "0.98.2";
    process-compose = "1.5.0"; # Unified observability
    tailscale = "1.78.0"; # Mesh network
  };

  # ===========================================================================
  # TESTING & BUILD
  # ===========================================================================
  testing = {
    playwright = "1.57.0";
    vitest = "2.1.0";
    vite = "7.2.6";
    bruno-cli = "1.30.0"; # API testing
  };

  # ===========================================================================
  # PYTHON
  # ===========================================================================
  python = {
    python = "3.13.1";
    pydantic = "2.10.0";
    ruff = "0.8.0";
  };

  # ===========================================================================
  # DATABASE ADAPTERS
  # ===========================================================================
  databases = {
    libsql-client = "0.14.0"; # Turso
    postgres = "3.4.0";
  };

  # ===========================================================================
  # AUTH & SERVICES
  # ===========================================================================
  services = {
    clerk = "6.0.0";
    livekit = "2.9.0";
  };

  # ===========================================================================
  # METADATA
  # ===========================================================================
  meta = {
    frozen = "2025-12";
    updated = "2025-12-07";
    # Used for documentation and drift detection
  };

  # ===========================================================================
  # HELPER: Flat npm dependencies for package.json generation
  # Actual working versions as of December 2025
  # ===========================================================================
  npm = {
    # Core (Effect ecosystem - versions must be compatible)
    typescript = "5.9.3";
    effect = "3.19.9";
    "@effect/cli" = "0.72.1";
    "@effect/platform" = "0.93.6";
    "@effect/platform-node" = "0.103.0";
    "@effect/platform-bun" = "0.86.0";
    "@effect/printer" = "0.47.0";
    "@effect/printer-ansi" = "0.47.0";
    zod = "3.24.0";

    # Frontend
    react = "19.0.0";
    react-dom = "19.0.0";
    xstate = "5.19.0";
    "@tanstack/react-router" = "1.93.1";
    "@tanstack/react-query" = "5.62.0";
    tailwindcss = "4.0.0";

    # Backend
    hono = "4.6.0";
    drizzle-orm = "0.38.0";

    # Database
    "@libsql/client" = "0.14.0";
    postgres = "3.4.0";

    # Testing
    "@playwright/test" = "1.49.0";
    vitest = "2.1.0";

    # Build
    vite = "6.0.0";
    handlebars = "4.7.8";

    # Dev
    "@biomejs/biome" = "2.3.8";
    "@types/bun" = "1.2.10";
  };
}
