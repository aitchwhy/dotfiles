# Tech Stack SSOT — December 2025

> **Single Source of Truth for all technology decisions, versions, and architectural patterns.**
> 
> This document is declarative: the running system MUST match this specification.
> Any drift between this spec and runtime is a bug to be corrected.

**Version:** 1.1.0  
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
| Durable Execution | Temporal Cloud* |

*Temporal Cloud is the only external managed service—GCP Workflows lacks equivalent capabilities (replay, signals, queries, deterministic execution).

### 1.3 Maximum Rigor Through Paradigms

| Paradigm | Tool | What It Eliminates |
|----------|------|-------------------|
| **Algebraic Effects** | Effect-TS | Untyped errors, hidden dependencies, race conditions |
| **Finite State Machines** | XState | Impossible states, state explosion, UI logic bugs |
| **Durable Execution** | Temporal | Lost updates, inconsistent state, debugging blind spots |
| **Parse Don't Validate** | Zod | Invalid data propagation |
| **Schema-First RPC** | tRPC | Client/server type drift |

### 1.4 Type Safety Hierarchy

```
Zod Schema (runtime) → TypeScript Type (compile-time) → Effect-TS (typed errors + DI)
```

**Rules:**
- Schema is ALWAYS the source of truth
- Types are ALWAYS inferred from schemas via `z.infer<>`
- No `any` — use `unknown` + type guards
- No type assertions without adjacent validation

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
│  Nix Flakes • nix-direnv • Process Compose • Secret Manager • Git           │
│  PURPOSE: Hermetic environments, secrets, version control                   │
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
│  Effect-TS • XState • tRPC • Hono • Temporal • Drizzle • Zod               │
│  PURPOSE: Business logic, state, API, persistence, workflows               │
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
# versions.nix — Generated from this document
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

  # ═══════════════════════════════════════════════════════════════════════════
  # LAYER 1: RUNTIME
  # ═══════════════════════════════════════════════════════════════════════════
  nodejs = "25.2.1";
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
  effect = "3.19.10";
  effect-platform = "0.72.0";
  effect-platform-node = "0.69.0";
  effect-schema = "0.99.0";
  xstate = "5.24.0";
  xstate-react = "6.0.0";
  xstate-store = "3.13.0";

  # ═══════════════════════════════════════════════════════════════════════════
  # LAYER 2: APPLICATION — Data Access (Google Cloud)
  # ═══════════════════════════════════════════════════════════════════════════
  drizzle-orm = "0.44.7";
  drizzle-kit = "0.30.0";
  pg = "8.13.0";                    # PostgreSQL driver
  google-cloud-pubsub = "4.9.0";   # Pub/Sub client
  ioredis = "5.4.1";               # Redis client for Memorystore

  # ═══════════════════════════════════════════════════════════════════════════
  # LAYER 2: APPLICATION — Durable Execution (Temporal Cloud)
  # ═══════════════════════════════════════════════════════════════════════════
  temporalio-client = "1.13.2";
  temporalio-worker = "1.13.2";
  temporalio-workflow = "1.13.2";
  temporalio-activity = "1.13.2";
  temporalio-common = "1.13.2";
  temporalio-testing = "1.13.2";

  # ═══════════════════════════════════════════════════════════════════════════
  # LAYER 2: APPLICATION — Authentication
  # ═══════════════════════════════════════════════════════════════════════════
  better-auth = "1.3.8";

  # ═══════════════════════════════════════════════════════════════════════════
  # LAYER 2: APPLICATION — Frontend
  # ═══════════════════════════════════════════════════════════════════════════
  react = "19.2.1";
  react-dom = "19.2.1";
  tanstack-router = "1.140.0";
  tailwindcss = "4.0.0";

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
  ast-grep = "0.30.0";

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
    "@temporalio/client": "1.13.2",
    "@temporalio/worker": "1.13.2",
    "@temporalio/workflow": "1.13.2",
    "@temporalio/activity": "1.13.2",
    "@temporalio/common": "1.13.2",
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
    "@temporalio/testing": "1.13.2",
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

### 3.3 Google Cloud Services

| Service | Purpose | Local Equivalent |
|---------|---------|------------------|
| **Cloud Run** | Container hosting (API, Workers) | Process Compose |
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

### 4.3 Secrets Management

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
- Required for Temporal Worker (uses Node-specific APIs)
- LTS track provides stability guarantees
- Wide ecosystem compatibility

**When to Use:**
- Production deployments on Cloud Run
- Temporal Workers (required)
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

**Limitations:**
- Temporal Worker requires Node.js (uses `worker_threads`, `vm`)
- Some native modules may have compatibility issues

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

// 1. Define context and events
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

### 6.3 tRPC 11.7.2

**Purpose:** End-to-end type-safe RPC between client and server.

**Rationale:**
- Zero code generation — types inferred from server
- Works with any validator (Zod, Effect Schema)
- Subscriptions for real-time
- Batching and caching built-in

**Server Setup with Hono:**

```typescript
// src/server/trpc.ts
import { initTRPC, TRPCError } from "@trpc/server";
import { z } from "zod";

const t = initTRPC.create();

export const router = t.router;
export const publicProcedure = t.procedure;

// src/server/routers/user.ts
import { router, publicProcedure } from "../trpc";
import { UserSchema } from "../schemas/user";

export const userRouter = router({
  getById: publicProcedure
    .input(z.object({ id: z.string().uuid() }))
    .output(UserSchema)
    .query(async ({ input }) => {
      const program = getUser(input.id).pipe(
        Effect.provide(DrizzleUserRepo),
        Effect.catchTag("UserNotFoundError", () =>
          Effect.fail(new TRPCError({ code: "NOT_FOUND" }))
        )
      );
      return Effect.runPromise(program);
    }),
});

// src/server/routers/index.ts
export const appRouter = router({
  user: userRouter,
});

export type AppRouter = typeof appRouter;

// src/server/index.ts
import { Hono } from "hono";
import { trpcServer } from "@hono/trpc-server";
import { appRouter } from "./routers";

const app = new Hono();
app.use("/trpc/*", trpcServer({ router: appRouter }));

export default app;
```

### 6.4 Hono 4.10.7

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

### 6.5 Temporal 1.13.2 (Temporal Cloud)

**Purpose:** Durable execution for long-running workflows.

**Rationale:**
- **Fault Tolerance:** Workflows survive crashes, restarts, deployments
- **Event Sourcing:** Complete audit trail of all executions
- **Time Travel:** Replay any historical execution exactly
- **Saga Pattern:** Automatic compensation for failed distributed transactions

**Why Temporal Cloud (not GCP Workflows):**
- Deterministic replay (GCP Workflows lacks this)
- Signals and queries for workflow interaction
- Local activities for low-latency operations
- TypeScript SDK with full type safety

**Connection Setup:**

```typescript
// src/temporal/client.ts
import { Client, Connection } from "@temporalio/client";

export async function createTemporalClient() {
  const connection = await Connection.connect({
    address: process.env.TEMPORAL_ADDRESS!, // e.g., "namespace.tmprl.cloud:7233"
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

  const deadline = Date.now() + 5 * 60 * 1000; // 5 minutes
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

**Worker Setup (runs on Cloud Run):**

```typescript
// src/temporal/worker.ts
import { Worker, NativeConnection } from "@temporalio/worker";
import * as activities from "./activities/phone-auth";

async function run() {
  const connection = await NativeConnection.connect({
    address: process.env.TEMPORAL_ADDRESS!,
    tls: {
      clientCertPair: {
        crt: Buffer.from(process.env.TEMPORAL_TLS_CERT!, "base64"),
        key: Buffer.from(process.env.TEMPORAL_TLS_KEY!, "base64"),
      },
    },
  });

  const worker = await Worker.create({
    connection,
    namespace: process.env.TEMPORAL_NAMESPACE!,
    taskQueue: "phone-auth",
    workflowsPath: require.resolve("./workflows/phone-auth"),
    activities,
  });

  await worker.run();
}

run().catch(console.error);
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

export type User = typeof users.$inferSelect;
export type NewUser = typeof users.$inferInsert;
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
// src/services/events.ts
import { PubSub } from "@google-cloud/pubsub";
import { Effect, Context, Layer, Data } from "effect";
import { z } from "zod";

const pubsub = new PubSub();

export const UserCreatedSchema = z.object({
  type: z.literal("user.created"),
  data: z.object({
    userId: z.string().uuid(),
    email: z.string().email(),
    createdAt: z.string().datetime(),
  }),
});

export type UserCreatedEvent = z.infer<typeof UserCreatedSchema>;

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

### 6.9 Zod 4.1.13

**Purpose:** Runtime validation with static type inference.

**Rationale:**
- Schema-first: define once, use everywhere
- Runtime validation at boundaries
- TypeScript inference via `z.infer<>`
- Excellent error messages

**Schema Definition:**

```typescript
// src/schemas/user.ts
import { z } from "zod";

export const UserIdSchema = z.string().uuid().brand<"UserId">();
export type UserId = z.infer<typeof UserIdSchema>;

export const UserSchema = z.object({
  id: UserIdSchema,
  email: z.string().email(),
  name: z.string().min(1).max(100).optional(),
  createdAt: z.date(),
});

export type User = z.infer<typeof UserSchema>;

export const CreateUserSchema = UserSchema.omit({ id: true, createdAt: true });
export type CreateUser = z.infer<typeof CreateUserSchema>;
```

### 6.10 React 19.2.1 + TanStack Router 1.140.0

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

**Structured Logging (Cloud Logging):**

```typescript
// src/lib/logger.ts
import { Effect } from "effect";

interface LogEntry {
  severity: "DEBUG" | "INFO" | "WARNING" | "ERROR";
  message: string;
  [key: string]: unknown;
}

export const log = (entry: LogEntry) => Effect.sync(() => {
  console.log(JSON.stringify({
    ...entry,
    timestamp: new Date().toISOString(),
    "logging.googleapis.com/trace": process.env.TRACE_ID,
  }));
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
│  │  - Entities (User, Order, etc.)                                     │   │
│  │  - Value Objects (UserId, Email, etc.)                              │   │
│  │  - Domain Events                                                    │   │
│  │  - Domain Errors (UserNotFoundError, etc.)                          │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                         │
│                                    ▼                                         │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                         PORTS (Interfaces)                           │   │
│  │  - UserRepository: Context.Tag                                      │   │
│  │  - NotificationService: Context.Tag                                 │   │
│  │  - PaymentGateway: Context.Tag                                      │   │
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
│  - Temporal workflows   │ │  - StripePayment        │ │  - PubSubEvents         │
│  - Pub/Sub handlers     │ │    (Layer)              │ │    (Layer)              │
└─────────────────────────┘ └─────────────────────────┘ └─────────────────────────┘
```

### 8.2 Directory Structure

```
src/
├── domain/                    # Domain layer (pure)
│   ├── entities/
│   ├── values/
│   ├── errors/
│   └── events/
├── ports/                     # Port interfaces (Context.Tag)
├── services/                  # Use cases / application services
├── adapters/                  # Adapter implementations (Layers)
│   ├── inbound/
│   │   ├── http/
│   │   ├── trpc/
│   │   ├── temporal/
│   │   └── pubsub/
│   └── outbound/
├── schemas/                   # Zod schemas (source of truth)
├── db/                        # Database
│   ├── schema.ts
│   └── migrations/
├── lib/                       # Infrastructure
└── index.ts                   # Application entry point
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
├── infra/
│   ├── terraform/
│   │   ├── main.tf
│   │   ├── cloud-run.tf
│   │   ├── cloud-sql.tf
│   │   ├── memorystore.tf
│   │   ├── pubsub.tf
│   │   └── secrets.tf
│   └── cloudbuild.yaml
├── src/
├── temporal/
│   ├── workflows/
│   ├── activities/
│   └── worker.ts
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
      temporal:
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

  temporal:
    command: temporal server start-dev --db-filename /tmp/temporal.db
    readiness_probe:
      http_get:
        host: localhost
        port: 7233
        path: /health
      initial_delay_seconds: 5
      period_seconds: 10

  temporal-worker:
    command: bun run temporal:worker
    depends_on:
      temporal:
        condition: process_healthy
      app:
        condition: process_healthy

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
            temporal-cli
            google-cloud-sdk
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
      - "DATABASE_URL=database-url:latest,TEMPORAL_TLS_CERT=temporal-cert:latest,TEMPORAL_TLS_KEY=temporal-key:latest"
      - "--vpc-connector"
      - "ember-vpc-connector"

substitutions:
  _REGION: us-east1
  _REPO: ember

options:
  logging: CLOUD_LOGGING_ONLY
```

### 10.5 package.json scripts

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
    "temporal:worker": "bun run temporal/worker.ts"
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
git commit -m "feat(auth): add phone verification workflow"
```

### 11.3 Deployment

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

---

## Appendix A: Anti-Patterns

| ❌ Don't | ✅ Do |
|----------|-------|
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
| Multiple cloud vendors | Consolidate to GCP |
| Self-managed databases | Cloud SQL |
| Self-managed Redis | Memorystore |
| Self-managed Kafka | Pub/Sub |

---

## Appendix B: Google Cloud Resource Summary

| Resource | Name | Purpose |
|----------|------|---------|
| **Cloud Run** | `ember-api` | API server |
| **Cloud Run** | `ember-temporal-worker` | Temporal worker |
| **Cloud SQL** | `ember-postgres` | PostgreSQL 16 |
| **Memorystore** | `ember-redis` | Redis 7.2 cache |
| **Pub/Sub Topic** | `user-events` | User domain events |
| **Pub/Sub Topic** | `order-events` | Order domain events |
| **Artifact Registry** | `ember` | Container images |
| **Secret Manager** | `database-url` | DB connection string |
| **Secret Manager** | `temporal-cert` | Temporal TLS cert |
| **Secret Manager** | `temporal-key` | Temporal TLS key |
| **VPC Connector** | `ember-vpc-connector` | Private network access |

---

*This document is the authoritative source for all technology decisions. Any code or configuration that contradicts this spec is a bug.*
