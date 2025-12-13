# Lessons Learned

Persistent log of insights across sessions.

## Format

- **Date**: YYYY-MM-DD
- **Category**: bug | pattern | optimization | gotcha
- **Lesson**: What was learned
- **Evidence**: How verified

---

## Lessons

### 2025-12-11 | pattern | Migration complete

Architecture switched to Bootloader pattern. Single AGENTS.md routes to modular content.
*Evidence*: Symlinks verified via `readlink ~/.claude/CLAUDE.md`

---

### 2025-12-12 | optimization | Nix Build Performance

**The Cache Miss Problem**

*Symptom*: CI builds take 25-35 minutes even with Cachix configured.

*Root Cause*: Derivation hash includes source code. Source changes every commit. Hash changes every commit. Cachix never has a cache hit for the main derivation.

*Solution*: Split dependencies into a separate derivation whose hash is based only on the lockfile. Dependencies cached 99% of the time. App build takes 30 seconds.

*Evidence*: After split, warm builds complete in <60 seconds vs 25+ minutes.

---

### 2025-12-12 | pattern | Cache Layer Stack

Three cache layers required for optimal Nix builds:

1. **Cachix** - Remote binary cache. Stores complete derivations by content hash. Shared everywhere.
2. **magic-nix-cache** - GitHub Actions local cache. Persists /nix/store between workflow runs.
3. **Bun cache** - Package manager cache. USELESS inside Nix sandbox (isolated).

*Key Insight*: Layer 2 (magic-nix-cache) helps with flake evaluation and intermediate derivations. Layer 1 (Cachix) handles the heavy lifting for split derivations.

*Evidence*: CI runs dropped from 30+ minutes to 5-10 minutes with proper layer configuration.

---

### 2025-12-12 | gotcha | Nix Sandbox Isolation

Nix builds are sandboxed. Package manager caches (~/.bun, ~/.npm) are NOT accessible during builds.

*Wrong assumption*: "Bun cache in CI will speed up builds"
*Reality*: Bun inside Nix derivation cannot see ~/.bun cache

*Solution*: Use derivation splitting instead. Cache at the Nix level, not package manager level.

---

### 2025-12-12 | pattern | Derivation Splitting

**Anti-Patterns Eliminated:**
- `bun install` inside app derivation (was rebuilding deps every commit)
- Using `nixos-unstable` (slower evaluation)
- Missing magic-nix-cache in CI (no local store persistence)
- Post-build Cachix push (should use streaming `cachix watch-exec`)

**Verification Command:**
```bash
nix build .#api -v 2>&1 | grep -E "building|cached"
```
Second build should show "cached" for nodeModules.

---

*Add new lessons above this line*
