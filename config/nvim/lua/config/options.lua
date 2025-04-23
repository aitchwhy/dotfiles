-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-----------------------------------------------------------------------------------
-- VIM BEHAVIOR OPTIONS
-----------------------------------------------------------------------------------

-- -- Better UI
-- vim.opt.termguicolors = true        -- Enable 24-bit RGB color in the TUI
-- vim.opt.number = true               -- Show line numbers
-- vim.opt.relativenumber = true       -- Show relative line numbers
-- vim.opt.signcolumn = "yes"          -- Always show the sign column
-- vim.opt.cursorline = true           -- Highlight the current line
-- vim.opt.scrolloff = 8               -- Minimum number of screen lines above/below cursor
-- vim.opt.sidescrolloff = 8           -- Minimum number of screen columns to keep around cursor

-- -- Editor behavior
-- vim.opt.expandtab = true            -- Use spaces instead of tabs
-- vim.opt.shiftwidth = 2              -- Size of an indent
-- vim.opt.tabstop = 2                 -- Number of spaces tabs count for
-- vim.opt.smartindent = true          -- Insert indents automatically
-- vim.opt.wrap = false                -- Disable line wrap by default
-- vim.opt.breakindent = true          -- Maintain indent when wrapping is enabled
-- vim.opt.linebreak = true            -- Wrap on word boundaries when wrap is enabled
-- vim.opt.mouse = "a"                 -- Enable mouse in all modes

-- -- Search
-- vim.opt.ignorecase = true           -- Ignore case in search patterns
-- vim.opt.smartcase = true            -- Override ignorecase if search contains uppercase
-- vim.opt.hlsearch = true             -- Highlight all matches on previous search pattern
-- vim.opt.incsearch = true            -- Show matches while typing search pattern

-- -- Files and buffers
-- vim.opt.undofile = true             -- Enable persistent undo
-- vim.opt.swapfile = false            -- Disable swap files
-- vim.opt.backup = false              -- Disable backup files
-- vim.opt.hidden = true               -- Allow switching from unsaved buffers
-- vim.opt.autoread = true             -- Auto-reload files changed outside of vim
-- vim.opt.confirm = true              -- Prompt to save changed files instead of failing commands
-- vim.opt.fileencoding = "utf-8"      -- File encoding

-- -- Performance and system
-- vim.opt.updatetime = 250            -- Faster completion and better UX
-- vim.opt.timeoutlen = 300            -- Time to wait for a key code or mapped key sequence
-- vim.opt.lazyredraw = true           -- Don't redraw while executing macros
-- vim.opt.history = 500               -- Remember more commands and searches

-- -- Clipboard
-- vim.opt.clipboard = "unnamedplus"   -- Use system clipboard for all operations

-- -- Split behavior
-- vim.opt.splitbelow = true           -- Put new windows below current
-- vim.opt.splitright = true           -- Put new windows right of current

-- -- Completion
-- vim.opt.completeopt = { "menu", "menuone", "noselect" }  -- For better completion experience

-- -- Misc
-- vim.g.mapleader = " "               -- Set leader key to space
-- vim.g.maplocalleader = ","          -- Set local leader key-- Disable providers that are optional and causing warnings
-- vim.g.loaded_ruby_provider = 0    -- Disable Ruby provider
-- vim.g.loaded_perl_provider = 0    -- Disable Perl provider
-- LSP Server to use for Python.
-- Set to "basedpyright" to use basedpyright instead of pyright.
-- vim.g.lazyvim_python_lsp = "pyright"
-- Set to "ruff_lsp" to use the old LSP implementation version.
-- vim.g.lazyvim_python_ruff = "ruff"
