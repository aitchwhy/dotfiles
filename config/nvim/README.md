# Neovim + Lazy.nvim setup

💤 LazyVim [docs](https://www.lazyvim.org/)

- [nvim tips](https://daler.github.io/dotfiles/vim.html)

## Folder structure

```
~/.config/nvim
├─ init.lua                         <-- Main entry point
├── lua
│   ├── config
│   │   ├── autocmds.lua            <-- User-defined autocmds
│   │   ├── keymaps.lua             <-- User-defined keymaps
│   │   ├── lazy.lua                <-- lazy.nvim framework entry
│   │   └── options.lua             <-- Custom vim.opt settings
│   └── plugins
│       ├─ core.lua                 <-- Your main Lazy setup, with LazyVim imports
│       ├─ lsp.lua                  <-- LSP overrides (mason.nvim, nvim-lspconfig)
│       ├─ formatting.lua           <-- conform.nvim, nvim-lint config
│       ├─ treesitter.lua           <-- Extra Treesitter config
│       ├─ editor.lua               <-- Editor enhancements (noice, flash, yanky, etc.)
│       └─ ... (any additional .lua for custom plugin configs)

```
