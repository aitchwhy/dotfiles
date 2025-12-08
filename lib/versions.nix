# Signet - Centralized Version Management
# Frozen: December 2025
# Updated: 2025-12-08
#
# This is the single source of truth for all version numbers.
# Consumed by:
#   - flake.nix (via specialArgs)
#   - modules/home/apps/signet.nix (generates versions.json)
#   - config/signet/src/schema/versions.ts (imports versions.json)
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
  # TYPESCRIPT ECOSYSTEM (deprecated - use npm section below)
  # ===========================================================================
  # NOTE: The npm section is the single source of truth for TypeScript deps.
  # This section is retained only for backwards compatibility with any
  # external consumers. All new code should reference the npm section.

  # ===========================================================================
  # FRONTEND
  # ===========================================================================
  frontend = {
    react = "19.2.1";
    react-dom = "19.2.1";
    xstate = "5.24.0"; # Actor model state machines
    tanstack-router = "1.140.0";
    tanstack-query = "5.90.12";
    tailwindcss = "4.1.17";
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
    vitest = "4.0.15";
    vite = "7.2.7";
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
    libsql-client = "0.15.15"; # Turso
    postgres = "3.4.7";
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
    updated = "2025-12-08";
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
    zod = "4.1.13";

    # Frontend
    react = "19.2.1";
    react-dom = "19.2.1";
    xstate = "5.24.0";
    "@tanstack/react-router" = "1.140.0";
    "@tanstack/react-query" = "5.90.12";
    tailwindcss = "4.1.17";

    # Backend
    hono = "4.10.7";
    drizzle-orm = "0.45.0";

    # Database
    "@libsql/client" = "0.15.15";
    postgres = "3.4.7";

    # Testing
    "@playwright/test" = "1.57.0";
    vitest = "4.0.15";

    # Build
    vite = "7.2.7";
    handlebars = "4.7.8";

    # Dev
    "@biomejs/biome" = "2.3.8";
    "@types/bun" = "1.2.10";
  };
}
