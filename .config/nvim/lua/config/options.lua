-----------------------------------------------------------------------------------
-- OPTIONS CONFIGURATION - LAZYVIM 8.X COMPATIBLE
-- -----------------------------------------------------------------------------------
-- -- Options are automatically loaded before lazy.nvim startup
-- -- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- -- Add any additional options here
--
-- -- LazyVim 8.x specific global settings
-- vim.g.lazyvim_picker = "fzf" -- Use fzf-lua as the picker
vim.g.lazyvim_cmp = "blink.cmp" -- Use blink.cmp as the completion engine
--
-- -- Disable providers you don't need for better startup performance
-- vim.g.loaded_perl_provider = 0
-- vim.g.loaded_ruby_provider = 0
--
-- -- Register zsh as a bash-like language for treesitter
vim.treesitter.language.register("bash", "zsh")
--
-- -- UI improvements
-- vim.opt.termguicolors = true -- Enable 24-bit RGB colors
-- vim.opt.number = true -- Show line numbers
-- vim.opt.relativenumber = true -- Show relative line numbers
-- vim.opt.signcolumn = "yes" -- Always show sign column
-- vim.opt.cursorline = true -- Highlight current line
-- vim.opt.showmode = false -- Don't show mode in command line (shown by statusline)
--
-- -- Editing experience
-- vim.opt.expandtab = true -- Use spaces instead of tabs
-- vim.opt.shiftwidth = 2 -- Size of an indent
-- vim.opt.tabstop = 2 -- Number of spaces tabs count for
-- vim.opt.softtabstop = 2 -- Number of spaces a tab counts for while editing
-- vim.opt.smartindent = true -- Insert indents automatically
-- vim.opt.wrap = false -- Disable line wrap
-- vim.opt.linebreak = true -- Break lines at word boundary
--
-- -- Search settings
-- vim.opt.ignorecase = true -- Ignore case when searching
-- vim.opt.smartcase = true -- Don't ignore case with capitals
-- vim.opt.inccommand = "split" -- Preview substitutions
--
-- -- System integration
-- vim.opt.clipboard = "unnamedplus" -- Use system clipboard
-- vim.opt.mouse = "a" -- Enable mouse in all modes
-- vim.opt.updatetime = 100 -- Faster completion
-- vim.opt.timeout = true -- Enable timeout for mappings
-- vim.opt.timeoutlen = 300 -- Time to wait for a mapped sequence
--
-- -- Folding with treesitter (Neovim 0.11+ compatible)
-- vim.opt.foldmethod = "expr"
-- vim.opt.foldexpr = "vim.treesitter.foldexpr()"
-- vim.opt.foldenable = true -- Disable folding by default
-- vim.opt.foldlevel = 99 -- High fold level to open folds by default
--
-- -- File handling
-- vim.opt.undofile = true -- Save undo history
-- vim.opt.confirm = true -- Confirm to save changes before exiting
-- vim.opt.autowrite = true -- Auto save before commands like :next and :make
--
-- -- Split preferences
-- vim.opt.splitbelow = true -- Put new windows below current
-- vim.opt.splitright = true -- Put new windows right of current
--
-- -- Performance
-- vim.opt.shadafile = "NONE" -- Disable shada file for faster startup
-- -- vim.opt.lazyredraw = true -- Don't redraw while executing macros
--
-- -- Disable some builtin plugins we don't need
-- -- vim.g.loaded_gzip = 1
-- -- vim.g.loaded_tarPlugin = 1
-- -- vim.g.loaded_zipPlugin = 1
-- -- vim.g.loaded_2html_plugin = 1
