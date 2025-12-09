---
description: Rebuild Nix darwin configuration
allowed-tools: Bash
---

# Nix Darwin Rebuild

## 1. Format Check

```bash
cd ~/dotfiles
nix fmt -- --check
```

## 2. Lint

```bash
nix flake check
```

## 3. Build Test

```bash
darwin-rebuild build --flake .#hank-mbp-m4
```

## 4. Switch (if build succeeds)

```bash
sudo darwin-rebuild switch --flake .#hank-mbp-m4
```

## 5. Verify

```bash
echo "Generation:"
darwin-rebuild --list-generations | tail -1
```
