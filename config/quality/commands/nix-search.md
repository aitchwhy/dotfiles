---
description: Search Nix packages
allowed-tools: Bash
---

# Search Nix Packages: $ARGUMENTS

## Search nixpkgs

```bash
nix search nixpkgs $ARGUMENTS --json | jq -r 'to_entries[] | "\(.key): \(.value.description)"' | head -20
```

## Alternative with more detail

```bash
nix-env -qaP ".*$ARGUMENTS.*" 2>/dev/null | head -20
```

## Check if package is available

```bash
nix-locate --whole-name --type x "bin/$ARGUMENTS" 2>/dev/null | head -5
```
