---
name: nix-check
description: Verify Nix build configuration follows optimization patterns. Run before any Nix changes.
allowed-tools: Read, Bash, Grep
---

# Nix Optimization Checker

Check that Nix build configuration follows best practices.

## Verification Steps

### 1. Check for Derivation Splitting

```bash
# Look for bun install inside app derivations (anti-pattern)
grep -r "bun install" flake.nix flake/*.nix 2>/dev/null | grep -v "nodeModules\|node-modules"
```

**If found**: Flag as anti-pattern. `bun install` should only be in a dedicated `nodeModules` derivation.

### 2. Check nixpkgs Pin

```bash
# Should be pinned to a release, not unstable
grep "nixpkgs.url" flake.nix
```

**Expected**: `github:NixOS/nixpkgs/nixos-24.11` (not unstable)

### 3. Check CI Configuration

```bash
# Must have magic-nix-cache after nix-installer
grep -A5 "nix-installer-action" .github/workflows/*.yml 2>/dev/null | grep -E "magic-nix-cache|cachix"
```

**Expected**: Both magic-nix-cache AND cachix-action present.

### 4. Check nix2container Layer Separation

```bash
# Should have separate layers array
grep -A10 "buildImage" flake.nix flake/*.nix 2>/dev/null | grep "layers"
```

**Expected**: `layers = [` with runtime deps separated from app code.

### 5. Report

Generate a report:

```
## Nix Build Optimization Check

### Derivation Splitting
- [ ] nodeModules separate from app derivation
- [ ] bun install only in nodeModules

### Caching
- [ ] nixpkgs pinned to stable release
- [ ] magic-nix-cache in CI
- [ ] Cachix configured

### Container Images
- [ ] nix2container with layer separation
- [ ] Runtime deps in separate layer

### Issues Found
[List any anti-patterns detected]

### Recommended Fixes
[Specific fix for each issue]
```
