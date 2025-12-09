# Unified Agent Configuration

Single source of truth for AI coding assistants:
- **Claude Code CLI** (`~/.claude/`)
- **Gemini CLI** (`~/.gemini/`)
- **Antigravity IDE** (`~/.gemini/antigravity/`)

## Structure

```
config/agents/
├── AGENT.md                    # Canonical context (symlinked as CLAUDE.md/GEMINI.md)
├── mcp-servers.json            # Shared MCP server config
├── settings/
│   ├── claude-code.json        # Claude Code settings (hooks, permissions)
│   └── gemini.json             # Gemini CLI settings
├── commands/                   # Slash commands (16 total)
├── skills/                     # Skill pattern libraries (15 total)
├── agents/                     # Agent persona definitions (5 total)
├── hooks/                      # Pre/Post tool-use hooks
├── evolution/                  # Self-evolving system (graders, lessons, metrics)
├── nix/
│   └── agents.nix              # Home Manager module
├── setup.sh                    # Manual installation script
└── justfile                    # Task runner
```

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
just setup-project  # Creates ./CLAUDE.md and ./GEMINI.md symlinks

# Or using shell alias
agent-setup
agent-clean
```

### Justfile commands
```bash
just              # List all commands
just validate     # Validate JSON configs
just status       # Show symlink status
just grade        # Run evolution graders
just metrics      # Show evolution metrics
```

## MCP Servers

Shared across Claude Code CLI, Gemini CLI, and Antigravity:
- `memory` - Persistent memory
- `filesystem` - File access (~/src, ~/dotfiles, ~/Documents)
- `git` - Git operations
- `sequential-thinking` - Chain of thought
- `context7` - Documentation fetcher
- `fetch` - HTTP requests
- `repomix` - Codebase packaging

**Note:** Claude Desktop uses separate config with PATH wrapper for Electron compatibility.
See `modules/home/apps/claude.nix`.

## Evolution System

Self-improving configuration with:
- **Graders**: Automated quality scoring (config validity, git hygiene, nix health)
- **Lessons**: SQLite-backed learning from sessions
- **Hooks**: Pre/Post tool-use validation and formatting

```bash
cd ~/dotfiles/config/agents
just grade        # Run all graders
just metrics      # Show DORA-style metrics
```
