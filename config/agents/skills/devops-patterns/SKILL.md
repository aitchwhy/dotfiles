---
name: devops-patterns
description: Nix-first DevOps - process-compose for local dev, Nix builds, nix2container for deployment. This is THE way.
allowed-tools: Read, Write, Edit, Bash
token-budget: 1000
---

# Nix-First DevOps

## Core Philosophy

```
localhost === CI === production
```

Achieved via:
- **Nix Flakes**: Hermetic, reproducible builds
- **process-compose**: Local service orchestration
- **nix2container**: OCI image generation (no Dockerfile)
- **GitHub Actions**: CI/CD runs `nix build`

## The Stack

| Layer | Tool | Anti-Pattern |
|-------|------|--------------|
| Local Dev | `process-compose` | `docker-compose`, `npm run dev` |
| Builds | `nix build` | Manual compilation, `docker build` |
| Containers | `nix2container` | `Dockerfile`, `docker build` |
| CI/CD | GHA + `nix build` | `docker build` in pipelines |

## Blocked Files (enforced by hook)

These files trigger a BLOCK in Claude Code:
- `docker-compose.yml` / `docker-compose.yaml`
- `Dockerfile` / `Dockerfile.*`
- `.dockerignore`

## Blocked Commands (enforced by hook)

These commands trigger a BLOCK in Claude Code:
- `docker-compose up|start|run|exec|build`
- `docker build`
- `npm|bun|yarn|pnpm run dev|start|serve`

## Correct Patterns

### Local Development

Always start services via process-compose:

```bash
# Start all services
process-compose up

# Start specific service
process-compose up api

# Or use just alias
just dev
```

### process-compose.yaml Structure

```yaml
version: "0.5"

processes:
  api:
    command: bun run dev
    ready_log_line: "Server listening"
    restart: on_failure
    max_restarts: 3
    depends_on:
      db:
        condition: process_healthy

  db:
    command: postgres -D data/
    is_daemon: true
    readiness_probe:
      exec:
        command: pg_isready -h localhost
      initial_delay_seconds: 2
      period_seconds: 1

  worker:
    command: bun run worker
    depends_on:
      api:
        condition: process_started
```

### Nix Flake with process-compose-flake

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    process-compose-flake.url = "github:Platonic-Systems/process-compose-flake";
  };

  outputs = inputs @ { flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.process-compose-flake.flakeModule
      ];

      systems = [ "x86_64-linux" "aarch64-darwin" ];

      perSystem = { pkgs, ... }: {
        # Define process-compose configurations
        process-compose."dev" = {
          settings.processes = {
            api.command = "${pkgs.bun}/bin/bun run dev";
            db.command = "${pkgs.postgresql}/bin/postgres -D ./data";
          };
        };

        # nix run .#dev starts process-compose
        apps.dev = {
          type = "app";
          program = "${self'.packages.dev}/bin/dev";
        };
      };
    };
}
```

### nix2container for OCI Images (Conceptual)

Instead of Dockerfile:

```nix
# In flake.nix perSystem
packages.container-api = nix2container.buildImage {
  name = "api";
  tag = "latest";

  copyToRoot = pkgs.buildEnv {
    name = "root";
    paths = [ self'.packages.api ];
  };

  config = {
    Cmd = [ "${self'.packages.api}/bin/api" ];
    ExposedPorts."8080/tcp" = {};
  };
};
```

Build and push:

```bash
# Build container
nix build .#container-api

# Load into Docker (for local testing)
./result | docker load

# Or push directly to registry
nix run .#container-api.copyToRegistry -- docker://ghcr.io/org/api:latest
```

### GitHub Actions Workflow

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: DeterminateSystems/nix-installer-action@main

      - uses: DeterminateSystems/magic-nix-cache-action@main

      - name: Build
        run: nix build .#api

      - name: Test
        run: nix flake check

      - name: Build Container
        run: nix build .#container-api

      - name: Push Container
        if: github.ref == 'refs/heads/main'
        run: |
          nix run .#container-api.copyToRegistry -- \
            docker://ghcr.io/${{ github.repository }}/api:${{ github.sha }}
```

## Decision Tree

| Question | Answer |
|----------|--------|
| Start API locally? | `process-compose up api` |
| Run all services? | `process-compose up` or `just dev` |
| Build binary? | `nix build .#api` |
| Create container? | `nix build .#container-api` |
| Run tests? | `nix flake check` or `bun test` |
| Deploy? | Push to main, GHA runs `nix build` |

## Why This Approach?

### Problems with Docker-First

1. **Dockerfile drift**: Dockerfile gets out of sync with Nix
2. **Two build systems**: Maintaining both Nix and Docker
3. **Non-reproducible**: `apt-get update` yields different results daily
4. **Slow iteration**: Rebuild entire image for small changes
5. **Layer caching complexity**: Optimizing Dockerfile layers is an art

### Benefits of Nix-First

1. **Single source of truth**: Nix defines everything
2. **Reproducible**: Same inputs = same outputs, always
3. **Fast iteration**: Only rebuilds what changed
4. **Minimal images**: nix2container creates tiny, optimized images
5. **No layer games**: Nix handles caching automatically
6. **Local = CI = Prod**: Exact same binaries everywhere

## Related Skills

- `nix-darwin-patterns`: System configuration with Nix
- `nix-flake-parts`: Modular flake structure
- `hexagonal-architecture`: No-mock testing with real services
