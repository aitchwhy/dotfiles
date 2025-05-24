# Neovim Configuration

A modern, fully-featured Neovim setup based on LazyVim with optimized configurations for development and text editing. This setup includes LSP support, fuzzy finding, Git integration, and more, wrapped in a Tokyo Night theme.

## Features

- 🚀 Based on [LazyVim](https://www.lazyvim.org/) for a solid foundation
- 🔍 LSP integration for intelligent code completion and navigation
- 🌳 Treesitter for advanced syntax highlighting and code understanding
- 🔎 Fuzzy finding with FZF and Telescope
- 📝 Multiple editing modes with different levels of assistance
- 🧠 AI coding assistance with Copilot integration
- 🧩 Code snippets and intelligent completion
- 🎨 Beautiful Tokyo Night theme with custom tweaks
- ⚡ Optimized for performance on Apple Silicon

## Structure

The configuration follows a modular structure for better organization:

```
~/.config/nvim/
├── init.lua                 # Main entry point
├── lazyvim.json             # LazyVim configuration
├── stylua.toml              # Lua formatting config
└── lua/
    ├── config/              # Core configuration
    │   ├── autocmds.lua     # Automatic commands
    │   ├── keymaps.lua      # Custom key mappings
    │   ├── lazy.lua         # Plugin manager setup
    │   └── options.lua      # Vim options
    └── plugins/             # Plugin configurations
        ├── blink-cmp.lua    # Completion
        ├── catppuccin.lua   # Theme
        ├── conform.lua      # Formatting
        ├── copilot.lua      # AI assistance
        ├── edgy.lua         # UI sidebar improvements
        ├── fzf-lua.lua      # Fuzzy finding
        ├── which-key.lua    # Key binding help
        ├── yazi.lua         # File manager integration
        └── ...              # Other plugin configurations
```

## Key Bindings

This configuration uses Space as the leader key. Here are some important key bindings:

### General

- `<Space>` - Leader key (access to most commands)
- `<Space>f` - Find files
- `<Space>g` - Git commands
- `<Space>b` - Buffer commands
- `<Space>/` - Search in current buffer
- `<Space>:` - Command history
- `<Space>w` - Window commands

### Navigation

- `<C-h/j/k/l>` - Navigate between windows
- `H/L` - Previous/next buffer
- `gd` - Go to definition
- `gr` - Go to references
- `K` - Show documentation

### Code Editing

- `<Space>c` - Code actions
- `<Space>r` - Rename symbol
- `<Space>d` - Diagnostics
- `<Space>lf` - Format document
- `<Space>lr` - Rename symbol
- `gc` - Comment toggle

### Terminal and File Explorer

- `<Space>ft` - Terminal
- `<Space>e` - File explorer
- `<Space>o` - Oil file manager

## Plugin Highlights

- **LSP**: Native LSP with nvim-lspconfig and mason.nvim for easy setup
- **Completion**: nvim-cmp with various sources (LSP, buffer, path, snippets)
- **Git**: Integration with LazyGit, Gitsigns, and Fugitive
- **UI**: Lualine, Noice, and nvim-notify for an enhanced interface
- **Navigation**: Telescope, FZF, and Harpoon for quick file navigation
- **Editing**: Multiple plugins for text editing enhancement

## Installation

This configuration is installed automatically by the setup.sh script.

For manual installation:

1. Ensure Neovim 0.9+ is installed: `brew install neovim`
2. Create the config directory: `mkdir -p ~/.config/nvim`
3. Symlink the configuration: `ln -s ~/dotfiles/config/nvim ~/.config/nvim`
4. Start Neovim to install plugins: `nvim`

## Dependencies

Some external programs enhance this Neovim setup:

- `ripgrep` - Fast text search
- `fd` - Fast file finder
- `lazygit` - Git terminal UI
- `stylua` - Lua formatter
- `nodejs` - Required for Copilot and some LSP servers

## Customization

To customize further:

1. Edit files in `~/dotfiles/config/nvim/lua/config/` for core settings
2. Edit files in `~/dotfiles/config/nvim/lua/plugins/` for plugin configurations
3. Add new plugin configurations as separate files in the plugins directory

## Troubleshooting

If you encounter issues:

1. Update plugins: `:Lazy update`
2. Check health: `:checkhealth`
3. Clean and reinstall: `:Lazy clean` followed by `:Lazy sync`

## Resources

- [Neovim Documentation](https://neovim.io/doc/)
- [LazyVim Documentation](https://www.lazyvim.org/)
- [Awesome Neovim](https://github.com/rockerBOO/awesome-neovim) - Collection of awesome Neovim plugins