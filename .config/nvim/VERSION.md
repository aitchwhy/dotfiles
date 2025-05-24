# Neovim Configuration Version Information

This document captures the version information and state of the Neovim configuration.

## Version Information

- **Neovim Version**: 0.11.1
- **Configuration Framework**: LazyVim
- **Last Updated**: 2025-05-03

## Dependencies

- **Required CLI Tools**:
  - ripgrep (14.1.1)
  - fd (10.2.0)
  - lazygit (0.50.0)
  - stylua (latest)
  - node.js (23.11.0) - For LSP servers and copilot
  - npm (11.3.0)

- **Optional Tools**:
  - gcc (14.2.0) - For treesitter compilation
  - python (3.12.10) - For python plugins

## Plugin Status

Key plugins installed and their status:

| Plugin | Version | Status |
|--------|---------|--------|
| lazy.nvim | latest | Working |
| nvim-lspconfig | latest | Working |
| nvim-treesitter | latest | Working |
| mason.nvim | latest | Working |
| telescope.nvim | latest | Working |
| neo-tree.nvim | latest | Working |
| which-key.nvim | latest | Working |
| mini.nvim | latest | Working |
| copilot.lua | latest | Working |
| nvim-cmp | latest | Working |
| lualine.nvim | latest | Working |
| telescope.nvim | latest | Working |
| tokyonight.nvim | latest | Working |

## Configuration Health

Results from `:checkhealth`:

- **Core**: No issues
- **LSP**: All servers working properly
- **Treesitter**: All parsers functioning
- **Clipboard**: Working with macOS clipboard
- **Performance**: Startup time < 100ms

## Debug Information

- **Lua Version**: 5.4.7
- **Config Path**: ~/.config/nvim
- **Data Path**: ~/.local/share/nvim
- **Plugin Path**: ~/.local/share/nvim/lazy
- **Swap Path**: ~/.local/state/nvim/swap
- **Log Path**: ~/.local/state/nvim/log

## Command Line Tools

Commands available for Neovim management:

```bash
# Edit configuration
nvim ~/.config/nvim/init.lua

# Update plugins
nvim --headless "+Lazy update" +qa

# Check health
nvim --headless "+checkhealth" "+write /tmp/nvim-health.txt" +qa

# Clean plugins
nvim --headless "+Lazy clean" +qa

# Sync plugins
nvim --headless "+Lazy sync" +qa

# Format Lua files
stylua ~/.config/nvim/lua
```

## Just Integration

Just tasks available for Neovim:

```
just nvim edit      # Edit Neovim config
just nvim update    # Update Neovim plugins
just nvim health    # Check Neovim health
just nvim clean     # Clean Neovim plugins
just nvim sync      # Sync Neovim plugins
just nvim format    # Format Neovim Lua files
just nvim plugins   # List all Neovim installed plugins
just nvim minimal   # Start Neovim with minimal config
just nvim scratch   # Start Neovim from scratch (no config)
```

## Recent Changes

- Updated to Neovim 0.11.1
- Migrated to latest LazyVim framework
- Added Tokyo Night theme integration
- Improved LSP configuration
- Enhanced Yazi integration
- Optimized for Apple Silicon performance