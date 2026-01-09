---
status: accepted
date: 2026-01-09
decision-makers: [hank]
consulted: []
informed: []
---

# QMK Source as Keyboard Configuration SSOT

## Context and Problem Statement

How should we manage ZSA Voyager keyboard configuration to ensure reproducibility, version control, and access to advanced QMK features?

## Decision Drivers

* Single Source of Truth - no split-brain between cloud config and local
* Version control with meaningful diffs
* Access to advanced QMK features (per-key tapping, chordal hold, combos)
* Reproducible builds via Nix
* CI validation that config compiles
* Independence from external services (Oryx cloud)

## Considered Options

* QMK C source files in repo with Nix build
* QMK JSON format with qmk compile
* Oryx web configurator (ZSA cloud)
* Kanata software remapper (cross-platform)
* ZMK firmware (Devicetree-based)

## Decision Outcome

Chosen option: "QMK C source files with Nix build", because:
- Full access to QMK features (per-key tapping terms, chordal hold, custom keycodes)
- Version-controlled with meaningful diffs
- CI validates every keymap change compiles
- Reproducible builds via Nix derivations
- Independence from Oryx cloud service

### Consequences

* Good: Full version control of keyboard configuration
* Good: CI catches syntax errors before flashing
* Good: Access to advanced QMK features not exposed in Oryx
* Good: Single source of truth eliminates configuration drift
* Good: Can share keyboard config as part of dotfiles
* Neutral: Must learn QMK C syntax (one-time learning cost)
* Neutral: Flashing still requires Keymapp app (hardware limitation)
* Bad: Initial QMK fetch is ~500MB (cached after first build)
* Bad: Cannot use Oryx visual editor (acceptable tradeoff)

### Confirmation

```bash
# Verify keymap syntax
nix flake check

# Build firmware
nix build .#voyager-firmware

# Check output
file result/bin/voyager.bin

# Flash via Keymapp app
open -a Keymapp
```

## Implementation

### Directory Structure

```
keyboards/
├── default.nix              # Nix build module
├── lib/
│   ├── stubs.h              # QMK stubs for syntax checking
│   └── version.h            # Version header stub
└── voyager/
    ├── keymap.c             # Key mappings (SSOT)
    ├── config.h             # Tapping behavior
    ├── rules.mk             # Build features
    └── README.md            # Layer reference
```

### Flake Integration

```nix
# flake.nix inputs
zsa-qmk = {
  url = "git+https://github.com/zsa/qmk_firmware?ref=firmware25&submodules=1";
  flake = false;
};

# Exports
packages.voyager-firmware   # Full build
checks.qmk-syntax           # Syntax validation
```

### Commands

```bash
just build-keyboard    # Build firmware (~5 min first time)
just check-keyboard    # Validate syntax (~1 second)
just keyboard-help     # Show layer reference
```

## Layout Reference

### Layer 0: BASE

QWERTY with home row mods (GASC pattern):
- A=Ctrl, S=Opt, D=Cmd, F=Shift (left hand)
- J=Shift, K=Cmd, L=Opt, ;=Ctrl (right hand)
- CapsLock = Esc (tap) / Ctrl (hold)
- Thumb cluster: Hyper, Cmd, Space/NAV, Enter

### Layer 1: NAV (Hold Space)

- HJKL = Arrow keys (Vim-style)
- Left hand = Symbols and brackets
- F-keys across top row
- Home/End/PgUp/PgDn on right

### Layer 2: SYS (Combo: Hyper+Enter)

- Media controls (Vol, Play, Prev/Next)
- RGB controls
- QK_BOOT for bootloader mode

## Compliance

This decision obsoletes:
- Kanata keyboard remapper (removed)
- Karabiner-Elements (removed, was only for Kanata driver)
- Any Oryx layout configurations
- Any `.bin`/`.hex` firmware files in repo

## More Information

* [QMK Documentation](https://docs.qmk.fm/)
* [ZSA QMK Fork](https://github.com/zsa/qmk_firmware)
* [Home Row Mods Guide](https://precondition.github.io/home-row-mods)
* [Chordal Hold](https://docs.qmk.fm/tap_hold#chordal-hold)
* [ZSA Keymapp](https://www.zsa.io/flash)
* Related: [ADR-008](008-nix-managed-config.md) for Nix configuration patterns
