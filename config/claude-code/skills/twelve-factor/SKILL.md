---
name: twelve-factor
description: 12-Factor App methodology applied to Nix dotfiles and modern TypeScript. Reproducible builds, environment config, dev/prod parity.
allowed-tools: Read, Write, Edit, Grep, Glob, Bash
---

# Twelve-Factor App Patterns for Nix + TypeScript

The [Twelve-Factor App](https://12factor.net) methodology, adapted for dotfiles management and TypeScript development.

## I. Codebase: One Repo, Many Deploys

**Principle**: One codebase tracked in version control, many deploys.

```
# Dotfiles structure - single repo for all machines
~/dotfiles/
  flake.nix                    # Entry point
  flake.lock                   # Pinned dependencies
  hosts/
    hank-mbp-m4/              # Machine-specific config
    work-laptop/
  modules/                     # Shared modules
  users/                       # User configurations
```

Each machine is a "deploy" of the same codebase:

```nix
# flake.nix
{
  outputs = { nixpkgs, darwin, home-manager, ... }: {
    darwinConfigurations = {
      "hank-mbp-m4" = darwin.lib.darwinSystem { ... };
      "work-laptop" = darwin.lib.darwinSystem { ... };
    };
  };
}
```

## II. Dependencies: Explicitly Declare and Isolate

**Principle**: Never rely on implicit system-wide packages.

```nix
# Bad: assumes system has curl installed
environment.systemPackages = [ pkgs.jq ];
# Then in a script: curl ... | jq ...

# Good: explicitly declare all dependencies
environment.systemPackages = with pkgs; [
  curl
  jq
];
```

For development shells:

```nix
# flake.nix devShell
devShells.default = pkgs.mkShell {
  packages = with pkgs; [
    bun
    biome
    typescript
    # Every tool the project needs
  ];
};
```

## III. Config: Store in Environment

**Principle**: Configuration that varies between deploys belongs in environment.

```typescript
// Bad: hardcoded configuration
const API_URL = 'https://api.production.com';
const DB_HOST = 'localhost';

// Good: environment-driven configuration
const config = {
  apiUrl: process.env.API_URL ?? 'http://localhost:3000',
  dbHost: process.env.DB_HOST ?? 'localhost',
  dbPort: parseInt(process.env.DB_PORT ?? '5432', 10),
} as const;
```

For Nix, use module options:

```nix
# modules/services/api.nix
{ config, lib, ... }:
let
  inherit (lib) mkOption types;
  cfg = config.services.api;
in
{
  options.services.api = {
    apiUrl = mkOption {
      type = types.str;
      description = "API endpoint URL";
    };
    environment = mkOption {
      type = types.enum [ "development" "staging" "production" ];
      default = "development";
    };
  };
}
```

## IV. Backing Services: Treat as Attached Resources

**Principle**: Databases, caches, APIs are attached resources swapped via config.

```typescript
// Abstract over the backing service
interface CacheService {
  get(key: string): Promise<Result<string | null, Error>>;
  set(key: string, value: string, ttl?: number): Promise<Result<void, Error>>;
}

// Implementations can be swapped
const cache: CacheService = process.env.NODE_ENV === 'production'
  ? new RedisCache(process.env.REDIS_URL!)
  : new InMemoryCache();
```

## V. Build, Release, Run: Strict Separation

**Principle**: Strictly separate build, release, and run stages.

```bash
# Build: Convert code to executable bundle
nix build .#darwinConfigurations.hank-mbp-m4.system

# Release: Combine build with config (the flake.lock pins this)
darwin-rebuild switch --flake .#hank-mbp-m4

# Run: Execute in target environment
# (happens automatically after switch)
```

For TypeScript:

```bash
# Build
bun run build

# Release (deploy artifacts + environment)
# CI/CD handles this - never manually deploy

# Run
bun run start
```

## VI. Processes: Execute as Stateless Processes

**Principle**: Processes are stateless and share-nothing.

```typescript
// Bad: storing state in process memory
const userSessions = new Map<string, Session>();

// Good: external backing service for state
const getSession = (sessionId: string) => redis.get(`session:${sessionId}`);
const setSession = (sessionId: string, session: Session) =>
  redis.set(`session:${sessionId}`, JSON.stringify(session), 'EX', 3600);
```

## VII. Port Binding: Export Services via Port Binding

**Principle**: The app is completely self-contained.

```typescript
// Hono app binds its own port
const app = new Hono();

app.get('/health', (c) => c.json({ status: 'ok' }));

export default {
  port: parseInt(process.env.PORT ?? '3000', 10),
  fetch: app.fetch,
};
```

## VIII. Concurrency: Scale Out via Process Model

**Principle**: Scale by running more processes, not bigger processes.

```typescript
// Workers handle different concerns
// web: handles HTTP requests
// worker: processes background jobs
// scheduler: runs periodic tasks

// Each can scale independently based on load
```

## IX. Disposability: Fast Startup, Graceful Shutdown

**Principle**: Processes start fast and shut down gracefully.

```typescript
// Fast startup - lazy initialization where possible
const db = createLazyConnection(() => connectToDatabase());

// Graceful shutdown
process.on('SIGTERM', async () => {
  console.log('Shutting down gracefully...');
  await server.close();
  await db.disconnect();
  process.exit(0);
});
```

For Nix services:

```nix
systemd.services.myapp = {
  serviceConfig = {
    ExecStart = "${pkgs.myapp}/bin/myapp";
    ExecStop = "${pkgs.myapp}/bin/myapp --shutdown";
    TimeoutStopSec = 30;
  };
};
```

## X. Dev/Prod Parity: Keep Environments Similar

**Principle**: Development, staging, and production should be as similar as possible.

Nix excels here:

```nix
# The same flake builds for all environments
# Development machine
darwin-rebuild switch --flake .#hank-mbp-m4

# CI environment uses the same flake
nix build .#darwinConfigurations.hank-mbp-m4.system

# Same packages, same versions, same configuration structure
```

For TypeScript:

```typescript
// Use the same database in dev and prod (just different instances)
// Bad: SQLite in dev, PostgreSQL in prod

// Good: PostgreSQL everywhere, use Docker for local dev
// docker-compose.yml
// services:
//   db:
//     image: postgres:16
//     ports: ["5432:5432"]
```

## XI. Logs: Treat as Event Streams

**Principle**: Never manage log files. Write to stdout.

```typescript
// Bad: writing to log files
fs.appendFileSync('/var/log/app.log', message);

// Good: write to stdout, let infrastructure handle routing
console.log(JSON.stringify({
  timestamp: new Date().toISOString(),
  level: 'info',
  message: 'User logged in',
  userId: user.id,
}));
```

## XII. Admin Processes: Run as One-Off Processes

**Principle**: Admin/management tasks run as one-off processes.

```bash
# Database migrations
bun run db:migrate

# One-off data fixes
bun run scripts/fix-user-data.ts

# Interactive console
bun run console
```

In the evolution system:

```bash
# One-off grading
bun run src/index.ts grade

# Database migration
bun run scripts/migrate-jsonl.ts

# Security audit
bun run src/index.ts audit
```

---

## Nix-Specific Twelve-Factor Patterns

### Reproducibility as a First-Class Concern

```nix
# Pin all inputs via flake.lock
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    # Pinned to specific commit via flake.lock
  };
}
```

### Declarative Over Imperative

```nix
# Bad: imperative setup
# "Run these commands after install..."

# Good: declarative configuration
{
  environment.systemPackages = [ ... ];
  programs.zsh.enable = true;
  services.yabai.enable = true;
}
```

### Atomic Deployments

```bash
# Nix provides atomic upgrades and rollbacks
darwin-rebuild switch --flake .#hank-mbp-m4

# If something breaks
darwin-rebuild switch --rollback
```
