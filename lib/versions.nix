# Signet - Centralized Version Management
# Frozen: December 2025
# Updated: 2025-12-08
# SSOT Version: 2.0.0 (Dec 8, 2025 Migration)
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
    node = "22.21.1"; # LTS (updated)
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
    xstate = "5.24.0"; # Actor model state machines (handles API state)
    tanstack-router = "1.140.0";
    # NOTE: TanStack Query removed - XState actors handle API state
    tailwindcss = "4.1.17";
  };

  # ===========================================================================
  # BACKEND
  # ===========================================================================
  backend = {
    hono = "4.10.7"; # Standards-based server (latest Dec 8, 2025)
    drizzle-orm = "0.45.0";
    temporal = "1.13.0"; # Durable workflows (SDK version)
    restate = "1.9.1"; # Alternative durable execution
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
    better-auth = "1.4.5"; # TypeScript-first auth (replaces Clerk)
    livekit = "2.9.0";
  };

  # ===========================================================================
  # OBSERVABILITY
  # ===========================================================================
  observability = {
    opentelemetry-api = "1.9.0";
    opentelemetry-sdk = "2.2.0"; # Major SDK upgrade Dec 2025
    posthog-js = "1.298.0";
    posthog-node = "5.14.1";
    datadog-agent = "7.60.0"; # Reference only (not npm)
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
  # SSOT December 8, 2025 - All versions frozen
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
    xstate = "5.24.0"; # Handles API state via actors
    "@xstate/react" = "5.0.0";
    "@tanstack/react-router" = "1.140.0";
    # NOTE: @tanstack/react-query removed - XState actors handle API state
    tailwindcss = "4.1.17";

    # Backend
    hono = "4.10.7";
    "@hono/zod-openapi" = "0.18.0";
    drizzle-orm = "0.45.0";
    drizzle-kit = "0.30.0";

    # Auth
    better-auth = "1.4.5";

    # Durable Workflows
    "@temporalio/client" = "1.13.0";
    "@temporalio/worker" = "1.13.0";
    "@temporalio/workflow" = "1.13.0";
    "@temporalio/activity" = "1.13.0";
    "@restatedev/restate-sdk" = "1.9.1"; # Alternative

    # Observability
    "@opentelemetry/api" = "1.9.0";
    "@opentelemetry/sdk-trace-node" = "2.2.0"; # Major SDK upgrade Dec 2025
    "@opentelemetry/exporter-trace-otlp-http" = "0.57.0";
    posthog-js = "1.298.0";
    posthog-node = "5.14.1";

    # Cache & Queue
    ioredis = "5.8.2";

    # Database
    "@libsql/client" = "0.15.15";
    postgres = "3.4.7";

    # Testing
    "@playwright/test" = "1.57.0";
    vitest = "4.0.15";
    "@vitest/ui" = "4.0.15";

    # Build
    vite = "7.2.7";
    handlebars = "4.7.8";

    # Dev & Linting
    oxlint = "1.32.0"; # Rust-based linter (replaces Biome for Signet)
    "@biomejs/biome" = "2.3.8"; # Kept for non-Signet projects
    "@types/bun" = "1.2.10";
    "@ast-grep/napi" = "0.33.1";
  };
}
