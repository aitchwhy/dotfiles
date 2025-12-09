# Tech Stack SSOT — December 2025

> **Single Source of Truth for all technology decisions, versions, and architectural patterns.**
>
> This document is declarative: the running system MUST match this specification.
> Any drift between this spec and runtime is a bug to be corrected.

**Version:** 1.2.0
**Last Updated:** December 9, 2025
**Owner:** Hank Lee

---

## Table of Contents

1. [Core Principles](#1-core-principles)
2. [Architectural Layers](#2-architectural-layers)
3. [Complete Version Matrix](#3-complete-version-matrix)
4. [Layer 0: Foundation](#4-layer-0-foundation)
5. [Layer 1: Runtime](#5-layer-1-runtime)
6. [Layer 2: Application](#6-layer-2-application)
7. [Layer 3: Operational](#7-layer-3-operational)
8. [Architecture Patterns](#8-architecture-patterns)
9. [File Structure](#9-file-structure)
10. [Configuration Files](#10-configuration-files)
11. [Development Workflow](#11-development-workflow)
12. [Quality Gates](#12-quality-gates)
13. [Appendix: Temporal (Optional)](#appendix-temporal-optional)

---

## 1. Core Principles

### 1.1 Environment Parity

```
localhost === CI === production
```

Achieved through:
- **Nix Flakes** for hermetic, reproducible environments
- **Process Compose** for local service orchestration
- **Cloud Build + Artifact Registry** for identical production images
- **Secret Manager** for production secrets (SOPS locally)

### 1.2 Google Cloud Consolidation

All managed infrastructure runs on Google Cloud Platform to minimize toolset sprawl:

| Concern | Google Cloud Service |
|---------|---------------------|
| Compute | Cloud Run |
| Database | Cloud SQL (PostgreSQL) |
| Cache | Memorystore (Redis) |
| Messaging | Pub/Sub |
| Secrets | Secret Manager |
| Observability | Cloud Trace, Cloud Logging, Cloud Monitoring |
| Container Registry | Artifact Registry |
| CI/CD | Cloud Build |
| Infrastructure as Code | Pulumi (TypeScript) |

### 1.3 Maximum Rigor Through Paradigms

| Paradigm | Tool | What It Eliminates |
|----------|------|-------------------|
| **Algebraic Effects** | Effect-TS | Untyped errors, hidden dependencies, race conditions |
| **Finite State Machines** | XState | Impossible states, state explosion, UI logic bugs |
| **TypeScript-First Validation** | Zod + `satisfies` | Type drift between compile-time and runtime |
| **Schema-First RPC** | tRPC | Client/server type drift |

### 1.4 Type Safety Hierarchy

```
TypeScript Type (source of truth) → Zod Schema (runtime validation via satisfies)
```

**Rules:**
- **TypeScript type is ALWAYS the source of truth**
- **NEVER use `z.infer<>`** — define the type explicitly first
- Zod schemas MUST use `satisfies` to ensure conformance to the TypeScript type
- No `any` — use `unknown` + type guards
- No type assertions without adjacent validation

**Naming Convention:**
- TypeScript type: `PascalCase` (e.g., `User`, `CreateUserInput`)
- Zod schema: `camelCase` + `Schema` suffix (e.g., `userSchema`, `createUserInputSchema`)

**Pattern:**

```typescript
// ✅ CORRECT: TypeScript type is source of truth
interface User {
  readonly id: string;
  readonly email: string;
  readonly name?: string;
  readonly createdAt: Date;
}

const userSchema = z.object({
  id: z.string().uuid(),
  email: z.string().email(),
  name: z.string().min(1).max(100).optional(),
  createdAt: z.date(),
}) satisfies z.ZodType<User>;

// ❌ NEVER: Inferring types from Zod
// type User = z.infer<typeof userSchema>;  // FORBIDDEN
```

### 1.5 Error Handling Philosophy

```typescript
// ❌ NEVER: throw for expected failures
function getUser(id: string): User {
  const user = db.find(id);
  if (!user) throw new Error("Not found"); // Hidden failure mode
  return user;
}

// ✅ ALWAYS: typed errors with Effect-TS
function getUser(id: string): Effect<User, UserNotFoundError | DatabaseError, Database> {
  return Effect.gen(function* () {
    const db = yield* Database;
    const user = yield* db.find(id);
    if (!user) return yield* Effect.fail(new UserNotFoundError({ id }));
    return user;
  });
}
```

---

## 2. Architectural Layers

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         LAYER 0: FOUNDATION                                  │
│  Nix Flakes • nix-direnv • Process Compose • Secret Manager • Git • Pulumi │
│  PURPOSE: Hermetic environments, secrets, version control, IaC             │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         LAYER 1: RUNTIME                                     │
│  Node.js 25 • Bun 1.3 • TypeScript 5.9                                      │
│  PURPOSE: Execute code, manage packages, transpile                          │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         LAYER 2: APPLICATION                                 │
│  Effect-TS • XState • tRPC • Hono • Drizzle • Zod                          │
│  PURPOSE: Business logic, state, API, persistence                          │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         LAYER 3: OPERATIONAL                                 │
│  Vitest • Playwright • OXC • OpenTelemetry • Cloud Build • Cloud Run       │
│  PURPOSE: Testing, quality, observability, deployment                       │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Complete Version Matrix

### 3.1 Canonical Versions

All versions are pinned. Updates require explicit version bump in this document.

```nix
# SSOT: lib/versions.nix — This section must match lib/versions.nix
# Run: diff <(grep -E "^\s+\w+ =" lib/versions.nix) <(grep -E "^\s+\w+ =" STACK.md) to check drift
{
  # ═══════════════════════════════════════════════════════════════════════════
  # LAYER 0: FOUNDATION
  # ═══════════════════════════════════════════════════════════════════════════
  nix-darwin = "24.11";
  home-manager = "24.11";
  nix-direnv = "3.0.6";
  process-compose = "1.5.0";
  sops = "3.9.0";           # Local secrets only
  age = "1.2.0";            # Local secrets only
  google-cloud-sdk = "504.0.1";
  pulumi = "3.142.0";

  # ═══════════════════════════════════════════════════════════════════════════
  # LAYER 1: RUNTIME (synced with lib/versions.nix)
  # ═══════════════════════════════════════════════════════════════════════════
  nodejs = "22.21.1";  # LTS - matches lib/versions.nix runtime.node
  bun = "1.3.4";
  typescript = "5.9.3";

  # ═══════════════════════════════════════════════════════════════════════════
  # LAYER 2: APPLICATION — API & Communication
  # ═══════════════════════════════════════════════════════════════════════════
  hono = "4.10.7";
  hono-node-server = "1.13.7";
  hono-trpc-server = "0.4.0";
  hono-zod-openapi = "0.18.0";
  trpc-server = "11.7.2";
  trpc-client = "11.7.2";

  # ═══════════════════════════════════════════════════════════════════════════
  # LAYER 2: APPLICATION — Validation
  # ═══════════════════════════════════════════════════════════════════════════
  zod = "4.1.13";

  # ═══════════════════════════════════════════════════════════════════════════
  # LAYER 2: APPLICATION — State Management
  # ═══════════════════════════════════════════════════════════════════════════
  effect = "3.19.9";  # synced with lib/versions.nix npm.effect
  effect-platform = "0.93.6";  # @effect/platform
  effect-platform-node = "0.103.0";  # @effect/platform-node
  effect-schema = "0.99.0";
  xstate = "5.24.0";
  xstate-react = "5.0.0";  # @xstate/react - synced with versions.nix
  xstate-store = "3.13.0";

  # ═══════════════════════════════════════════════════════════════════════════
  # LAYER 2: APPLICATION — Data Access (Google Cloud)
  # ═══════════════════════════════════════════════════════════════════════════
  drizzle-orm = "0.45.0";  # synced with lib/versions.nix
  drizzle-kit = "0.30.0";
  pg = "8.13.0";                    # PostgreSQL driver
  google-cloud-pubsub = "4.9.0";   # Pub/Sub client
  ioredis = "5.8.2";               # Redis client for Memorystore - synced

  # ═══════════════════════════════════════════════════════════════════════════
  # LAYER 2: APPLICATION — Authentication
  # ═══════════════════════════════════════════════════════════════════════════
  better-auth = "1.4.5";  # synced with lib/versions.nix

  # ═══════════════════════════════════════════════════════════════════════════
  # LAYER 2: APPLICATION — Frontend
  # ═══════════════════════════════════════════════════════════════════════════
  react = "19.2.1";
  react-dom = "19.2.1";
  tanstack-router = "1.140.0";
  tailwindcss = "4.1.17";  # synced with lib/versions.nix

  # ═══════════════════════════════════════════════════════════════════════════
  # LAYER 3: OPERATIONAL — Testing
  # ═══════════════════════════════════════════════════════════════════════════
  vitest = "4.0.15";
  vitest-ui = "4.0.15";
  vitest-coverage-v8 = "4.0.15";
  vitest-browser-playwright = "4.0.15";
  playwright = "1.57.0";
  playwright-test = "1.57.0";

  # ═══════════════════════════════════════════════════════════════════════════
  # LAYER 3: OPERATIONAL — Code Quality
  # ═══════════════════════════════════════════════════════════════════════════
  oxlint = "1.32.0";
  ast-grep = "0.33.1";  # synced with lib/versions.nix

  # ═══════════════════════════════════════════════════════════════════════════
  # LAYER 3: OPERATIONAL — Observability (OpenTelemetry → GCP)
  # ═══════════════════════════════════════════════════════════════════════════
  opentelemetry-sdk-node = "1.28.0";
  opentelemetry-auto-instrumentations-node = "0.52.0";
  opentelemetry-exporter-trace-otlp-http = "0.56.0";
  google-cloud-opentelemetry-cloud-trace-exporter = "2.4.1";
  posthog-js = "1.301.0";
  posthog-node = "5.17.0";
}
```

### 3.2 npm Package Mapping

```json
{
  "dependencies": {
    "hono": "4.10.7",
    "@hono/node-server": "1.13.7",
    "@hono/trpc-server": "0.4.0",
    "@hono/zod-openapi": "0.18.0",
    "@trpc/server": "11.7.2",
    "@trpc/client": "11.7.2",
    "zod": "4.1.13",
    "effect": "3.19.10",
    "@effect/platform": "0.72.0",
    "@effect/platform-node": "0.69.0",
    "@effect/schema": "0.99.0",
    "xstate": "5.24.0",
    "@xstate/react": "6.0.0",
    "@xstate/store": "3.13.0",
    "drizzle-orm": "0.44.7",
    "pg": "8.13.0",
    "@google-cloud/pubsub": "4.9.0",
    "ioredis": "5.4.1",
    "better-auth": "1.3.8",
    "react": "19.2.1",
    "react-dom": "19.2.1",
    "@tanstack/react-router": "1.140.0",
    "@opentelemetry/sdk-node": "1.28.0",
    "@opentelemetry/auto-instrumentations-node": "0.52.0",
    "@google-cloud/opentelemetry-cloud-trace-exporter": "2.4.1",
    "posthog-node": "5.17.0"
  },
  "devDependencies": {
    "typescript": "5.9.3",
    "drizzle-kit": "0.30.0",
    "vitest": "4.0.15",
    "@vitest/ui": "4.0.15",
    "@vitest/coverage-v8": "4.0.15",
    "@vitest/browser-playwright": "4.0.15",
    "@playwright/test": "1.57.0",
    "oxlint": "1.32.0",
    "tailwindcss": "4.0.0",
    "posthog-js": "1.301.0",
    "@types/pg": "8.11.10"
  }
}
```

### 3.3 Pulumi Package Mapping (infra/package.json)

```json
{
  "name": "ember-infra",
  "devDependencies": {
    "@pulumi/pulumi": "3.142.0",
    "@pulumi/gcp": "8.12.0",
    "@pulumi/docker": "4.5.7",
    "typescript": "5.9.3"
  }
}
```

### 3.4 Google Cloud Services

| Service | Purpose | Local Equivalent |
|---------|---------|------------------|
| **Cloud Run** | Container hosting (API) | Process Compose |
| **Cloud SQL** | PostgreSQL 16 | Local PostgreSQL |
| **Memorystore** | Redis 7.2 | Local Redis |
| **Pub/Sub** | Event streaming | Local emulator |
| **Secret Manager** | Production secrets | SOPS + Age |
| **Cloud Build** | CI/CD pipelines | Local builds |
| **Artifact Registry** | Container images | Local Docker |
| **Cloud Trace** | Distributed tracing | Jaeger local |
| **Cloud Logging** | Centralized logs | stdout |
| **Cloud Monitoring** | Metrics & alerts | Local metrics |

---

## 4. Layer 0: Foundation

### 4.1 Nix Flakes

**Purpose:** Hermetic, reproducible development environments across all machines.

**Rationale:**
- Declarative: environment defined in code, versioned in git
- Reproducible: same inputs always produce same outputs
- Isolated: no global pollution, multiple versions coexist
- Cross-platform: works on macOS (nix-darwin) and Linux

**Key Files:**
- `flake.nix` — Root flake definition
- `flake.lock` — Pinned dependency versions
- `.envrc` — Direnv integration (`use flake`)

### 4.2 Process Compose

**Purpose:** Orchestrate all local services with a single command.

**Rationale:**
- Replaces Docker Compose for development (faster startup)
- Defines service dependencies declaratively
- Provides log aggregation and health checks
- Configuration mirrors production topology on Cloud Run

**Usage:**
```bash
process-compose up        # Start all services
process-compose up -d     # Start detached
process-compose down      # Stop all services
process-compose logs app  # View app logs
```

### 4.3 Pulumi (TypeScript)

**Purpose:** Infrastructure as Code with full TypeScript type safety.

**Rationale:**
- TypeScript: same language as application code
- Type safety: catch infrastructure errors at compile time
- Reusable components: share infrastructure patterns as packages
- State management: Pulumi Cloud or self-hosted backend

**Project Structure:**
```
infra/
├── index.ts              # Main Pulumi program
├── package.json          # Pulumi dependencies
├── tsconfig.json         # TypeScript config
├── Pulumi.yaml           # Project definition
├── Pulumi.dev.yaml       # Dev stack config
└── Pulumi.prod.yaml      # Prod stack config
```

**Example Infrastructure:**

```typescript
// infra/index.ts
import * as pulumi from "@pulumi/pulumi";
import * as gcp from "@pulumi/gcp";

const config = new pulumi.Config();
const project = gcp.config.project;
const region = config.require("region");

// Cloud SQL PostgreSQL
const dbInstance = new gcp.sql.DatabaseInstance("ember-db", {
  databaseVersion: "POSTGRES_16",
  region,
  settings: {
    tier: "db-f1-micro",
    ipConfiguration: {
      ipv4Enabled: false,
      privateNetwork: vpc.id,
    },
    backupConfiguration: {
      enabled: true,
      startTime: "03:00",
    },
  },
  deletionProtection: true,
});

const database = new gcp.sql.Database("ember", {
  instance: dbInstance.name,
  name: "ember",
});

const dbUser = new gcp.sql.User("ember-user", {
  instance: dbInstance.name,
  name: "ember",
  password: config.requireSecret("dbPassword"),
});

// Memorystore Redis
const redis = new gcp.redis.Instance("ember-cache", {
  region,
  tier: "BASIC",
  memorySizeGb: 1,
  redisVersion: "REDIS_7_2",
  authorizedNetwork: vpc.id,
});

// Cloud Run Service
const apiService = new gcp.cloudrunv2.Service("ember-api", {
  location: region,
  template: {
    containers: [{
      image: pulumi.interpolate`${region}-docker.pkg.dev/${project}/ember/api:latest`,
      ports: [{ containerPort: 8080 }],
      envs: [
        { name: "DATABASE_URL", valueSource: { secretKeyRef: { secret: dbUrlSecret.secretId, version: "latest" } } },
        { name: "REDIS_URL", value: pulumi.interpolate`redis://${redis.host}:${redis.port}` },
      ],
      resources: {
        limits: { cpu: "1", memory: "512Mi" },
      },
    }],
    vpcAccess: {
      connector: vpcConnector.id,
      egress: "PRIVATE_RANGES_ONLY",
    },
  },
});

// Pub/Sub Topics
const userEventsTopic = new gcp.pubsub.Topic("user-events");
const orderEventsTopic = new gcp.pubsub.Topic("order-events");

// Exports
export const apiUrl = apiService.uri;
export const dbConnectionName = dbInstance.connectionName;
export const redisHost = redis.host;
```

### 4.4 Secrets Management

**Local Development:** SOPS + Age
- Secrets encrypted in git
- Decrypted automatically via `.envrc`

**Production:** Google Secret Manager
- Secrets stored in GCP
- Accessed via Workload Identity (no keys in code)
- Mounted as environment variables in Cloud Run

```typescript
// src/lib/secrets.ts
import { SecretManagerServiceClient } from "@google-cloud/secret-manager";
import { Effect, Layer, Context, Data } from "effect";

class SecretsError extends Data.TaggedError("SecretsError")<{
  readonly cause: unknown;
}> {}

interface SecretsService {
  readonly get: (name: string) => Effect.Effect<string, SecretsError>;
}

class Secrets extends Context.Tag("Secrets")<Secrets, SecretsService>() {}

// Production: Secret Manager
const SecretManagerLive = Layer.sync(Secrets, () => {
  const client = new SecretManagerServiceClient();
  const projectId = process.env.GCP_PROJECT_ID!;

  return {
    get: (name) => Effect.tryPromise({
      try: async () => {
        const [version] = await client.accessSecretVersion({
          name: `projects/${projectId}/secrets/${name}/versions/latest`,
        });
        return version.payload?.data?.toString() ?? "";
      },
      catch: (e) => new SecretsError({ cause: e }),
    }),
  };
});

// Local: Environment variables (from SOPS)
const EnvSecretsLive = Layer.succeed(Secrets, {
  get: (name) => Effect.sync(() => process.env[name] ?? ""),
});

export { Secrets, SecretManagerLive, EnvSecretsLive };
```

---

## 5. Layer 1: Runtime

### 5.1 Node.js 25.2.1

**Purpose:** Primary JavaScript runtime for production.

**Rationale:**
- Current release with latest V8 optimizations
- LTS track provides stability guarantees
- Wide ecosystem compatibility

**When to Use:**
- Production deployments on Cloud Run
- When Bun compatibility issues arise

### 5.2 Bun 1.3.4

**Purpose:** Fast all-in-one toolkit for development.

**Rationale:**
- 30x faster package installs than npm
- Built-in bundler, test runner, TypeScript support
- Native PostgreSQL, Redis clients
- Hot reloading in development

**When to Use:**
- Package management (`bun install`)
- Development server (`bun run dev`)
- Unit tests (`bun test` or `vitest`)
- Scripts and tooling

### 5.3 TypeScript 5.9.3

**Purpose:** Type-safe JavaScript with static analysis.

**Configuration:**
```json
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "verbatimModuleSyntax": true,
    "moduleResolution": "bundler",
    "module": "ESNext",
    "target": "ESNext",
    "lib": ["ESNext"],
    "skipLibCheck": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true
  }
}
```

**Rules:**
- `strict: true` is mandatory
- `any` is forbidden — use `unknown` + type guards
- All exports must have explicit types
- Branded types for domain identifiers

---

## 6. Layer 2: Application

### 6.1 Effect-TS 3.19.10

**Purpose:** Typed functional effects for backend business logic.

**Rationale:**
- **Typed Errors:** Every function declares what errors it can produce
- **Dependency Injection:** Services declared in type signature via `Context.Tag`
- **Structured Concurrency:** Fibers with automatic cancellation and resource cleanup
- **Observability:** Built-in tracing with `Effect.withSpan()`

**Core Concepts:**

```typescript
// Effect<Success, Error, Requirements>
// - Success: what the effect produces on success
// - Error: what errors can occur (union type)
// - Requirements: what services are needed (intersection type)

import { Effect, Context, Layer, Data } from "effect";

// 1. Define typed errors
class UserNotFoundError extends Data.TaggedError("UserNotFoundError")<{
  readonly userId: string;
}> {}

class DatabaseError extends Data.TaggedError("DatabaseError")<{
  readonly cause: unknown;
}> {}

// 2. Define service interface (Port)
interface UserRepository {
  readonly findById: (id: string) => Effect.Effect<User, UserNotFoundError | DatabaseError>;
  readonly save: (user: User) => Effect.Effect<void, DatabaseError>;
}

// 3. Create service tag
class UserRepo extends Context.Tag("UserRepo")<UserRepo, UserRepository>() {}

// 4. Implement service (Adapter)
const DrizzleUserRepo = Layer.succeed(UserRepo, {
  findById: (id) => Effect.gen(function* () {
    const result = yield* Effect.tryPromise({
      try: () => db.select().from(users).where(eq(users.id, id)),
      catch: (e) => new DatabaseError({ cause: e }),
    });
    if (result.length === 0) {
      return yield* Effect.fail(new UserNotFoundError({ userId: id }));
    }
    return result[0];
  }),
  save: (user) => Effect.tryPromise({
    try: () => db.insert(users).values(user),
    catch: (e) => new DatabaseError({ cause: e }),
  }),
});

// 5. Use in business logic
const getUser = (id: string) => Effect.gen(function* () {
  const repo = yield* UserRepo;
  return yield* repo.findById(id);
}).pipe(
  Effect.withSpan("getUser", { attributes: { userId: id } })
);

// 6. Run with provided dependencies
const program = getUser("123").pipe(
  Effect.provide(DrizzleUserRepo)
);

Effect.runPromise(program);
```

### 6.2 XState 5.24.0

**Purpose:** Finite state machines for frontend state management.

**Rationale:**
- **Impossible States Eliminated:** Can only be in defined states
- **Explicit Transitions:** Predictable state changes
- **Actor Model:** Isolated, composable state machines
- **Visualizable:** XState Inspector for debugging
- **Handles Async:** Actors manage API calls, no need for TanStack Query

**Core Concepts:**

```typescript
import { createMachine, assign, fromPromise } from "xstate";
import { useMachine } from "@xstate/react";

// 1. Define context and events with TypeScript types first
interface FetchContext {
  data: User | null;
  error: string | null;
}

type FetchEvent =
  | { type: "FETCH"; userId: string }
  | { type: "RETRY" };

// 2. Create machine
const fetchUserMachine = createMachine({
  id: "fetchUser",
  initial: "idle",
  context: {
    data: null,
    error: null,
  } satisfies FetchContext,
  states: {
    idle: {
      on: {
        FETCH: {
          target: "loading",
          actions: assign({ error: null }),
        },
      },
    },
    loading: {
      invoke: {
        src: fromPromise(async ({ input }: { input: { userId: string } }) => {
          const response = await fetch(`/api/users/${input.userId}`);
          if (!response.ok) throw new Error("Failed to fetch");
          return response.json();
        }),
        input: ({ event }) => ({ userId: event.userId }),
        onDone: {
          target: "success",
          actions: assign({ data: ({ event }) => event.output }),
        },
        onError: {
          target: "failure",
          actions: assign({ error: ({ event }) => event.error.message }),
        },
      },
    },
    success: {
      on: {
        FETCH: {
          target: "loading",
          actions: assign({ error: null }),
        },
      },
    },
    failure: {
      on: {
        RETRY: "loading",
        FETCH: {
          target: "loading",
          actions: assign({ error: null }),
        },
      },
    },
  },
});

// 3. Use in React component
function UserProfile({ userId }: { userId: string }) {
  const [state, send] = useMachine(fetchUserMachine);

  useEffect(() => {
    send({ type: "FETCH", userId });
  }, [userId, send]);

  return (
    <div>
      {state.matches("loading") && <Spinner />}
      {state.matches("success") && <UserCard user={state.context.data!} />}
      {state.matches("failure") && (
        <ErrorMessage
          message={state.context.error!}
          onRetry={() => send({ type: "RETRY" })}
        />
      )}
    </div>
  );
}
```

### 6.3 Zod 4.1.13 (with TypeScript-First Pattern)

**Purpose:** Runtime validation that conforms to TypeScript types.

**Critical Rule:** TypeScript type is ALWAYS the source of truth. Zod schemas use `satisfies` to ensure conformance.

**Pattern:**

```typescript
// src/types/user.ts — TypeScript types (source of truth)
export interface UserId extends String {
  readonly _brand: unique symbol;
}

export interface User {
  readonly id: UserId;
  readonly email: string;
  readonly name?: string;
  readonly createdAt: Date;
}

export interface CreateUserInput {
  readonly email: string;
  readonly name?: string;
}

// src/schemas/user.ts — Zod schemas (runtime validation)
import { z } from "zod";
import type { User, UserId, CreateUserInput } from "../types/user";

// Schema conforms to TypeScript type via satisfies
export const userIdSchema = z.string().uuid() satisfies z.ZodType<UserId>;

export const userSchema = z.object({
  id: userIdSchema,
  email: z.string().email(),
  name: z.string().min(1).max(100).optional(),
  createdAt: z.date(),
}) satisfies z.ZodType<User>;

export const createUserInputSchema = z.object({
  email: z.string().email(),
  name: z.string().min(1).max(100).optional(),
}) satisfies z.ZodType<CreateUserInput>;

// ❌ NEVER DO THIS:
// type User = z.infer<typeof userSchema>;  // FORBIDDEN
```

**Validation at Boundaries:**

```typescript
// src/adapters/inbound/trpc/user-router.ts
import { router, publicProcedure } from "../trpc";
import { createUserInputSchema, userSchema } from "../../../schemas/user";
import type { User, CreateUserInput } from "../../../types/user";

export const userRouter = router({
  create: publicProcedure
    .input(createUserInputSchema)  // Runtime validation
    .output(userSchema)            // Runtime validation
    .mutation(async ({ input }): Promise<User> => {
      // input is typed as CreateUserInput
      // return type is User
      return createUser(input);
    }),
});
```

### 6.4 tRPC 11.7.2

**Purpose:** End-to-end type-safe RPC between client and server.

**Rationale:**
- Zero code generation — types inferred from server
- Works with Zod for runtime validation
- Subscriptions for real-time
- Batching and caching built-in

**Server Setup with Hono:**

```typescript
// src/server/trpc.ts
import { initTRPC, TRPCError } from "@trpc/server";

const t = initTRPC.create();

export const router = t.router;
export const publicProcedure = t.procedure;

// src/server/routers/user.ts
import { router, publicProcedure } from "../trpc";
import { userSchema, createUserInputSchema } from "../schemas/user";
import type { User } from "../types/user";

export const userRouter = router({
  getById: publicProcedure
    .input(z.object({ id: z.string().uuid() }))
    .output(userSchema)
    .query(async ({ input }): Promise<User> => {
      const program = getUser(input.id).pipe(
        Effect.provide(DrizzleUserRepo),
        Effect.catchTag("UserNotFoundError", () =>
          Effect.fail(new TRPCError({ code: "NOT_FOUND" }))
        )
      );
      return Effect.runPromise(program);
    }),

  create: publicProcedure
    .input(createUserInputSchema)
    .output(userSchema)
    .mutation(async ({ input }): Promise<User> => {
      const program = createUser(input).pipe(
        Effect.provide(DrizzleUserRepo)
      );
      return Effect.runPromise(program);
    }),
});

// src/server/routers/index.ts
export const appRouter = router({
  user: userRouter,
});

export type AppRouter = typeof appRouter;
```

### 6.5 Hono 4.10.7

**Purpose:** Ultrafast, Web Standards-based HTTP framework.

**Rationale:**
- Zero dependencies, ~12kb minified
- Runs everywhere: Cloud Run, Bun, Node.js, Deno
- Web Standards (Request/Response)
- Built-in middleware ecosystem

**Usage:**

```typescript
import { Hono } from "hono";
import { cors } from "hono/cors";
import { logger } from "hono/logger";
import { serve } from "@hono/node-server";
import { trpcServer } from "@hono/trpc-server";
import { appRouter } from "./routers";

const app = new Hono();

// Middleware
app.use("*", logger());
app.use("*", cors());

// Health check (required for Cloud Run)
app.get("/health", (c) => c.json({ status: "ok" }));

// tRPC
app.use("/trpc/*", trpcServer({ router: appRouter }));

// Start server
const port = parseInt(process.env.PORT ?? "8080");
serve({ fetch: app.fetch, port });
```

### 6.6 Drizzle ORM 0.44.7 + Cloud SQL PostgreSQL

**Purpose:** Type-safe SQL query builder with managed PostgreSQL.

**Rationale:**
- SQL-first: write SQL, get types
- Zero runtime overhead
- Cloud SQL provides managed PostgreSQL with automatic backups
- Private VPC connection from Cloud Run

**Schema Definition:**

```typescript
// src/db/schema.ts
import { pgTable, text, timestamp, uuid } from "drizzle-orm/pg-core";

export const users = pgTable("users", {
  id: uuid("id").primaryKey().defaultRandom(),
  email: text("email").notNull().unique(),
  name: text("name"),
  createdAt: timestamp("created_at", { withTimezone: true })
    .notNull()
    .defaultNow(),
});

// Drizzle infers its own types for DB operations
export type DbUser = typeof users.$inferSelect;
export type DbNewUser = typeof users.$inferInsert;
```

**Database Connection:**

```typescript
// src/db/index.ts
import { drizzle } from "drizzle-orm/node-postgres";
import { Pool } from "pg";
import * as schema from "./schema";

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
});

export const db = drizzle(pool, { schema });
```

### 6.7 Google Cloud Pub/Sub

**Purpose:** Event streaming and async messaging.

**Rationale:**
- Fully managed, scales automatically
- At-least-once delivery with acknowledgment
- Dead letter queues for failed messages
- Integrates with Cloud Run via push subscriptions

**Publisher:**

```typescript
// src/types/events.ts — TypeScript types first
export interface UserCreatedEvent {
  readonly type: "user.created";
  readonly data: {
    readonly userId: string;
    readonly email: string;
    readonly createdAt: string;
  };
}

// src/schemas/events.ts — Zod schemas conform to types
import { z } from "zod";
import type { UserCreatedEvent } from "../types/events";

export const userCreatedEventSchema = z.object({
  type: z.literal("user.created"),
  data: z.object({
    userId: z.string().uuid(),
    email: z.string().email(),
    createdAt: z.string().datetime(),
  }),
}) satisfies z.ZodType<UserCreatedEvent>;

// src/services/events.ts
import { PubSub } from "@google-cloud/pubsub";
import { Effect, Context, Layer, Data } from "effect";

const pubsub = new PubSub();

interface EventPublisher {
  readonly publish: <T>(topic: string, event: T) => Effect.Effect<string, PublishError>;
}

class Events extends Context.Tag("Events")<Events, EventPublisher>() {}

class PublishError extends Data.TaggedError("PublishError")<{
  readonly cause: unknown;
}> {}

const PubSubEventsLive = Layer.succeed(Events, {
  publish: (topic, event) => Effect.tryPromise({
    try: async () => {
      const messageId = await pubsub
        .topic(topic)
        .publishMessage({ json: event });
      return messageId;
    },
    catch: (e) => new PublishError({ cause: e }),
  }),
});

export { Events, PubSubEventsLive };
```

### 6.8 Memorystore (Redis)

**Purpose:** Caching and rate limiting.

**Rationale:**
- Fully managed Redis 7.2
- Private VPC connection from Cloud Run
- Automatic failover and persistence

**Connection:**

```typescript
// src/services/cache.ts
import Redis from "ioredis";
import { Effect, Context, Layer, Data } from "effect";

const redis = new Redis(process.env.REDIS_URL!);

interface CacheService {
  readonly get: (key: string) => Effect.Effect<string | null, CacheError>;
  readonly set: (key: string, value: string, ttlSeconds?: number) => Effect.Effect<void, CacheError>;
  readonly del: (key: string) => Effect.Effect<void, CacheError>;
}

class Cache extends Context.Tag("Cache")<Cache, CacheService>() {}

class CacheError extends Data.TaggedError("CacheError")<{
  readonly cause: unknown;
}> {}

const RedisLive = Layer.succeed(Cache, {
  get: (key) => Effect.tryPromise({
    try: () => redis.get(key),
    catch: (e) => new CacheError({ cause: e }),
  }),
  set: (key, value, ttl) => Effect.tryPromise({
    try: async () => {
      if (ttl) {
        await redis.setex(key, ttl, value);
      } else {
        await redis.set(key, value);
      }
    },
    catch: (e) => new CacheError({ cause: e }),
  }),
  del: (key) => Effect.tryPromise({
    try: async () => { await redis.del(key); },
    catch: (e) => new CacheError({ cause: e }),
  }),
});

export { Cache, RedisLive };
```

### 6.9 React 19.2.1 + TanStack Router 1.140.0

**Purpose:** UI rendering and type-safe routing.

**Rationale:**
- React 19: Compiler optimizations, Activity API
- TanStack Router: File-based, type-safe routing
- XState handles all async state (no TanStack Query needed)

---

## 7. Layer 3: Operational

### 7.1 Vitest 4.0.15

**Purpose:** Fast, Vite-native unit and integration testing.

**Configuration:**

```typescript
// vitest.config.ts
import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    globals: true,
    environment: "node",
    include: ["src/**/*.test.ts"],
    coverage: {
      provider: "v8",
      reporter: ["text", "json", "html"],
      exclude: ["node_modules/", "src/**/*.test.ts"],
    },
    typecheck: {
      enabled: true,
    },
  },
});
```

### 7.2 Playwright 1.57.0

**Purpose:** End-to-end browser testing.

**Configuration:**

```typescript
// playwright.config.ts
import { defineConfig, devices } from "@playwright/test";

export default defineConfig({
  testDir: "./e2e",
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: "html",
  use: {
    baseURL: "http://localhost:8080",
    trace: "on-first-retry",
  },
  projects: [
    { name: "chromium", use: { ...devices["Desktop Chrome"] } },
    { name: "firefox", use: { ...devices["Desktop Firefox"] } },
    { name: "webkit", use: { ...devices["Desktop Safari"] } },
  ],
  webServer: {
    command: "bun run dev",
    url: "http://localhost:8080",
    reuseExistingServer: !process.env.CI,
  },
});
```

### 7.3 OXC (oxlint) 1.32.0

**Purpose:** Rust-based linter, 50-100x faster than ESLint.

**Configuration:**

```json
{
  "rules": {
    "no-unused-vars": "error",
    "no-console": "warn",
    "eqeqeq": "error",
    "no-var": "error",
    "prefer-const": "error"
  },
  "ignorePatterns": ["node_modules/", "dist/", "*.config.*"]
}
```

### 7.4 OpenTelemetry → Google Cloud Observability

**Purpose:** Vendor-neutral observability exported to GCP.

**Setup:**

```typescript
// src/lib/telemetry.ts
import { NodeSDK } from "@opentelemetry/sdk-node";
import { getNodeAutoInstrumentations } from "@opentelemetry/auto-instrumentations-node";
import { TraceExporter } from "@google-cloud/opentelemetry-cloud-trace-exporter";
import { Resource } from "@opentelemetry/resources";
import { ATTR_SERVICE_NAME, ATTR_SERVICE_VERSION } from "@opentelemetry/semantic-conventions";

const sdk = new NodeSDK({
  resource: new Resource({
    [ATTR_SERVICE_NAME]: "ember-api",
    [ATTR_SERVICE_VERSION]: process.env.npm_package_version ?? "0.0.0",
  }),
  traceExporter: new TraceExporter({
    projectId: process.env.GCP_PROJECT_ID,
  }),
  instrumentations: [getNodeAutoInstrumentations()],
});

sdk.start();

process.on("SIGTERM", () => {
  sdk.shutdown().then(() => process.exit(0));
});
```

### 7.5 PostHog 1.301.0

**Purpose:** Product analytics, A/B testing, feature flags.

**Setup:**

```typescript
// src/lib/posthog.ts
import { PostHog } from "posthog-node";

export const posthog = new PostHog(process.env.POSTHOG_API_KEY!, {
  host: process.env.POSTHOG_HOST ?? "https://app.posthog.com",
});

export function trackEvent(
  distinctId: string,
  event: string,
  properties?: Record<string, unknown>
) {
  posthog.capture({ distinctId, event, properties });
}

export async function isFeatureEnabled(
  distinctId: string,
  featureKey: string
): Promise<boolean> {
  return posthog.isFeatureEnabled(featureKey, distinctId) ?? false;
}
```

---

## 8. Architecture Patterns

### 8.1 Hexagonal Architecture with Effect-TS

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              APPLICATION CORE                                │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                         DOMAIN LAYER                                 │   │
│  │  - TypeScript types (src/types/) — SOURCE OF TRUTH                  │   │
│  │  - Zod schemas (src/schemas/) — runtime validation via satisfies    │   │
│  │  - Domain Errors (Data.TaggedError)                                 │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                         │
│                                    ▼                                         │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                         PORTS (Interfaces)                           │   │
│  │  - UserRepository: Context.Tag                                      │   │
│  │  - NotificationService: Context.Tag                                 │   │
│  │  - EventPublisher: Context.Tag                                      │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                         │
│                                    ▼                                         │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                      USE CASES / SERVICES                            │   │
│  │  - Effect.gen functions composing ports                             │   │
│  │  - Business logic with typed errors                                 │   │
│  │  - Tracing with Effect.withSpan()                                   │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                    ┌───────────────┼───────────────┐
                    ▼               ▼               ▼
┌─────────────────────────┐ ┌─────────────────────────┐ ┌─────────────────────────┐
│    ADAPTERS (Inbound)   │ │   ADAPTERS (Outbound)   │ │   ADAPTERS (Outbound)   │
│                         │ │                         │ │                         │
│  - Hono HTTP routes     │ │  - DrizzleUserRepo      │ │  - TwilioNotification   │
│  - tRPC procedures      │ │    (Layer)              │ │    (Layer)              │
│  - Pub/Sub handlers     │ │  - StripePayment        │ │  - PubSubEvents         │
│                         │ │    (Layer)              │ │    (Layer)              │
└─────────────────────────┘ └─────────────────────────┘ └─────────────────────────┘
```

### 8.2 Directory Structure

```
src/
├── types/                     # TypeScript types (SOURCE OF TRUTH)
│   ├── user.ts                # User, UserId, CreateUserInput
│   ├── order.ts
│   └── events.ts
├── schemas/                   # Zod schemas (satisfies TS types)
│   ├── user.ts                # userSchema, createUserInputSchema
│   ├── order.ts
│   └── events.ts
├── domain/                    # Domain layer
│   └── errors/                # Domain errors (Data.TaggedError)
├── ports/                     # Port interfaces (Context.Tag)
├── services/                  # Use cases / application services
├── adapters/                  # Adapter implementations (Layers)
│   ├── inbound/
│   │   ├── http/
│   │   ├── trpc/
│   │   └── pubsub/
│   └── outbound/
├── db/                        # Database
│   ├── schema.ts
│   └── migrations/
├── lib/                       # Infrastructure
└── index.ts                   # Application entry point
```

### 8.3 Type/Schema File Organization

```typescript
// src/types/user.ts — TypeScript types (SOURCE OF TRUTH)
export interface UserId extends String {
  readonly _brand: unique symbol;
}

export interface User {
  readonly id: UserId;
  readonly email: string;
  readonly name?: string;
  readonly createdAt: Date;
}

export interface CreateUserInput {
  readonly email: string;
  readonly name?: string;
}

// src/schemas/user.ts — Zod schemas (conform via satisfies)
import { z } from "zod";
import type { User, UserId, CreateUserInput } from "../types/user";

export const userIdSchema = z.string().uuid() satisfies z.ZodType<UserId>;

export const userSchema = z.object({
  id: userIdSchema,
  email: z.string().email(),
  name: z.string().min(1).max(100).optional(),
  createdAt: z.date(),
}) satisfies z.ZodType<User>;

export const createUserInputSchema = z.object({
  email: z.string().email(),
  name: z.string().min(1).max(100).optional(),
}) satisfies z.ZodType<CreateUserInput>;
```

---

## 9. File Structure

```
project-root/
├── .github/
│   └── workflows/
│       └── deploy.yml
├── config/
│   └── claude-code/
├── e2e/
├── infra/                      # Pulumi infrastructure
│   ├── index.ts                # Main Pulumi program
│   ├── package.json
│   ├── tsconfig.json
│   ├── Pulumi.yaml
│   ├── Pulumi.dev.yaml
│   └── Pulumi.prod.yaml
├── src/
│   ├── types/                  # TypeScript types (SOURCE OF TRUTH)
│   ├── schemas/                # Zod schemas (satisfies TS types)
│   ├── domain/
│   ├── ports/
│   ├── services/
│   ├── adapters/
│   ├── db/
│   ├── lib/
│   └── index.ts
├── .envrc
├── .sops.yaml
├── flake.nix
├── flake.lock
├── process-compose.yaml
├── Dockerfile
├── package.json
├── tsconfig.json
├── vitest.config.ts
├── playwright.config.ts
├── oxlint.config.json
└── drizzle.config.ts
```

---

## 10. Configuration Files

### 10.1 process-compose.yaml

```yaml
version: "0.6"

log_level: info
log_location: /tmp/process-compose.log

processes:
  app:
    command: bun run dev
    readiness_probe:
      http_get:
        host: localhost
        port: 8080
        path: /health
      initial_delay_seconds: 2
      period_seconds: 5
    depends_on:
      db:
        condition: process_healthy
      redis:
        condition: process_healthy

  db:
    command: |
      docker run --rm -p 5432:5432 \
        -e POSTGRES_USER=postgres \
        -e POSTGRES_PASSWORD=postgres \
        -e POSTGRES_DB=ember \
        postgres:16-alpine
    readiness_probe:
      exec:
        command: "pg_isready -h localhost -p 5432"
      initial_delay_seconds: 3
      period_seconds: 5

  redis:
    command: docker run --rm -p 6379:6379 redis:7.2-alpine
    readiness_probe:
      exec:
        command: "redis-cli ping"
      initial_delay_seconds: 2
      period_seconds: 5

  pubsub-emulator:
    command: |
      gcloud beta emulators pubsub start \
        --project=ember-local \
        --host-port=localhost:8085
    environment:
      - PUBSUB_EMULATOR_HOST=localhost:8085
```

### 10.2 flake.nix

```nix
{
  description = "Ember development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            nodejs_22
            bun
            postgresql_16
            redis
            google-cloud-sdk
            pulumi
            process-compose
            sops
            age
            docker
          ];

          shellHook = ''
            export PATH="$PWD/node_modules/.bin:$PATH"
            export PUBSUB_EMULATOR_HOST=localhost:8085
            echo "🚀 Development environment ready"
            echo "Run: process-compose up"
          '';
        };
      });
}
```

### 10.3 Dockerfile

```dockerfile
FROM node:25-alpine AS builder
WORKDIR /app
COPY package.json bun.lockb ./
RUN npm install
COPY . .
RUN npm run build

FROM node:25-alpine AS runner
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./
ENV PORT=8080
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1
CMD ["node", "dist/index.js"]
```

### 10.4 cloudbuild.yaml

```yaml
steps:
  - name: "node:25-alpine"
    entrypoint: "npm"
    args: ["ci"]

  - name: "node:25-alpine"
    entrypoint: "npm"
    args: ["run", "validate"]

  - name: "gcr.io/cloud-builders/docker"
    args:
      - "build"
      - "-t"
      - "${_REGION}-docker.pkg.dev/${PROJECT_ID}/${_REPO}/api:${SHORT_SHA}"
      - "-t"
      - "${_REGION}-docker.pkg.dev/${PROJECT_ID}/${_REPO}/api:latest"
      - "."

  - name: "gcr.io/cloud-builders/docker"
    args:
      - "push"
      - "--all-tags"
      - "${_REGION}-docker.pkg.dev/${PROJECT_ID}/${_REPO}/api"

  - name: "gcr.io/cloud-builders/gcloud"
    args:
      - "run"
      - "deploy"
      - "ember-api"
      - "--image"
      - "${_REGION}-docker.pkg.dev/${PROJECT_ID}/${_REPO}/api:${SHORT_SHA}"
      - "--region"
      - "${_REGION}"
      - "--platform"
      - "managed"
      - "--allow-unauthenticated"
      - "--set-secrets"
      - "DATABASE_URL=database-url:latest"
      - "--vpc-connector"
      - "ember-vpc-connector"

substitutions:
  _REGION: us-east1
  _REPO: ember

options:
  logging: CLOUD_LOGGING_ONLY
```

### 10.5 infra/Pulumi.yaml

```yaml
name: ember-infra
runtime: nodejs
description: Ember infrastructure on Google Cloud
```

### 10.6 package.json scripts

```json
{
  "scripts": {
    "dev": "bun run --hot src/index.ts",
    "build": "bun build src/index.ts --outdir dist --target node",
    "start": "node dist/index.js",
    "typecheck": "tsc --noEmit",
    "lint": "oxlint .",
    "lint:fix": "oxlint --fix .",
    "test": "vitest run",
    "test:watch": "vitest",
    "test:coverage": "vitest run --coverage",
    "test:e2e": "playwright test",
    "test:e2e:ui": "playwright test --ui",
    "validate": "bun run typecheck && bun run lint && bun run test",
    "db:generate": "drizzle-kit generate",
    "db:migrate": "drizzle-kit migrate",
    "db:studio": "drizzle-kit studio",
    "infra:preview": "cd infra && pulumi preview",
    "infra:up": "cd infra && pulumi up",
    "infra:destroy": "cd infra && pulumi destroy"
  }
}
```

---

## 11. Development Workflow

### 11.1 Daily Development

```bash
cd project-root
nix develop
process-compose up
# Separate terminal:
bun run test:watch
```

### 11.2 Before Commit

```bash
bun run validate
git add .
git commit -m "feat(auth): add phone verification"
```

### 11.3 Infrastructure Changes

```bash
cd infra
pulumi preview    # Review changes
pulumi up         # Apply changes
```

### 11.4 Deployment

```bash
git push origin main  # Triggers Cloud Build
```

---

## 12. Quality Gates

### 12.1 Every Code Change MUST

| Check | Command | Criteria |
|-------|---------|----------|
| Type Safety | `bun run typecheck` | Zero errors |
| Linting | `bun run lint` | Zero errors |
| Unit Tests | `bun run test` | All pass |
| E2E Tests | `bun run test:e2e` | All pass (CI only) |

### 12.2 Type/Schema Rules

- [ ] TypeScript type defined in `src/types/` (PascalCase: `User`)
- [ ] Zod schema defined in `src/schemas/` (camelCase: `userSchema`)
- [ ] Schema uses `satisfies z.ZodType<T>` to conform to TS type
- [ ] **NEVER** use `z.infer<>` to derive types

---

## Appendix A: Anti-Patterns

| ❌ Don't | ✅ Do |
|----------|-------|
| `z.infer<typeof schema>` | Define TS type first, schema `satisfies` type |
| `any` | `unknown` + type guards |
| `throw` for expected failures | Effect-TS typed errors |
| Multiple `useState` + `useEffect` | XState machine |
| TanStack Query for simple fetches | XState actors |
| ESLint/Prettier | OXC (oxlint) |
| Jest | Vitest |
| Express/Fastify | Hono |
| Prisma | Drizzle ORM |
| npm/yarn/pnpm | Bun |
| Docker Compose (dev) | Process Compose |
| Terraform | Pulumi (TypeScript) |
| Multiple cloud vendors | Consolidate to GCP |

---

## Appendix B: Google Cloud Resource Summary

| Resource | Name | Purpose |
|----------|------|---------|
| **Cloud Run** | `ember-api` | API server |
| **Cloud SQL** | `ember-postgres` | PostgreSQL 16 |
| **Memorystore** | `ember-redis` | Redis 7.2 cache |
| **Pub/Sub Topic** | `user-events` | User domain events |
| **Pub/Sub Topic** | `order-events` | Order domain events |
| **Artifact Registry** | `ember` | Container images |
| **Secret Manager** | `database-url` | DB connection string |
| **VPC Connector** | `ember-vpc-connector` | Private network access |

---

## Appendix: Temporal (Optional)

> **Status:** Optional. Use only if durable execution requirements exceed what Pub/Sub + Cloud Run can provide.

**When to Add Temporal:**
- Long-running workflows (>30 minutes)
- Human-in-the-loop workflows requiring signals
- Complex saga patterns with compensation
- Need for deterministic replay and time-travel debugging

**If Temporal is Needed:**

Add to versions.nix:
```nix
temporalio-client = "1.13.2";
temporalio-worker = "1.13.2";
temporalio-workflow = "1.13.2";
temporalio-activity = "1.13.2";
temporalio-common = "1.13.2";
temporalio-testing = "1.13.2";
```

Add to package.json:
```json
{
  "@temporalio/client": "1.13.2",
  "@temporalio/worker": "1.13.2",
  "@temporalio/workflow": "1.13.2",
  "@temporalio/activity": "1.13.2",
  "@temporalio/common": "1.13.2"
}
```

**Temporal Cloud Connection:**

```typescript
// src/temporal/client.ts
import { Client, Connection } from "@temporalio/client";

export async function createTemporalClient() {
  const connection = await Connection.connect({
    address: process.env.TEMPORAL_ADDRESS!,
    tls: {
      clientCertPair: {
        crt: Buffer.from(process.env.TEMPORAL_TLS_CERT!, "base64"),
        key: Buffer.from(process.env.TEMPORAL_TLS_KEY!, "base64"),
      },
    },
  });

  return new Client({
    connection,
    namespace: process.env.TEMPORAL_NAMESPACE!,
  });
}
```

**Workflow Example:**

```typescript
// src/temporal/workflows/phone-auth.ts
import { proxyActivities, sleep, defineSignal, setHandler } from "@temporalio/workflow";
import type * as activities from "../activities/phone-auth";

const { sendVerificationCode, verifyCode } = proxyActivities<typeof activities>({
  startToCloseTimeout: "30s",
  retry: { maximumAttempts: 3 },
});

export const codeEnteredSignal = defineSignal<[string]>("codeEntered");

export async function phoneAuthWorkflow(phoneNumber: string): Promise<{ success: boolean }> {
  let enteredCode: string | null = null;

  setHandler(codeEnteredSignal, (code) => {
    enteredCode = code;
  });

  const { code: expectedCode } = await sendVerificationCode(phoneNumber);

  const deadline = Date.now() + 5 * 60 * 1000;
  while (!enteredCode && Date.now() < deadline) {
    await sleep("5s");
  }

  if (!enteredCode) {
    return { success: false };
  }

  const isValid = await verifyCode(phoneNumber, enteredCode, expectedCode);
  return { success: isValid };
}
```

---

*This document is the authoritative source for all technology decisions. Any code or configuration that contradicts this spec is a bug.*
