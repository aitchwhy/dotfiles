---
status: accepted
date: 2025-12-01
decision-makers: [hank]
consulted: []
informed: []
---

# Nix-Managed Claude Configuration

## Context and Problem Statement

Claude Code stores configuration in `~/.claude/`. How should we manage this configuration reproducibly?

## Decision Drivers

* Configuration must be version-controlled
* Must work with nix-darwin and home-manager
* Must support both Claude Desktop and Claude Code
* MCP servers need consistent configuration

## Considered Options

* Manual `~/.claude/` management
* Symlinks from dotfiles
* Nix home-manager with file generation
* Chezmoi templates

## Decision Outcome

Chosen option: "Nix home-manager with file generation", because it integrates with existing Nix infrastructure.

### Consequences

* Good, because configuration is declarative and reproducible
* Good, because MCP servers defined once, used everywhere
* Good, because `just switch` applies all changes
* Bad, because manual `~/.claude/` edits get overwritten
* Bad, because requires Nix knowledge to modify

### Confirmation

```bash
# MCP servers must come from single Nix file
grep -l "mcpServers" modules/home/apps/mcp.nix

# Never edit directly (should be symlinks or generated)
ls -la ~/.claude/settings.json
```

## More Information

* MCP SSOT: `modules/home/apps/mcp.nix`
* Apply changes: `just switch`
* Related: [ADR-004](004-typescript-ssot.md)
