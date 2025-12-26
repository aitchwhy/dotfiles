-- Minimal init for headless testing
-- Used by CI and PlenaryBustedDirectory

-- Set up paths
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local plenarypath = vim.fn.stdpath("data") .. "/site/pack/test/start/plenary.nvim"

-- Add to runtime path
vim.opt.rtp:prepend(lazypath)
vim.opt.rtp:prepend(plenarypath)

-- Minimal options for testing
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.writebackup = false

-- Load plenary if available
local ok, _ = pcall(require, "plenary")
if not ok then
  print("Warning: plenary.nvim not found - some tests may be skipped")
end
