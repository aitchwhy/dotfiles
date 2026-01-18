---
description: Audit Claude Code configuration state
allowed-tools: Bash, Read
---

# Configuration Audit

## Check Symlinks
```bash
ls -la ~/.claude/settings.json
ls -la ~/.claude/skills
ls -la ~/.claude/agents
ls -la ~/.claude/commands
```

## Verify Generation
```bash
cd ~/dotfiles/config/quality
pnpm run typecheck
```

## Check MCP Servers
```bash
cat ~/.claude.json | jq '.mcpServers'
```

## Report Findings
Report any broken symlinks, type errors, or missing configs.
