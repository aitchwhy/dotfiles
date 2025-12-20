---
name: nix-infrastructure
description: Production-grade Nix infrastructure patterns. Port registry, process-compose-flake, nix2container, CI/CD with GHA + Cachix + Colmena.
allowed-tools: Read, Write, Edit, Bash, Grep
token-budget: 600
references:
  - references/process-compose.md: "process-compose-flake service definitions"
  - references/nix2container.md: "Container builds and layer optimization"
  - references/cicd.md: "GitHub Actions, Cachix, Colmena deployment"
---

# Nix Infrastructure Patterns

> Read specific reference files based on your task.

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

**IMPORTANT**: Read `nix-configuration-centralization` skill for complete patterns.

### Structure

```nix
# lib/config/ports.nix
{
  infrastructure = { ssh = 22; tailscale = 41641; nodeExporter = 9100; };
  databases = { redis = 6379; postgresql = 5432; };
  development = { api = 3000; worker = 3001; };
  otel = { grpc = 4317; http = 4318; };
  observability = { prometheus = 9090; grafana = 3100; loki = 3200; };
}
```

### Usage in NixOS Modules

```nix
{ lib, ... }:
let
  cfg = import ../../../lib/config { inherit lib; };
  ports = cfg.ports;
  services = cfg.services;
in
{
  services.prometheus.exporters.node = {
    enable = true;
    port = ports.infrastructure.nodeExporter;
  };

  # Use derived service URLs instead of hardcoding
  services.promtail.configuration.clients = [
    { url = services.loki.pushUrl; }
  ];
}
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

## Build Optimization (Critical)

**Before any nix2container work, read `nix-build-optimization` skill.**

Key principles:
1. **Never put `bun install` in app derivation** - Split into nodeModules
2. **Pin nixpkgs to stable** - Use `nixos-24.11`, not unstable
3. **Use magic-nix-cache in CI** - After nix-installer, before cachix
4. **Layer nix2container images** - Runtime in layer, app in copyToRoot

## When to Read Reference Files

| Task | Read |
|------|------|
| Local dev services | `references/process-compose.md` |
| Container builds | `references/nix2container.md` |
| CI/CD, deployment | `references/cicd.md` |

## Related Skills

| Skill | Relationship |
|-------|--------------|
| **nix-configuration-centralization** | **Core pattern - read first** |
| `nix-build-optimization` | **Critical** - Derivation splitting, Cachix |
| `devops-patterns` | Philosophy and blocked files/commands |
| `nix-patterns` | Flake-parts, nix-darwin, Home Manager |
