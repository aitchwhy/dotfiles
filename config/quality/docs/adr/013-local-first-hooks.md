---
status: accepted
date: 2026-01-18
decision-makers: [hank]
consulted: []
informed: []
---

# Local-First Hooks: Project Authority Over Global Enforcement

## Context and Problem Statement

The quality tooling architecture had three layers enforcing the same patterns:
1. oxlint (645+ rules, fast, type-aware)
2. Dotfiles AST-grep (44 rules via global hooks)
3. Project-local AST-grep (105 rules in Told)

This "split-brain" architecture caused triple enforcement of basic patterns (console, any, assertions) and inconsistent enforcement of domain patterns. Global hooks bypassed project-level ignores in `sgconfig.yml`, causing false positives.

How should quality enforcement be layered to avoid redundancy while maintaining project authority?

## Decision Drivers

* Single enforcement point per pattern (no redundancy)
* Project authority over their own rules and ignores
* Fast feedback (oxlint for basics, AST-grep for domain patterns)
* YAML-based ignores in `sgconfig.yml` must be respected

## Considered Options

* Option 1: Keep global hooks, improve filtering
* Option 2: Remove global hooks, local-first enforcement
* Option 3: Centralized rules with project overrides

## Decision Outcome

Chosen option: "Option 2: Remove global hooks, local-first enforcement", because it gives projects authority over their rules and respects `sgconfig.yml` ignores.

### Consequences

* Good, because each project controls its own rules
* Good, because `sgconfig.yml` ignores work correctly
* Good, because no duplicate enforcement of oxlint-covered patterns
* Bad, because new projects must explicitly adopt templates

### Confirmation

```bash
# Global hooksPath should be empty
git config --global core.hooksPath  # Returns empty

# Told should use local ast-grep scan
grep "ast-grep scan" ~/src/told/lefthook.yml  # Returns simple command

# No oxlint-covered rules in templates
ls ~/dotfiles/config/quality/rules/templates/effect-ts/ | grep -E "no-console|no-any"  # No matches
```

## Pros and Cons of the Options

### Option 1: Keep global hooks, improve filtering

* Good, because all projects get quality checks automatically
* Bad, because shell-based filtering is fragile and verbose
* Bad, because ignores must be maintained in two places (shell + YAML)
* Bad, because difficult to debug false positives

### Option 2: Remove global hooks, local-first enforcement

* Good, because projects own their rules completely
* Good, because `sgconfig.yml` is the single source for ignores
* Good, because simple `ast-grep scan` command in lefthook
* Neutral, because new projects must run `lefthook install`

### Option 3: Centralized rules with project overrides

* Good, because updates propagate automatically
* Bad, because override mechanism is complex
* Bad, because still requires syncing between central and local

## More Information

The new architecture:

```
LAYER 1: oxlint (fast, built-in)
├── no-console: deny
├── typescript/no-explicit-any: deny
├── typescript/no-non-null-assertion: deny
└── unicorn/no-nested-ternary: deny

LAYER 2: AST-grep (domain-specific, project-local)
├── Effect-TS patterns (no-try-catch, http-ssot, etc.)
├── Project-specific rules (handler locations, config patterns)
└── YAML ignores in sgconfig.yml

LAYER 3: biome (format only)

GLOBAL HOOKS: NONE
Each project uses local lefthook → ast-grep scan → sgconfig.yml
```

Templates for new projects: `~/dotfiles/config/quality/rules/templates/`
