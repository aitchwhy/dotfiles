---
name: port-registry
description: Type-safe port allocation via lib/ports.nix. Prevents conflicts across Nix modules and process-compose.
allowed-tools: Read, Write, Edit
---

# Port Registry Pattern

Centralized port allocation to prevent conflicts across services.

## Why Port Registry

Without centralized allocation:
- Port conflicts between services
- Hard-to-debug "address in use" errors
- Inconsistent ports across environments
- No single source of truth

With port registry:
- Compile-time conflict detection
- Consistent ports everywhere
- Self-documenting infrastructure

## Structure

```nix
# lib/ports.nix
{
  infrastructure = {
    ssh = 22;
    tailscale = 41641;
    nodeExporter = 9100;
    promtail = 9080;
  };

  databases = {
    redis = 6379;
    postgresql = 5432;
    temporal = 7233;
  };

  development = {
    api = 3000;
    web = 3001;
    temporalUI = 8233;
    storybook = 6006;
  };

  otel = {
    grpc = 4317;
    http = 4318;
    jaegerUI = 16686;
  };

  storage = {
    minio = 9000;
    minioConsole = 9001;
  };
}
```

## Port Ranges Convention

| Range | Category | Examples |
|-------|----------|----------|
| 0-1023 | System/Well-known | ssh (22), http (80) |
| 3000-3999 | Application servers | api, web, vite |
| 4000-4999 | Telemetry/Tracing | OTEL (4317/4318) |
| 5000-5999 | Databases | PostgreSQL (5432) |
| 6000-6999 | Dev tools | Redis (6379), Storybook (6006) |
| 7000-7999 | Workflow engines | Temporal (7233) |
| 8000-8999 | Web UIs | Temporal UI (8233) |
| 9000-9999 | Infrastructure | MinIO (9000), Prometheus (9090) |

## Usage in NixOS Modules

```nix
{ lib, ... }:
let
  ports = import ../../../lib/ports.nix;
in
{
  services.prometheus.exporters.node = {
    enable = true;
    port = ports.infrastructure.nodeExporter;
  };

  services.postgresql = {
    enable = true;
    port = ports.databases.postgresql;
  };

  networking.firewall.allowedTCPPorts = [
    ports.infrastructure.ssh
    ports.databases.postgresql
  ];

  networking.firewall.allowedUDPPorts = [
    ports.infrastructure.tailscale
  ];
}
```

## Usage in process-compose

### Nix Integration (process-compose-flake)

```nix
# flake/process-compose.nix
{ inputs, ... }:
{
  imports = [ inputs.process-compose-flake.flakeModule ];

  perSystem = { pkgs, ... }:
  let
    ports = import ../lib/ports.nix;
  in
  {
    process-compose.dev = {
      settings.processes = {
        api = {
          command = "${pkgs.bun}/bin/bun run dev";
          environment.PORT = toString ports.development.api;
          ready_log_line = "listening on";
        };

        redis = {
          command = "${pkgs.redis}/bin/redis-server --port ${toString ports.databases.redis}";
          is_daemon = true;
          readiness_probe = {
            exec.command = "${pkgs.redis}/bin/redis-cli -p ${toString ports.databases.redis} ping";
          };
        };

        postgres = {
          command = "${pkgs.postgresql_18}/bin/postgres -D $PGDATA -p ${toString ports.databases.postgresql}";
          environment.PGDATA = "/tmp/pgdata-dev";
        };
      };
    };
  };
}
```

### YAML Configuration

```yaml
# process-compose.yaml
processes:
  redis:
    # Port from lib/ports.nix: databases.redis = 6379
    command: redis-server --port 6379

  api:
    # Port from lib/ports.nix: development.api = 3000
    command: bun run dev
    environment:
      PORT: "3000"
    depends_on:
      redis:
        condition: process_healthy

  postgres:
    # Port from lib/ports.nix: databases.postgresql = 5432
    command: postgres -D /tmp/pgdata -p 5432
```

## Adding New Ports

### 1. Choose Port Range

Select based on service category:
- New database → 5000-5999
- New dev tool → 6000-6999
- New web UI → 8000-8999

### 2. Check for Conflicts

```bash
# Check if port is in use
lsof -i :8080

# Check all registered ports
grep -r "= [0-9]\{4\}" lib/ports.nix
```

### 3. Add to Registry

```nix
# lib/ports.nix
{
  # ... existing ports ...

  newCategory = {
    newService = 8080;
  };
}
```

### 4. Use in Module

```nix
let
  ports = import ../lib/ports.nix;
in
{
  services.newService.port = ports.newCategory.newService;
}
```

## Checking Port Usage

```bash
# Check if port is in use
lsof -i :3000

# Find process using port
lsof -i :3000 -t | xargs ps -p

# List all listening ports
netstat -vanp tcp | grep LISTEN

# macOS: List all listening ports
lsof -iTCP -sTCP:LISTEN -P
```

## Conflict Resolution

### Development Conflict

When a port is already in use during development:

```bash
# Find and kill process
lsof -i :3000 -t | xargs kill

# Or use different port temporarily
PORT=3001 bun run dev
```

### CI Conflict

Use process-compose for orchestration to ensure services start in order:

```yaml
processes:
  postgres:
    command: postgres -p 5432

  api:
    command: bun run dev
    depends_on:
      postgres:
        condition: process_healthy
```

## Port Health Checks

```nix
# process-compose readiness probe
readiness_probe = {
  exec.command = "nc -z localhost ${toString ports.databases.postgresql}";
  initial_delay_seconds = 2;
  period_seconds = 5;
};
```

## Anti-Patterns

### Avoid

```nix
# DON'T: Hardcode ports inline
services.myService.port = 3000;

# DON'T: Use different ports in different environments
# DON'T: Let services auto-select ports
```

### Prefer

```nix
# DO: Reference from ports.nix
services.myService.port = ports.development.myService;

# DO: Document port purpose
# DO: Use consistent ports everywhere
```

## Quick Reference

| Service | Port | Protocol |
|---------|------|----------|
| SSH | 22 | TCP |
| PostgreSQL | 5432 | TCP |
| Redis | 6379 | TCP |
| API Server | 3000 | TCP |
| Web Dev | 3001 | TCP |
| Storybook | 6006 | TCP |
| MinIO S3 | 9000 | TCP |
| MinIO Console | 9001 | TCP |
| OTEL gRPC | 4317 | TCP |
| OTEL HTTP | 4318 | TCP |
| Jaeger UI | 16686 | TCP |
| Prometheus | 9090 | TCP |
| Temporal | 7233 | TCP |
| Temporal UI | 8233 | TCP |
| Tailscale | 41641 | UDP |
