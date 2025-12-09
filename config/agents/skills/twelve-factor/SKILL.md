---
name: twelve-factor
description: 12-Factor App methodology applied to Nix dotfiles and modern TypeScript. Reproducible builds, environment config, dev/prod parity.
allowed-tools: Read, Write, Edit, Grep, Glob, Bash
---

## I. Codebase

**Principle**: One codebase tracked in version control, many deploys.

Each machine is a "deploy" of the same dotfiles codebase.

## II. Dependencies

### Explicitly Declare All Dependencies

```nix
# Bad: assumes system has curl
environment.systemPackages = [ pkgs.jq ];

# Good: explicitly declare all
environment.systemPackages = with pkgs; [ curl jq ];

# Dev shells with all tools
devShells.default = pkgs.mkShell {
  packages = with pkgs; [ bun biome typescript ];
};
```

## III. Config

### Environment-Driven Configuration

```typescript
// Bad: hardcoded
const API_URL = 'https://api.production.com';

// Good: environment-driven
const config = {
  apiUrl: process.env.API_URL ?? 'http://localhost:3000',
  dbHost: process.env.DB_HOST ?? 'localhost',
} as const;
```

## V. Build, Release, Run

### Strict Separation

```bash
# Build: Convert code to executable
nix build .#darwinConfigurations.hostname.system

# Release: Combine build with config
darwin-rebuild switch --flake .#hostname

# TypeScript
bun run build  # Build
bun run start  # Run
```

## IX. Disposability

### Graceful Shutdown

```typescript
// Lazy initialization
const db = createLazyConnection(() => connectToDatabase());

// Graceful shutdown
process.on('SIGTERM', async () => {
  console.log('Shutting down gracefully...');
  await server.close();
  await db.disconnect();
  process.exit(0);
});
```

## X. Dev/Prod Parity

### Nix Ensures Parity

```nix
# The same flake builds for all environments
darwin-rebuild switch --flake .#hostname  # Dev machine
nix build .#darwinConfigurations.hostname.system  # CI

# Same packages, same versions, same configuration
```

## XI. Logs

### Logs as Event Streams

```typescript
// Bad: writing to log files
fs.appendFileSync('/var/log/app.log', message);

// Good: structured stdout
console.log(JSON.stringify({
  timestamp: new Date().toISOString(),
  level: 'info',
  message: 'User logged in',
  userId: user.id,
}));
```
