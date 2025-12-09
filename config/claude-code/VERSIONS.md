# VERSIONS.md - Frozen December 2025

> Single Source of Truth for all version numbers
> Updated: December 8, 2025

## Runtime

| Package | Version | Notes |
|---------|---------|-------|
| Bun | 1.3.4 | Primary runtime |
| Node.js | 22.21.1 | LTS fallback |
| UV | 0.5.1 | Python package manager |
| Volta | 2.0.1 | Node version manager |

## TypeScript Ecosystem

| Package | Version | Notes |
|---------|---------|-------|
| TypeScript | 5.9.3 | Strict mode |
| Effect-TS | 3.19.9 | Functional effect system |
| Zod | 4.1.13 | Schema validation |

## Frontend

| Package | Version | Notes |
|---------|---------|-------|
| React | 19.2.1 | UI library |
| React DOM | 19.2.1 | DOM bindings |
| TanStack Router | 1.140.0 | Type-safe routing |
| XState | 5.24.0 | State management + API state |
| Tailwind CSS | 4.1.17 | Utility-first CSS |

> **Note**: TanStack Query removed - XState actors handle API state

## Backend

| Package | Version | Notes |
|---------|---------|-------|
| Hono | 4.10.7 | Web framework |
| Drizzle ORM | 0.45.0 | Database ORM |
| Drizzle Kit | 0.30.0 | Migration toolkit |

## Authentication

| Package | Version | Notes |
|---------|---------|-------|
| Better-Auth | 1.4.5 | TypeScript-first auth |

## Durable Workflows

| Package | Version | Notes |
|---------|---------|-------|
| @temporalio/client | 1.13.0 | Temporal client |
| @temporalio/worker | 1.13.0 | Temporal worker |
| @temporalio/workflow | 1.13.0 | Workflow definitions |
| @temporalio/activity | 1.13.0 | Activity definitions |
| @restatedev/restate-sdk | 1.9.1 | Alternative workflow engine |

## Observability

| Package | Version | Notes |
|---------|---------|-------|
| @opentelemetry/api | 1.9.0 | Tracing API |
| @opentelemetry/sdk-trace-node | 2.2.0 | Node.js SDK |
| @opentelemetry/exporter-trace-otlp-http | 0.57.0 | OTLP exporter |
| posthog-js | 1.298.0 | Client analytics |
| posthog-node | 5.14.1 | Server analytics |

## Cache & Queue

| Package | Version | Notes |
|---------|---------|-------|
| ioredis | 5.8.2 | Redis client |

## Database

| Package | Version | Notes |
|---------|---------|-------|
| @libsql/client | 0.15.15 | Turso client |
| postgres | 3.4.7 | PostgreSQL driver |

## Testing

| Package | Version | Notes |
|---------|---------|-------|
| Vitest | 4.0.15 | Unit/integration testing |
| @vitest/ui | 4.0.15 | Test UI |
| @playwright/test | 1.57.0 | E2E testing |

## Build & Dev

| Package | Version | Notes |
|---------|---------|-------|
| Vite | 7.2.7 | Build tool |
| oxlint | 1.32.0 | Rust-based linter (Signet) |
| @biomejs/biome | 2.3.8 | General projects |
| @types/bun | 1.2.10 | Bun types |
| @ast-grep/napi | 0.33.1 | AST analysis |

## Infrastructure

| Package | Version | Notes |
|---------|---------|-------|
| Pulumi | 4.15.0 | Infrastructure as Code |
| flyctl | 0.3.64 | Fly.io CLI |
| turso-cli | 0.98.2 | Turso CLI |
| process-compose | 1.5.0 | Dev orchestration |
| Tailscale | 1.78.0 | Mesh networking |

## Python

| Package | Version | Notes |
|---------|---------|-------|
| Python | 3.13.1 | Runtime |
| Pydantic | 2.10.0 | Validation |
| Ruff | 0.8.0 | Lint + format |

---

*Frozen: December 2025*
*Source: lib/versions.nix*
