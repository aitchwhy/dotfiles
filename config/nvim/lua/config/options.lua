-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-----------------------------------------------------------------------------------
-- VIM BEHAVIOR OPTIONS
-----------------------------------------------------------------------------------

-- disable mini-animate
vim.g.snacks_animate = false
vim.g.lazyvim_picker = "fzf"
vim.g.lazyvim_cmp = "blink.cmp"
-- vim.ui.select = Snacks.picker.select

-- In case you don't want to use `:LazyExtras`,
-- then you need to set the option below.
-- vim.g.lazyvim_picker = "snacks"
-- Disable providers you don't need
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0

vim.treesitter.language.register("bash", "zsh")

-- local opt = vim.opt
-- opt.tabstop = 4
