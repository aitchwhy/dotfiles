# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Linting & Formatting
- Format Lua: `stylua -c config/nvim/`
- Lint Lua: `selene config/nvim/`
- Python formatting: `ruff format <file.py>`
- Shell formatting: `shfmt -i 2 -ci <file.sh>`
- JavaScript/TypeScript linting: `eslint_d <file.js>`

### Testing
- Individual Lua test: `busted -m config/nvim/lua/tests <test_file>`

## Style Guidelines

- **Indentation**: 2 spaces for most files, 4 spaces for Python
- **Line Length**: 100 characters maximum
- **String Quotes**: Single quotes for Lua, double quotes for other languages
- **Naming**: camelCase for functions, snake_case for variables
- **Imports**: Group imports by type, sort alphabetically
- **Error Handling**: Use pcall/xpcall in Lua, try/catch in JavaScript
- **Comments**: Minimal, only when necessary to explain complex logic
- **Configuration**: Follow LazyVim conventions for Neovim configs