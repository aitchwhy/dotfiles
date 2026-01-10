---
status: accepted
date: 2026-01-10
decision-makers: [hank]
consulted: []
informed: []
---

# Runtime Path Patterns for Portable Nix Configuration

## Context and Problem Statement

Nix flakes only see git-tracked files. How should we reference paths that may be gitignored or need to be portable across users/machines?

## Decision Drivers

* Gitignored files (generated artifacts) can't use Nix path syntax
* Configuration must be portable across different usernames
* Must distinguish between Nix evaluation-time and shell runtime
* Flake reproducibility requires all referenced paths to be tracked

## Considered Options

* Nix path syntax (`../relative/path` or `/absolute/path`)
* Runtime string paths with variables (`"$HOME/path"`)
* Home-manager config references (`"${config.home.homeDirectory}/path"`)
* Track all files in git (no gitignore for referenced paths)

## Decision Outcome

Chosen option: "Runtime string paths with config references", because it provides portability while maintaining Nix's declarative nature.

### Path Types and When to Use Each

#### 1. Nix Configuration Paths (Required Hardcoding)

These define WHERE Nix installs things. They're configuration values, not runtime references:

```nix
# flake/darwin.nix - Defines user home for nix-darwin
users.users.hank = {
  home = "/Users/hank";  # Required: tells nix-darwin where home is
};

# users/hank.nix - Defines home for home-manager
home = {
  homeDirectory = "/Users/hank";  # Required: defines config.home.homeDirectory
};
```

#### 2. Nix Source Paths (Git-Tracked Only)

Use relative path syntax ONLY for files that ARE tracked in git:

```nix
# GOOD: File is tracked in git
source = ./scripts/my-script.sh;
source = ../modules/common.nix;

# BAD: File is gitignored - will fail with "not tracked by Git"
source = ../../../config/completions/generated;  # DON'T DO THIS
```

#### 3. Runtime String Paths (For Generated/Gitignored Files)

Use string interpolation for paths resolved at shell runtime:

```nix
# GOOD: Portable runtime path using config
programs.zsh.initContent = ''
  fpath=("${config.home.homeDirectory}/dotfiles/config/completions/generated/zsh" $fpath)
'';

# GOOD: Shell variable for portability in generated scripts
nixPaths = [
  "/etc/profiles/per-user/$USER/bin"  # Resolved at runtime
  "$HOME/.local/bin"
];

# BAD: Hardcoded username
nixPaths = [
  "/etc/profiles/per-user/hank/bin"  # DON'T DO THIS
];
```

### Variable Reference Guide

| Context | Variable | Example |
|---------|----------|---------|
| Nix evaluation | `${config.home.homeDirectory}` | `"${config.home.homeDirectory}/dotfiles"` |
| Nix evaluation | `${config.home.username}` | `"/etc/profiles/per-user/${config.home.username}/bin"` |
| Shell runtime | `$HOME` | `"$HOME/.config/mcp"` |
| Shell runtime | `$USER` | `"/etc/profiles/per-user/$USER/bin"` |

### Consequences

* Good, because generated/gitignored files can be referenced without git tracking
* Good, because configuration is portable across different usernames
* Good, because Nix evaluation doesn't fail on missing paths
* Good, because shell runtime resolves variables correctly
* Bad, because must understand when each pattern applies
* Bad, because runtime paths aren't validated at Nix evaluation time

### Confirmation

```bash
# No hardcoded usernames in runtime paths
rg '/Users/hank|/home/hank' modules/ --glob '*.nix' | grep -v 'homeDirectory\|users.users'

# No hardcoded usernames in per-user profiles
rg '/etc/profiles/per-user/[a-z]+' modules/ --glob '*.nix' | grep -v '\$USER\|config.home.username'

# Gitignored paths should use string interpolation, not Nix paths
rg '= \.\./.*generated' modules/ --glob '*.nix'  # Should return nothing
```

## More Information

* Related: [ADR-008](008-nix-managed-config.md) - Nix-managed configuration patterns
* Issue: Nix flakes error "Path 'X' is not tracked by Git"
* Fix commit: `fix(shell): use runtime path for gitignored completions`
