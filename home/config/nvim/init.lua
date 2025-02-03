-- -- Basic settings
-- vim.opt.number = true
-- vim.opt.relativenumber = true
-- vim.opt.mouse = 'a'

-- -- Plugin manager
-- local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
-- if not vim.loop.fs_stat(lazypath) then
--   vim.fn.system({
--     "git",
--     "clone",
--     "--filter=blob:none",
--     "https://github.com/folke/lazy.nvim.git",
--     lazypath,
--   })
-- end
-- vim.opt.rtp:prepend(lazypath)

-- require("lazy").setup({
--   -- Essential plugins
--   {'nvim-telescope/telescope.nvim', dependencies = {'nvim-lua/plenary.nvim'}},
--   {'nvim-treesitter/nvim-treesitter', build = ':TSUpdate'},
--   {'neovim/nvim-lspconfig'},
--   {'hrsh7th/nvim-cmp'},
  
--   -- Your custom plugins
--   {'ojroques/nvim-hardline'},  -- Status line
--   {'ibhagwan/fzf-lua'},        -- Better fzf integration
-- })

-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
