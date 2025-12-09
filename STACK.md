# Tech Stack SSOT — December 2025

> **Single Source of Truth for all technology decisions, versions, and architectural patterns.**
> 
> This document is declarative: the running system MUST match this specification.
> Any drift between this spec and runtime is a bug to be corrected.

**Version:** 1.0.0  
**Last Updated:** December 9, 2025  
**Owner:** Hank Kim

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
- **nix2container** for identical production images
- **SOPS + Age** for encrypted secrets in git

### 1.2 Maximum Rigor Through Paradigms

| Paradigm | Tool | What It Eliminates |
|----------|------|-------------------|
| **Algebraic Effects** | Effect-TS | Untyped errors, hidden dependencies, race conditions |
| **Finite State Machines** | XState | Impossible states, state explosion, UI logic bugs |
| **Durable Execution** | Temporal | Lost updates, inconsistent state, debugging blind spots |
| **Parse Don't Validate** | Zod | Invalid data propagation |
| **Schema-First RPC** | tRPC | Client/server type drift |

### 1.3 Type Safety Hierarchy

```
Zod Schema (runtime) → TypeScript Type (compile-time) → Effect-TS (typed errors + DI)
```

**Rules:**
- Schema is ALWAYS the source of truth
- Types are ALWAYS inferred from schemas via `z.infer<>`
- No `any` — use `unknown` + type guards
- No type assertions without adjacent validation

### 1.4 Error Handling Philosophy

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
│  Nix Flakes • nix-direnv • Process Compose • SOPS • Git                     │
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
│  Vitest • Playwright • OXC • OpenTelemetry • GitHub Actions • Fly.io       │
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
  sops = "3.9.0";
  age = "1.2.0";

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
  # LAYER 2: APPLICATION — Data Access
  # ═══════════════════════════════════════════════════════════════════════════
  drizzle-orm = "0.44.7";
  drizzle-kit = "0.30.0";
  libsql-client = "0.14.0";

  # ═══════════════════════════════════════════════════════════════════════════
  # LAYER 2: APPLICATION — Durable Execution
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
  # LAYER 3: OPERATIONAL — Observability
  # ═══════════════════════════════════════════════════════════════════════════
  opentelemetry-sdk-node = "1.28.0";
  opentelemetry-auto-instrumentations-node = "0.52.0";
  opentelemetry-exporter-trace-otlp-http = "0.56.0";
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
    "@libsql/client": "0.14.0",
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
    "@opentelemetry/exporter-trace-otlp-http": "0.56.0",
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
    "posthog-js": "1.301.0"
  }
}
```

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
- Configuration mirrors production topology

**Usage:**
```bash
process-compose up        # Start all services
process-compose up -d     # Start detached
process-compose down      # Stop all services
process-compose logs app  # View app logs
```

### 4.3 SOPS + Age

**Purpose:** Encrypted secrets stored in git, decrypted at runtime.

**Rationale:**
- Secrets are version-controlled alongside code
- Age provides modern, simple key management
- SOPS supports partial encryption (encrypt values, not keys)
- Works with Nix, GitHub Actions, and local development

**Key Files:**
- `.sops.yaml` — Encryption rules and key references
- `secrets/` — Encrypted secret files

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
- Production deployments
- Temporal Workers (required)
- When Bun compatibility issues arise

### 5.2 Bun 1.3.4

**Purpose:** Fast all-in-one toolkit for development.

**Rationale:**
- 30x faster package installs than npm
- Built-in bundler, test runner, TypeScript support
- Native SQLite, Redis clients
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

**When to Use:**
- All backend business logic
- Service definitions and dependency injection
- Error handling for expected failures
- Concurrent operations with resource management

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

**When to Use:**
- All UI state that has distinct modes (loading, success, error, etc.)
- Multi-step flows (wizards, onboarding, checkout)
- Complex interactions with multiple states
- Any state that would otherwise use multiple `useState` + `useEffect`

**When NOT to Use:**
- Simple boolean toggles
- Form field values (use native form state or simple store)

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
      // Effect-TS integration
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

**Client Setup:**

```typescript
// src/client/trpc.ts
import { createTRPCClient, httpBatchLink } from "@trpc/client";
import type { AppRouter } from "../server/routers";

export const trpc = createTRPCClient<AppRouter>({
  links: [
    httpBatchLink({
      url: "/trpc",
    }),
  ],
});

// Usage in XState actor
const fetchUser = fromPromise(async ({ input }: { input: { userId: string } }) => {
  return trpc.user.getById.query({ id: input.userId });
});
```

### 6.4 Hono 4.10.7

**Purpose:** Ultrafast, Web Standards-based HTTP framework.

**Rationale:**
- Zero dependencies, ~12kb minified
- Runs everywhere: Cloudflare Workers, Bun, Node.js, Deno
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

// Health check
app.get("/health", (c) => c.json({ status: "ok" }));

// tRPC
app.use("/trpc/*", trpcServer({ router: appRouter }));

// Start server
serve({ fetch: app.fetch, port: 8080 });
```

### 6.5 Temporal 1.13.2

**Purpose:** Durable execution for long-running workflows.

**Rationale:**
- **Fault Tolerance:** Workflows survive crashes, restarts, deployments
- **Event Sourcing:** Complete audit trail of all executions
- **Time Travel:** Replay any historical execution exactly
- **Saga Pattern:** Automatic compensation for failed distributed transactions

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

  // Send verification code
  const { code: expectedCode } = await sendVerificationCode(phoneNumber);

  // Wait for user to enter code (with timeout)
  const deadline = Date.now() + 5 * 60 * 1000; // 5 minutes
  while (!enteredCode && Date.now() < deadline) {
    await sleep("5s");
  }

  if (!enteredCode) {
    return { success: false }; // Timeout
  }

  // Verify code
  const isValid = await verifyCode(phoneNumber, enteredCode, expectedCode);
  return { success: isValid };
}

// src/temporal/activities/phone-auth.ts
import { Effect } from "effect";
import { TwilioService } from "../../services/twilio";

export async function sendVerificationCode(phoneNumber: string) {
  const program = Effect.gen(function* () {
    const twilio = yield* TwilioService;
    const code = Math.random().toString().slice(2, 8);
    yield* twilio.sendSms(phoneNumber, `Your code: ${code}`);
    return { code };
  }).pipe(Effect.provide(TwilioLive));

  return Effect.runPromise(program);
}
```

**Worker Setup:**

```typescript
// src/temporal/worker.ts
import { Worker, NativeConnection } from "@temporalio/worker";
import * as activities from "./activities/phone-auth";

async function run() {
  const connection = await NativeConnection.connect({ address: "localhost:7233" });

  const worker = await Worker.create({
    connection,
    namespace: "default",
    taskQueue: "phone-auth",
    workflowsPath: require.resolve("./workflows/phone-auth"),
    activities,
  });

  await worker.run();
}

run().catch(console.error);
```

### 6.6 Drizzle ORM 0.44.7

**Purpose:** Type-safe SQL query builder and ORM.

**Rationale:**
- SQL-first: write SQL, get types
- Zero runtime overhead
- Works with SQLite, PostgreSQL, MySQL
- Migrations with `drizzle-kit`

**Schema Definition:**

```typescript
// src/db/schema.ts
import { sqliteTable, text, integer } from "drizzle-orm/sqlite-core";
import { createId } from "@paralleldrive/cuid2";

export const users = sqliteTable("users", {
  id: text("id").primaryKey().$defaultFn(() => createId()),
  email: text("email").notNull().unique(),
  name: text("name"),
  createdAt: integer("created_at", { mode: "timestamp" })
    .notNull()
    .$defaultFn(() => new Date()),
});

export type User = typeof users.$inferSelect;
export type NewUser = typeof users.$inferInsert;
```

**Integration with Effect-TS:**

```typescript
// src/services/database.ts
import { Effect, Context, Layer } from "effect";
import { drizzle } from "drizzle-orm/libsql";
import { createClient } from "@libsql/client";
import * as schema from "../db/schema";

interface DatabaseService {
  readonly db: ReturnType<typeof drizzle>;
}

class Database extends Context.Tag("Database")<Database, DatabaseService>() {}

const DatabaseLive = Layer.sync(Database, () => ({
  db: drizzle(createClient({ url: process.env.DATABASE_URL! }), { schema }),
}));

export { Database, DatabaseLive };
```

### 6.7 Zod 4.1.13

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

### 6.8 React 19.2.1 + TanStack Router 1.140.0

**Purpose:** UI rendering and type-safe routing.

**Rationale:**
- React 19: Compiler optimizations, Activity API
- TanStack Router: File-based, type-safe routing
- XState handles all async state (no TanStack Query needed)

---

## 7. Layer 3: Operational

### 7.1 Vitest 4.0.15

**Purpose:** Fast, Vite-native unit and integration testing.

**Rationale:**
- Native ESM support
- Compatible with Jest API
- Browser Mode for component testing (stable in v4)
- Built-in visual regression testing

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

**Rationale:**
- Cross-browser: Chromium, Firefox, WebKit
- Auto-wait and retry for reliable tests
- Trace viewer for debugging
- Chrome for Testing builds (as of 1.57)

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

**Rationale:**
- Blazing fast (Rust-based)
- 600+ rules
- Drop-in ESLint replacement
- No configuration needed for defaults

**Configuration:**

```json
// oxlint.config.json
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

### 7.4 OpenTelemetry 1.28.0

**Purpose:** Vendor-neutral observability (traces, metrics, logs).

**Rationale:**
- Standard protocol, works with any backend
- Auto-instrumentation for common libraries
- Effect-TS integration via `Effect.withSpan()`
- Export to Datadog, Jaeger, or any OTLP collector

**Setup:**

```typescript
// src/lib/telemetry.ts
import { NodeSDK } from "@opentelemetry/sdk-node";
import { getNodeAutoInstrumentations } from "@opentelemetry/auto-instrumentations-node";
import { OTLPTraceExporter } from "@opentelemetry/exporter-trace-otlp-http";
import { Resource } from "@opentelemetry/resources";
import { ATTR_SERVICE_NAME, ATTR_SERVICE_VERSION } from "@opentelemetry/semantic-conventions";

const sdk = new NodeSDK({
  resource: new Resource({
    [ATTR_SERVICE_NAME]: "ember-api",
    [ATTR_SERVICE_VERSION]: process.env.npm_package_version ?? "0.0.0",
  }),
  traceExporter: new OTLPTraceExporter({
    url: process.env.OTEL_EXPORTER_OTLP_ENDPOINT ?? "http://localhost:4318/v1/traces",
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

**Rationale:**
- Open-source, self-hostable
- Session recording
- Feature flags with gradual rollout
- Funnel analysis

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
│  - Temporal workflows   │ │  - StripePayment        │ │  - SendGridEmail        │
│                         │ │    (Layer)              │ │    (Layer)              │
└─────────────────────────┘ └─────────────────────────┘ └─────────────────────────┘
```

### 8.2 Directory Structure

```
src/
├── domain/                    # Domain layer (pure)
│   ├── entities/              # Domain entities
│   │   └── user.ts
│   ├── values/                # Value objects + branded types
│   │   └── user-id.ts
│   ├── errors/                # Domain errors (Data.TaggedError)
│   │   └── user-errors.ts
│   └── events/                # Domain events
│       └── user-events.ts
│
├── ports/                     # Port interfaces (Context.Tag)
│   ├── user-repository.ts
│   ├── notification-service.ts
│   └── payment-gateway.ts
│
├── services/                  # Use cases / application services
│   ├── user-service.ts
│   └── order-service.ts
│
├── adapters/                  # Adapter implementations (Layers)
│   ├── inbound/
│   │   ├── http/              # Hono routes
│   │   │   └── user-routes.ts
│   │   ├── trpc/              # tRPC routers
│   │   │   └── user-router.ts
│   │   └── temporal/          # Temporal workflows
│   │       └── phone-auth.ts
│   └── outbound/
│       ├── drizzle-user-repo.ts
│       ├── twilio-notification.ts
│       └── stripe-payment.ts
│
├── schemas/                   # Zod schemas (source of truth)
│   ├── user.ts
│   └── order.ts
│
├── db/                        # Database
│   ├── schema.ts              # Drizzle schema
│   └── migrations/
│
├── lib/                       # Infrastructure
│   ├── telemetry.ts           # OpenTelemetry setup
│   └── posthog.ts             # Analytics
│
└── index.ts                   # Application entry point
```

### 8.3 State Machine Pattern for UI

Every UI flow with distinct states MUST use XState:

```typescript
// Pattern: Fetch Machine
const fetchMachine = createMachine({
  id: "fetch",
  initial: "idle",
  context: { data: null, error: null },
  states: {
    idle: { on: { FETCH: "loading" } },
    loading: {
      invoke: {
        src: "fetchData",
        onDone: { target: "success", actions: "setData" },
        onError: { target: "failure", actions: "setError" },
      },
    },
    success: { on: { REFRESH: "loading" } },
    failure: { on: { RETRY: "loading" } },
  },
});

// Pattern: Multi-step Flow
const wizardMachine = createMachine({
  id: "wizard",
  initial: "step1",
  context: { step1Data: null, step2Data: null },
  states: {
    step1: {
      on: {
        NEXT: { target: "step2", actions: "saveStep1" },
      },
    },
    step2: {
      on: {
        BACK: "step1",
        NEXT: { target: "step3", actions: "saveStep2" },
      },
    },
    step3: {
      on: {
        BACK: "step2",
        SUBMIT: "submitting",
      },
    },
    submitting: {
      invoke: {
        src: "submitWizard",
        onDone: "complete",
        onError: "step3",
      },
    },
    complete: { type: "final" },
  },
});
```

---

## 9. File Structure

```
project-root/
├── .github/
│   └── workflows/
│       └── ci.yml              # GitHub Actions CI/CD
│
├── config/
│   └── claude-code/            # AI assistant configuration
│       ├── CLAUDE.md
│       └── skills/
│
├── e2e/                        # Playwright E2E tests
│   └── auth.spec.ts
│
├── src/                        # Application source (see 8.2)
│
├── temporal/                   # Temporal workflows (separate for Worker)
│   ├── workflows/
│   ├── activities/
│   └── worker.ts
│
├── .envrc                      # Direnv: `use flake`
├── .sops.yaml                  # SOPS encryption config
├── flake.nix                   # Nix flake
├── flake.lock                  # Pinned Nix dependencies
├── process-compose.yaml        # Local service orchestration
├── fly.toml                    # Fly.io deployment config
├── package.json                # npm dependencies
├── tsconfig.json               # TypeScript config
├── vitest.config.ts            # Vitest config
├── playwright.config.ts        # Playwright config
├── oxlint.config.json          # OXC linter config
└── drizzle.config.ts           # Drizzle ORM config
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
      temporal:
        condition: process_healthy

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

  db:
    command: turso dev --db-file /tmp/local.db
    readiness_probe:
      exec:
        command: "turso db shell /tmp/local.db 'SELECT 1'"
      initial_delay_seconds: 2
      period_seconds: 5

  otel-collector:
    command: otelcol --config /etc/otel-collector-config.yaml
    environment:
      - OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318
```

### 10.2 flake.nix

```nix
{
  description = "Project development environment";

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
            # Runtime
            nodejs_22  # Use 22 LTS for stability; 25 when available in nixpkgs
            bun
            
            # Database
            turso-cli
            
            # Temporal
            temporal-cli
            
            # Tools
            process-compose
            sops
            age
            
            # Observability
            otel-collector
          ];

          shellHook = ''
            export PATH="$PWD/node_modules/.bin:$PATH"
            echo "🚀 Development environment ready"
          '';
        };
      });
}
```

### 10.3 tsconfig.json

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
    "sourceMap": true,
    "outDir": "dist",
    "rootDir": "src",
    "baseUrl": ".",
    "paths": {
      "@/*": ["src/*"]
    }
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

### 10.4 package.json scripts

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
# 1. Enter development environment
cd project-root
# nix-direnv auto-activates, or manually:
nix develop

# 2. Start all services
process-compose up

# 3. Run tests in watch mode (separate terminal)
bun run test:watch

# 4. View Temporal UI
open http://localhost:8233

# 5. View app
open http://localhost:8080
```

### 11.2 Before Commit

```bash
# Run full validation
bun run validate

# If all passes, commit with conventional format
git add .
git commit -m "feat(auth): add phone verification workflow"
```

### 11.3 TDD Cycle

1. **Red:** Write failing test that defines expected behavior
2. **Green:** Write minimal code to make test pass
3. **Refactor:** Improve code while keeping tests green
4. **Verify:** Run `bun run validate`

### 11.4 Adding a New Feature

1. Define Zod schema in `src/schemas/`
2. Create domain error if needed in `src/domain/errors/`
3. Define port interface in `src/ports/`
4. Implement use case in `src/services/`
5. Create adapter in `src/adapters/`
6. Add tRPC procedure in `src/adapters/inbound/trpc/`
7. Create XState machine for UI flow
8. Write tests at each layer

---

## 12. Quality Gates

### 12.1 Every Code Change MUST

| Check | Command | Criteria |
|-------|---------|----------|
| Type Safety | `bun run typecheck` | Zero errors |
| Linting | `bun run lint` | Zero errors |
| Unit Tests | `bun run test` | All pass |
| E2E Tests | `bun run test:e2e` | All pass (CI only) |

### 12.2 Every New File MUST

- [ ] Have explicit types (no inferred `any`)
- [ ] Export schemas before types
- [ ] Use Result types for fallible functions (Effect-TS)
- [ ] Have corresponding test file

### 12.3 CI Pipeline

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: DeterminateSystems/nix-installer-action@main
      - uses: DeterminateSystems/magic-nix-cache-action@main
      - run: nix develop --command bun install
      - run: nix develop --command bun run typecheck
      - run: nix develop --command bun run lint
      - run: nix develop --command bun run test

  e2e:
    runs-on: ubuntu-latest
    needs: validate
    steps:
      - uses: actions/checkout@v4
      - uses: DeterminateSystems/nix-installer-action@main
      - uses: DeterminateSystems/magic-nix-cache-action@main
      - run: nix develop --command bun install
      - run: nix develop --command npx playwright install --with-deps
      - run: nix develop --command bun run test:e2e

  deploy:
    runs-on: ubuntu-latest
    needs: [validate, e2e]
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4
      - uses: superfly/flyctl-actions/setup-flyctl@master
      - run: flyctl deploy --remote-only
        env:
          FLY_API_TOKEN: ${{ secrets.FLY_API_TOKEN }}
```

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
| Trigger.dev | Temporal |
| Manual retries | Temporal automatic retries |
| Inline SQL | Drizzle type-safe queries |
| `null` | `undefined` |
| Magic numbers | Named constants |
| Commented-out code | Delete it |
| `console.log` debugging | OpenTelemetry traces |

---

## Appendix B: Quick Reference

### Effect-TS Cheatsheet

```typescript
// Create effects
Effect.succeed(value)           // Success
Effect.fail(error)              // Failure
Effect.sync(() => value)        // Sync computation
Effect.tryPromise({ try, catch }) // Promise with error handling
Effect.gen(function* () { })    // Generator syntax

// Compose effects
Effect.map(effect, fn)          // Transform success
Effect.flatMap(effect, fn)      // Chain effects
Effect.catchTag("Tag", handler) // Handle specific error
Effect.provide(layer)           // Inject dependencies
Effect.withSpan("name")         // Add tracing

// Run effects
Effect.runSync(effect)          // Sync execution
Effect.runPromise(effect)       // Async execution
Effect.runPromiseExit(effect)   // Get Exit (success or failure)
```

### XState Cheatsheet

```typescript
// Create machine
createMachine({ id, initial, context, states })

// State definition
{ on: { EVENT: "target" } }     // Simple transition
{ on: { EVENT: { target, actions, guard } } } // Full transition
{ invoke: { src, onDone, onError } } // Async invocation
{ entry: [], exit: [] }         // Lifecycle actions

// Actions
assign({ key: value })          // Update context
assign({ key: (ctx, event) => value }) // Dynamic update
raise({ type: "EVENT" })        // Send event to self
sendTo(actorRef, event)         // Send to another actor

// React integration
const [state, send] = useMachine(machine)
state.matches("loading")        // Check current state
state.context.data              // Access context
send({ type: "FETCH" })         // Send event
```

### Temporal Cheatsheet

```typescript
// Workflow
export async function myWorkflow(input: Input): Promise<Output> {
  const result = await myActivity(input);
  await sleep("1 hour");
  return result;
}

// Activity
export async function myActivity(input: Input): Promise<Output> {
  // Side effects go here
}

// Signals
export const mySignal = defineSignal<[string]>("mySignal");
setHandler(mySignal, (value) => { /* handle */ });

// Queries
export const myQuery = defineQuery<string>("myQuery");
setHandler(myQuery, () => currentState);

// Client
const handle = await client.workflow.start(myWorkflow, {
  taskQueue: "my-queue",
  workflowId: "unique-id",
  args: [input],
});
await handle.signal(mySignal, "value");
const result = await handle.result();
```

---

*This document is the authoritative source for all technology decisions. Any code or configuration that contradicts this spec is a bug.*
