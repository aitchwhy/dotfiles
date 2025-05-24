# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Tool Configuration

These are the optimized settings for various CLI tools in the dotfiles:

| Tool      | Key Configurations                                   |
|-----------|------------------------------------------------------|
| Aerospace | `hyper-; = 'focus window-hint'` (window jumping)     |
| Atuin     | `workspaces=true`, `enter_accept=true`, `sync_frequency="60m"` |
| Bat       | `BAT_THEME="--theme=OneHalfDark"`, `DELTA_PAGER="bat --plain --paging=never"` |
| FZF       | 40% height, reverse layout, keybindings (ctrl-j/k navigation) |
| Git       | Safe pushes (`--force-with-lease = false`), current branch default |
| Glow      | Uses bat as pager for markdown preview               |
| Homebrew  | Analytics disabled                                   |
| htop      | IO Read/Write columns, optimized fields display      |
| just      | `summary = "on"`, zsh shell mode                     |
| yazi      | 5MB max file size for previews                       |
| starship  | Right prompt with time/battery, Tokyo Night theme    |

## Commands

### Linting & Formatting
- Format Lua: `stylua -c config/nvim/`
- Lint Lua: `selene config/nvim/`
- Python formatting: `ruff format <file.py>`
- Shell formatting: `shfmt -i 2 -ci <file.sh>`
- JavaScript/TypeScript linting: `eslint_d <file.js>`
- Validate Lua configuration: `nvim --headless -c "lua require('config.lazy')" -c "q"`

### Testing
- Individual Lua test: `busted -m config/nvim/lua/tests <test_file>`
- Single Neovim plugin test: `cd config/nvim && plenary-test spec/<plugin_name>_spec.lua`

## Style Guidelines

- **Indentation**: 2 spaces for most files, 4 spaces for Python
- **Line Length**: 120 characters maximum (per stylua.toml)
- **String Quotes**: Single quotes for Lua, double quotes for other languages
- **Naming**: camelCase for functions, snake_case for variables
- **Imports**: Group imports by type, sort alphabetically
- **Error Handling**: Use pcall/xpcall in Lua, try/catch in JavaScript
- **Comments**: Minimal, only when necessary to explain complex logic
- **Configuration**: Follow LazyVim conventions for Neovim configs
- **Cursor Rules**: Keep rules DRY, include both DO and DON'T examples
- **Commits**: Clear, atomic changes with descriptive messages