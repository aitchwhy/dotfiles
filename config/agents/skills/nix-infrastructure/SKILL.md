---
name: nix-infrastructure
description: Production-grade Nix infrastructure patterns. Port registry, process-compose-flake, nix2container, CI/CD with GHA + Cachix + Colmena.
allowed-tools: Read, Write, Edit, Bash, Grep
---

# Nix Infrastructure Patterns (December 2025)

## Core Philosophy

```
localhost === CI === production
```

Achieved via:
- **Nix Flakes**: Hermetic, reproducible builds
- **process-compose-flake**: Nix-native local orchestration
- **nix2container**: OCI images without Dockerfile
- **Port Registry**: Type-safe port allocation

## Port Registry Pattern

### Purpose

Prevent port conflicts with a single source of truth (`lib/ports.nix`).

### Structure

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
    temporalUI = 8233;
  };

  otel = {
    grpc = 4317;
    http = 4318;
  };
}
```

### Usage in NixOS Modules

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

  networking.firewall.allowedTCPPorts = [
    ports.infrastructure.ssh
  ];

  networking.firewall.allowedUDPPorts = [
    ports.infrastructure.tailscale
  ];
}
```

### Usage in process-compose.yaml

```yaml
processes:
  redis:
    # Port from lib/ports.nix: databases.redis = 6379
    command: redis-server --port 6379

  api:
    # Port from lib/ports.nix: development.api = 3000
    command: bun run dev
    environment:
      PORT: "3000"
```

## process-compose-flake Integration

### Nix-Native Service Definitions

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
            initial_delay_seconds = 1;
            period_seconds = 2;
          };
        };

        postgres = {
          command = "${pkgs.postgresql_18}/bin/postgres -D $PGDATA -p ${toString ports.databases.postgresql}";
          environment.PGDATA = "/tmp/pgdata-dev";
          readiness_probe = {
            exec.command = "${pkgs.postgresql_18}/bin/pg_isready -p ${toString ports.databases.postgresql}";
          };
          depends_on.postgres-init.condition = "process_completed_successfully";
        };

        postgres-init = {
          command = ''
            if [ ! -d /tmp/pgdata-dev ]; then
              ${pkgs.postgresql_18}/bin/initdb -D /tmp/pgdata-dev
            fi
          '';
          is_foreground = false;
        };
      };
    };

    # Process groups
    process-compose.minimal = {
      settings.processes = {
        redis = config.process-compose.dev.settings.processes.redis;
      };
    };
  };
}
```

### Commands

```bash
# Start all dev services
nix run .#dev
# or
just dev

# Start with TUI
nix run .#dev -- --tui

# Start minimal stack
nix run .#minimal
```

## nix2container Patterns

### Minimal Container Build

```nix
{ inputs, ... }:
{
  perSystem = { pkgs, system, self', ... }:
  let
    nix2container = inputs.nix2container.packages.${system}.nix2container;
    ports = import ../lib/ports.nix;
  in
  {
    packages.container-api = nix2container.buildImage {
      name = "api";
      tag = "latest";

      copyToRoot = pkgs.buildEnv {
        name = "api-root";
        paths = [
          self'.packages.api
          pkgs.cacert
        ];
        pathsToLink = [ "/bin" "/etc" ];
      };

      config = {
        Cmd = [ "${self'.packages.api}/bin/api" ];
        ExposedPorts."${toString ports.development.api}/tcp" = {};
        Env = [
          "PORT=${toString ports.development.api}"
          "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
        ];
      };
    };
  };
}
```

### Layer Optimization

```nix
packages.container-api = nix2container.buildImage {
  name = "api";

  # Separate layers for better caching
  layers = [
    # Base runtime (rarely changes)
    (nix2container.buildLayer {
      deps = [ pkgs.glibc pkgs.cacert ];
    })
    # Application runtime (changes occasionally)
    (nix2container.buildLayer {
      deps = [ pkgs.bun ];
    })
  ];

  # Application code (changes frequently - top layer)
  copyToRoot = [ self'.packages.api ];
};
```

### Build and Push

```bash
# Build container
nix build .#container-api

# Load into Docker (local testing)
./result | docker load

# Push directly to registry
nix run .#container-api.copyToRegistry -- docker://ghcr.io/org/api:latest
```

## CI/CD Patterns

### GitHub Actions with Cachix

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

      - uses: cachix/cachix-action@v15
        with:
          name: my-cache
          authToken: '${{ secrets.CACHIX_AUTH_TOKEN }}'

      - name: Check
        run: nix flake check

      - name: Build
        run: nix build .#default

      - name: Build Container
        if: github.ref == 'refs/heads/main'
        run: nix build .#container-api
```

### Colmena Deployment

```nix
# flake/deploy.nix
{ self, inputs, ... }:
{
  flake.colmena = {
    meta = {
      nixpkgs = import inputs.nixpkgs { system = "x86_64-linux"; };
      specialArgs = { inherit inputs self; };
    };

    defaults = {
      deployment = {
        buildOnTarget = false;  # Build locally or via nixbuild.net
        replaceUnknownProfiles = true;
      };
    };

    cloud-nixos = {
      deployment = {
        targetHost = "cloud-nixos.tail12345.ts.net";  # Tailscale MagicDNS
        targetUser = "root";
      };
      imports = [ self.nixosModules.cloud ];
    };
  };
}
```

### Deploy Commands

```bash
# Deploy single host
nix run nixpkgs#colmena -- apply --on cloud-nixos

# Deploy all hosts
nix run nixpkgs#colmena -- apply

# Parallel deployment with streaming evaluator
nix run nixpkgs#colmena -- apply --evaluator streaming
```

## Anti-Patterns

| Anti-Pattern | Correct Pattern |
|--------------|-----------------|
| Hardcoded ports in modules | `lib/ports.nix` registry |
| `docker-compose.yml` | `process-compose-flake` module |
| `Dockerfile` | `nix2container.buildImage` |
| `npm run dev` / `bun run dev` | `nix run .#dev` / `just dev` |
| Manual port allocation | Define in port registry |
| `forAllSystems` helper | `flake-parts perSystem` |
| Docker build in CI | `nix build .#container-*` |

## Flake Input Setup

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";

    # Local orchestration
    process-compose-flake = {
      url = "github:Platonic-Systems/process-compose-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Container builds
    nix2container = {
      url = "github:nlewo/nix2container";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Deployment
    colmena = {
      url = "github:zhaofengli/colmena";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
```

## Build Optimization (Critical)

**Before any nix2container work, read `nix-build-optimization` skill.**

Key principles:
1. **Never put `bun install` in app derivation** - Split into nodeModules
2. **Pin nixpkgs to stable** - Use `nixos-24.11`, not unstable
3. **Use magic-nix-cache in CI** - After nix-installer, before cachix
4. **Layer nix2container images** - Runtime in layer, app in copyToRoot

See `config/agents/skills/nix-build-optimization/SKILL.md` for full patterns.

## Related Skills

- `nix-build-optimization` - **Critical** - Derivation splitting, Cachix, CI/CD
- `devops-patterns` - Philosophy and blocked files/commands
- `nix-flake-parts` - Modular flake composition
- `nix-darwin-patterns` - macOS system configuration
