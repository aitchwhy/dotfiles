# sig - Signet-aware Claude Code Launcher

## Installation

The `sig` script is located at `~/dotfiles/scripts/sig`.

Add to your shell configuration (handled by Nix if using dotfiles):
```bash
# In ~/.zshrc or modules/home/shell/aliases.nix
alias sig="$HOME/dotfiles/scripts/sig"
```

Or add `~/dotfiles/scripts` to your PATH.

## Usage

```bash
sig                     # Launch Claude Code in current directory
sig ~/src/myproject     # Launch in specific directory
sig -v                  # Verbose mode
sig --no-hooks          # Disable hooks for debugging
sig --status            # Show configuration status
```

## Options

| Option | Description |
|--------|-------------|
| `-v, --verbose` | Enable verbose output |
| `--no-hooks` | Disable all hooks (for debugging) |
| `--status` | Show configuration status and exit |
| `-h, --help` | Show help message |

## Configuration Status

`sig --status` displays:
- Claude command availability
- Settings.json location and hook count
- MCP servers configuration
- PARAGON guard status
- AGENTS.md (SSOT) location
- Environment variable overrides

## Environment Variables

| Variable | Description |
|----------|-------------|
| `CLAUDE_DISABLE_HOOKS` | Set to 1 to disable all hooks |
| `CLAUDE_VERBOSE` | Set to 1 for verbose output |

## Future Enhancements

Planned features (not yet implemented):
- `-m, --mcp NAME` - Dynamically load MCP servers
- `-s, --skill NAME` - Initialize with specific skill context
- `--model MODEL` - Override default model

## Related

- `config/agents/AGENTS.md` - Single source of truth for agent instructions
- `config/agents/settings.json` - Hook configuration
- `modules/home/apps/claude.nix` - MCP server definitions
