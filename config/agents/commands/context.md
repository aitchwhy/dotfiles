Generate AI context packages for different concerns.

## Usage

```bash
# Full dotfiles context (default)
just rx-dots

# Nix infrastructure only
just rx-nix

# Signet CLI only
just rx-signet

# Agent system only
just rx-agents

# Copy to clipboard for Claude.ai
just rx-copy
```

## Concern-Specific Configs

| Config | Include Patterns | Purpose |
|--------|------------------|---------|
| `repomix.config.json` | Full dotfiles | Complete context |
| `config/repomix/nix.json` | `*.nix`, `flake.*` | Nix infrastructure |
| `config/repomix/signet.json` | `signet/src/**/*.ts` | Signet CLI |
| `config/repomix/agents.json` | `agents/**/*.{ts,md}` | Hooks & skills |

## Output Files

All outputs go to the current directory:
- `repomix-output.xml` - Full dotfiles
- `repomix-nix.xml` - Nix only
- `repomix-signet.xml` - Signet only
- `repomix-agents.xml` - Agents only

## MCP Integration

The Repomix MCP server is available for Claude Code:
```
mcp__repomix__pack_codebase
mcp__repomix__pack_remote_repository
```
