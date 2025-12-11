# Unified Agent Configuration

Single source of truth for AI coding assistants:
- **Claude Code CLI** (`~/.claude/`)
- **Gemini CLI** (`~/.gemini/`)
- **Cursor IDE** (`.cursorrules`)
- **Antigravity IDE** (`~/.gemini/antigravity/`)

## Bootloader Architecture

The system uses a **pull-based context** pattern with a tiny bootloader (~350 tokens) that routes to modular content:

```
config/agents/
├── AGENTS.md                   # Bootloader - routes to content below
├── rules/
│   └── stack.md                # Stack constraints and patterns
├── memory/
│   └── lessons.md              # Persistent learnings across sessions
├── skills/                     # Skill pattern libraries (24 total)
├── agents/                     # Agent personas for multi-agent review
├── commands/                   # Slash commands
├── hooks/                      # Pre/Post tool-use hooks
├── evolution/
│   └── grade.sh                # Health grader script
├── settings/
│   ├── claude-code.json        # Claude Code settings (hooks, permissions)
│   └── gemini.json             # Gemini CLI settings
├── nix/
│   └── agents.nix              # Home Manager module
└── AGENT.md                    # DEPRECATED - legacy monolithic config
```

## Symlink Management

All symlinks managed declaratively via Nix Home Manager:

| Target | Symlink Location |
|--------|------------------|
| `AGENTS.md` | `~/.claude/CLAUDE.md` |
| `AGENTS.md` | `~/.gemini/GEMINI.md` |
| `AGENTS.md` | `.cursorrules` (repo root) |
| `rules/` | `~/.claude/rules/`, `~/.gemini/rules/` |
| `memory/` | `~/.claude/memory/`, `~/.gemini/memory/` |

## Installation

### Via Nix (recommended)
Already configured in `modules/home/default.nix`:
```nix
modules.home.apps.agents.enable = true;
```

Run:
```bash
just switch  # from dotfiles root
```

### Manual
```bash
cd ~/dotfiles/config/agents
./setup.sh
```

## Usage

### Per-project context
```bash
# In any project directory
agent-setup  # Creates ./CLAUDE.md and ./GEMINI.md symlinks
agent-clean  # Removes agent context
```

### Health monitoring
```bash
# Run grader directly
./config/agents/evolution/grade.sh | jq .

# Run via health monitor (one-shot)
ONESHOT=true ./scripts/health-monitor.sh

# Check latest metrics
cat ~/.claude-metrics/latest.json | jq .
```

### Verification
```bash
# Verify symlinks after nix switch
readlink ~/.claude/CLAUDE.md     # -> .../AGENTS.md
readlink ~/.gemini/GEMINI.md     # -> .../AGENTS.md
readlink ~/dotfiles/.cursorrules # -> config/agents/AGENTS.md
```

## Evolution System

Self-improving configuration with 5-check health grader:

| Check | Weight | Purpose |
|-------|--------|---------|
| nix_flake | 25% | Flake validity |
| typescript | 20% | Type checking (signet) |
| hooks | 20% | Hook file integrity |
| skills | 15% | SKILL.md presence |
| versions | 20% | SSOT alignment |

Thresholds: `ok` >= 0.80, `warning` 0.50-0.79, `urgent` < 0.50

## MCP Servers

Shared across all AI tools:
- `memory` - Persistent memory
- `filesystem` - File access (~/src, ~/dotfiles, ~/Documents)
- `git` - Git operations
- `sequential-thinking` - Chain of thought
- `context7` - Documentation fetcher
- `fetch` - HTTP requests
- `repomix` - Codebase packaging
