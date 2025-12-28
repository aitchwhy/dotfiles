---
name: upgrade
description: Self-updating system for Claude Code patterns and Anthropic releases
allowed-tools: Read, Bash(curl:*), Bash(rg:*), Write
token-budget: 1500
---

# upgrade

## Overview

# Upgrade Skill

Monitors Anthropic releases and community patterns to keep the dotfiles system current.

## Sources Monitored

| Source | URL | Check Frequency |
|--------|-----|-----------------|
| Anthropic Docs | https://docs.anthropic.com/en/docs/claude-code | Weekly |
| Anthropic Cookbook | https://github.com/anthropics/anthropic-cookbook | Weekly |
| Claude Code Releases | https://github.com/anthropics/claude-code/releases | Daily |

## Usage

```bash
# Check for available updates (dry run)
just upgrade-check

# Show what would change
just upgrade-diff

# Apply updates (interactive)
just upgrade-apply
```

## Detected Patterns

The upgrade skill looks for:

### 1. Hook Updates
- New hook types (PreToolUse, PostToolUse, SessionStart, Stop)
- Changed hook signatures
- New matcher patterns

### 2. Skill Frontmatter
- `use_when:` directive (critical for routing)
- `allowed-tools:` restrictions
- `token-budget:` limits
- `model:` per-skill override

### 3. Permission Patterns
- New Bash command patterns
- File permission updates
- Security restrictions

### 4. MCP Protocol Changes
- New server types
- Changed configuration formats
- Deprecated servers

## Upgrade Workflow

```
1. Fetch    - Download latest docs and changelogs
2. Diff     - Compare against current config/agents/
3. Report   - Generate upgrade recommendations
4. Apply    - Implement changes (with user confirmation)
```

## Example Session

```
User: Check for Claude Code updates

Claude: [Reads this skill]
        [Fetches https://docs.anthropic.com/en/docs/claude-code]
        [Compares against config/agents/settings.json]
        [Reports findings]

Found 2 recommended updates:

1. NEW: `model` field in skill frontmatter
   - Allows per-skill model override
   - Add to: config/agents/skills/*/SKILL.md
   - Example: `model: opus`

2. UPDATED: PostToolUse hook now supports `toolResult` in matcher
   - Current: `"matcher": "Write|Edit|MultiEdit"`
   - New: Can match on tool results

Apply these updates? [y/N]
```

## Manual Check Process

When automated checks aren't available:

1. Visit https://docs.anthropic.com/en/docs/claude-code
2. Compare against `config/agents/settings.json` for hook changes
3. Check `config/agents/skills/*/SKILL.md` for frontmatter updates
4. Review release notes for breaking changes

## Related

- `config/agents/AGENTS.md` - Main bootloader (SSOT)
- `config/agents/settings.json` - Hook configuration
- `config/agents/skills/paragon/SKILL.md` - Enforcement system
- `modules/home/apps/claude.nix` - MCP server definitions
