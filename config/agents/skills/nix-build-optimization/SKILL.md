---
name: nix-build-optimization
description: Fundamental knowledge of Nix builds, Cachix, derivation splitting, nix2container, and CI/CD optimization. Use for ANY TypeScript/Nix project.
allowed-tools: Read, Write, Edit, Bash, Grep
globs: ["**/flake.nix", "**/flake.lock", "**/*.nix", ".github/workflows/*.yml"]
---

# Nix Build Optimization (December 2025)

## The Fundamental Problem

Nix derivation hashes are computed from ALL inputs. If your source code is an input, the hash changes on EVERY commit, causing cache misses:

```
+---------------------------------------------------------------+
|  BROKEN: Source code in derivation = cache miss every commit  |
+---------------------------------------------------------------+
|                                                               |
|  apiDrv = mkDerivation {                                      |
|    src = ./src;  <- Hash includes ALL source files            |
|    buildPhase = ''                                            |
|      bun install    <- Downloads 250MB EVERY TIME             |
|      bun build      <- Even though deps didn't change         |
|    '';                                                        |
|  };                                                           |
|                                                               |
|  Commit 1: hash = abc123 -> Cachix miss -> build (25 min)     |
|  Commit 2: hash = def456 -> Cachix miss -> build (25 min)     |
|                                                               |
|  The abc123 cache is USELESS because hash changed!            |
|                                                               |
+---------------------------------------------------------------+
```

## The Solution: Derivation Splitting

Separate stable inputs (dependencies) from volatile inputs (source code):

```
+---------------------------------------------------------------+
|  CORRECT: Split derivations = cache hits on dep layer         |
+---------------------------------------------------------------+
|                                                               |
|  +-------------------------+                                  |
|  | nodeModules             |  Hash = f(bun.lock) only         |
|  | (bun install)           |  Changes: ~weekly                |
|  |                         |  Cached: 99% of the time         |
|  +-----------+-------------+                                  |
|              | symlink (instant)                              |
|              v                                                |
|  +-------------------------+                                  |
|  | appDrv                  |  Hash = f(src + nodeModules)     |
|  | (bun build only)        |  Build time: 30 seconds          |
|  +-------------------------+                                  |
|                                                               |
|  Commit 1: nodeModules cached, appDrv builds (30 sec)         |
|  Commit 2: nodeModules HIT, appDrv builds (30 sec)            |
|                                                               |
+---------------------------------------------------------------+
```

## Cache Architecture

There are THREE cache layers. You need all of them:

```
+---------------------------------------------------------------+
|                      CACHE LAYER STACK                        |
+---------------------------------------------------------------+
|                                                               |
|  LAYER 1: CACHIX (Remote Binary Cache)                        |
|  =====================================                        |
|  - Stores: Complete /nix/store paths by content hash          |
|  - Shared: All CI runs, all machines, your laptop             |
|  - Speed: ~50-100 MB/s download                               |
|  - Setup: cachix/cachix-action@v15                            |
|                                                               |
|  LAYER 2: MAGIC NIX CACHE (GitHub Actions /nix/store)         |
|  ====================================================         |
|  - Stores: Entire /nix/store between workflow runs            |
|  - Shared: Same repo's CI runs only                           |
|  - Speed: ~200-500 MB/s (same datacenter)                     |
|  - Setup: DeterminateSystems/magic-nix-cache-action@v8        |
|                                                               |
|  LAYER 3: BUN/NPM CACHE (Package Manager)                     |
|  ========================================                     |
|  - Stores: ~/.bun/install/cache                               |
|  - WARNING: USELESS inside Nix sandbox!                       |
|  - Nix builds are isolated - can't see ~/.bun                 |
|                                                               |
+---------------------------------------------------------------+
```

## Implementation Pattern

### For TypeScript/Bun Projects

```nix
# In flake.nix or flake/packages.nix

{ inputs, ... }:
{
  perSystem = { pkgs, system, ... }:
  let
    # Compute lockfile hash for cache key
    bunLockHash = builtins.hashFile "sha256" ./bun.lock;

    # Source filter for deps (only lockfiles)
    depsSrc = pkgs.nix-filter {
      root = ./.;
      include = [
        "bun.lock"
        "package.json"
        ./apps       # Include package.json files
        ./packages   # Include package.json files
      ];
      exclude = [ "**/*.ts" "**/*.tsx" ];  # Exclude source
    };

    # Source filter for app (exclude tests, etc.)
    appSrc = pkgs.nix-filter {
      root = ./.;
      include = [
        ./apps
        ./packages
        "tsconfig.json"
        "bun.lock"
        "package.json"
      ];
      exclude = [
        "**/*.test.ts"
        "**/*.spec.ts"
        "**/e2e/**"
      ];
    };
  in
  {
    packages = {
      # ==========================================================
      # LAYER 1: Node Modules (cached by lockfile hash)
      # Only rebuilds when bun.lock changes (~weekly)
      # ==========================================================
      nodeModules = pkgs.stdenv.mkDerivation {
        name = "node-modules-${builtins.substring 0 8 bunLockHash}";
        src = depsSrc;

        nativeBuildInputs = [ pkgs.bun pkgs.cacert ];
        SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";

        buildPhase = ''
          export HOME=$TMPDIR
          bun install --frozen-lockfile --production
        '';

        installPhase = ''
          mkdir -p $out
          cp -r node_modules $out/
        '';

        # Allow network access for bun install
        __noChroot = true;
      };

      # ==========================================================
      # LAYER 2: Application Build (uses cached modules)
      # Only runs `bun build` - no network, ~30 seconds
      # ==========================================================
      api = pkgs.stdenv.mkDerivation {
        name = "api";
        src = appSrc;

        nativeBuildInputs = [ pkgs.bun ];

        buildPhase = ''
          export HOME=$TMPDIR

          # Link cached node_modules (instant, no download)
          ln -s ${packages.nodeModules}/node_modules ./node_modules

          # Build only - deps already installed
          bun build apps/api/src/server.ts \
            --outdir dist \
            --target bun \
            --minify
        '';

        installPhase = ''
          mkdir -p $out/dist
          cp -r dist/* $out/dist/
        '';
      };
    };
  };
}
```

### For nix2container Images

```nix
{ inputs, ... }:
{
  perSystem = { pkgs, system, self', ... }:
  let
    n2c = inputs.nix2container.packages.${system}.nix2container;
  in
  {
    packages = {
      # ==========================================================
      # LAYER 3: Container Image (layer separation)
      # ==========================================================
      apiImage = n2c.buildImage {
        name = "api";
        tag = "latest";

        # Separate layers for optimal caching
        layers = [
          # Runtime layer (rarely changes) - ~50MB
          (n2c.buildLayer {
            deps = [ pkgs.bun pkgs.cacert ];
          })
        ];

        # Application layer (changes frequently) - ~5MB
        copyToRoot = pkgs.buildEnv {
          name = "api-root";
          paths = [ self'.packages.api ];
          pathsToLink = [ "/dist" ];
        };

        config = {
          Cmd = [ "${pkgs.bun}/bin/bun" "run" "/dist/server.js" ];
          Env = [
            "NODE_ENV=production"
            "PORT=8080"
            "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
          ];
          ExposedPorts."8080/tcp" = {};
        };
      };
    };
  };
}
```

## CI/CD Pattern (GitHub Actions)

```yaml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest  # Or ubuntu-latest-8-cores for speed
    steps:
      - uses: actions/checkout@v4

      # ==========================================================
      # NIX SETUP (order matters!)
      # ==========================================================

      - name: Install Nix
        uses: DeterminateSystems/nix-installer-action@v14
        with:
          extra-conf: |
            experimental-features = nix-command flakes
            accept-flake-config = true

      # Layer 2: Local /nix/store cache (must be after nix-installer)
      - name: Enable Nix Store Cache
        uses: DeterminateSystems/magic-nix-cache-action@v8

      # Layer 1: Remote binary cache
      - name: Setup Cachix
        uses: cachix/cachix-action@v15
        with:
          name: your-cache-name
          authToken: '${{ secrets.CACHIX_AUTH_TOKEN }}'

      # ==========================================================
      # BUILD (with streaming Cachix push)
      # ==========================================================

      - name: Build with streaming cache
        run: |
          cachix watch-exec your-cache-name -- \
            nix build .#apiImage --print-build-logs
```

## Verification Commands

```bash
# Check if derivation splitting works
nix build .#nodeModules -v 2>&1 | grep -E "building|copying"

# Verify cache behavior (should show "cached" on second run)
nix build .#api -v 2>&1 | grep -E "building|cached"

# Check closure sizes
nix path-info -rsSh .#api | sort -k2 -h | tail -10

# Test image locally
nix build .#apiImage
nix run .#apiImage.copyToDockerDaemon
docker images api:latest --format "{{.Size}}"
```

## Anti-Patterns to NEVER Use

| Anti-Pattern | Correct Pattern |
|--------------|-----------------|
| `bun install` inside app derivation | Split into `nodeModules` derivation |
| `nixpkgs/nixos-unstable` | Pin to `nixpkgs/nixos-24.11` |
| Missing magic-nix-cache | Add after nix-installer |
| Post-build Cachix push | Use `cachix watch-exec` streaming |
| Dockerfile for Nix projects | `nix2container.buildImage` |
| `nix-shell` | `nix develop` (flakes-native) |
| `forAllSystems` helper | `flake-parts perSystem` |
| nodejs in Bun derivations | Remove - Bun doesn't need Node |

## When to Use Each Tool

| Tool | Use Case |
|------|----------|
| **Cachix** | Remote binary cache, shared across all machines |
| **magic-nix-cache** | GitHub Actions /nix/store persistence |
| **nix2container** | OCI images without Dockerfile |
| **dream2nix/bun2nix** | Per-package derivations (bleeding edge) |
| **process-compose-flake** | Local dev orchestration |
| **colmena** | Multi-host NixOS deployment |

## Expected Build Times

| Scenario | Before Split | After Split |
|----------|--------------|-------------|
| Cold build (no cache) | 25-35 min | 7-10 min |
| Warm build (deps cached) | 25-35 min | 1-2 min |
| CI with magic-nix-cache | 30+ min | 5-10 min |

## Related Skills

- `nix-infrastructure` - Port registry, process-compose, deployment
- `nix-flake-parts` - Modular flake composition
- `devops-patterns` - CI/CD philosophy
