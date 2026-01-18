---
description: Rebuild Nix system configuration
allowed-tools: Bash
---

# Nix System Rebuild

1. Run `just check` to validate flake
2. Run `just switch` (or `sudo darwin-rebuild switch --flake ~/dotfiles`)
3. Run `just health` to verify

If errors occur, diagnose but DO NOT retry automatically. Report for human review.
