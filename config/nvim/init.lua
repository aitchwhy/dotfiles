--------------------------
-- (init.lua) Lua config for neovim. Coming from Vim lanuage? See
-- https://neovim.io/doc/user/lua.html for the basics.
-- https://daler.github.io/dotfiles/vim.html

-- leader must be set before plugins are set up.
-- vim.cmd("let mapleader=','") -- Re-map leader from default \ to , (comma)
-- vim.cmd("let maplocalleader = '\\'") -- Local leader becomes \.

-- -- This allows nvim-tree to be used when opening a directory in nvim.
-- vim.g.loaded_netrw = 1
-- vim.g.loaded_netrwPlugin = 1
-- vim.cmd("set termguicolors") -- use full color in colorschemes
--------------------------

-- bootstrap lazy.nvim, LazyVim and your plugins
-- The files autocmds.lua, keymaps.lua, lazy.lua and options.lua under lua/config will be automatically loaded at the appropriate time, so you don't need to require those files manually. LazyVim comes with a set of default config files that will be loaded before your own.
require("config.lazy")
