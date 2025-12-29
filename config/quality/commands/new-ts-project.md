---
name: new-ts-project
description: Bootstrap a new TypeScript project with optimized Nix build. Use instead of manual setup.
allowed-tools: Read, Write, Edit, Bash
---

# New TypeScript Project Bootstrap

When creating a new TypeScript project with Nix builds:

## Required Reading

**Before proceeding, read these skills:**
1. `nix-build-optimization` - Derivation splitting, caching
2. `nix-infrastructure` - Port registry, nix2container
3. `project-bootstrap` - Monorepo structure

## Checklist

### 1. Flake Structure

```
project/
├── flake.nix           # Entry point with flake-parts
├── flake.lock          # Pinned inputs
├── flake/
│   ├── packages.nix    # App + nodeModules derivations
│   ├── containers.nix  # nix2container images
│   └── devshells.nix   # Development environment
├── apps/
│   └── api/
│       └── package.json
├── packages/
│   └── domain/
│       └── package.json
├── bun.lock            # Single lockfile at root
└── package.json        # Workspace root
```

### 2. Required Derivations

```nix
packages = {
  # MUST have separate nodeModules
  nodeModules = mkDerivation { /* bun install here */ };

  # App uses nodeModules, NO bun install
  api = mkDerivation { /* bun build only */ };

  # Container with layer separation
  apiImage = nix2container.buildImage { /* layers + copyToRoot */ };
};
```

### 3. CI Configuration

```yaml
steps:
  - uses: DeterminateSystems/nix-installer-action@v14
  - uses: DeterminateSystems/magic-nix-cache-action@v8  # MUST be second
  - uses: cachix/cachix-action@v15
  - run: cachix watch-exec cache-name -- nix build .#apiImage
```

### 4. Verification

After setup, run:
```bash
# First build (caches nodeModules)
nix build .#api -v

# Second build (should be fast)
touch apps/api/src/index.ts
time nix build .#api

# Should complete in <60 seconds
```

## Anti-Pattern Detection

If you see any of these, STOP and fix:
- `bun install` in app derivation
- `nixos-unstable` in inputs
- Missing magic-nix-cache in CI
- No layer separation in nix2container
