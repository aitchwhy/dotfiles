-- Options for LazyVim 15.x
-- Loaded before lazy.nvim startup

-- LazyVim settings
vim.g.lazyvim_cmp = "blink.cmp"
vim.g.lazyvim_picker = "snacks"
vim.g.autoformat = true
vim.g.snacks_animate = false
vim.g.ai_cmp = false -- Disable ghost text for AI completions (Sidekick NES handles it)

-- Sidekick/AI settings
vim.g.sidekick_nes = true -- Enable Next Edit Suggestions

-- Editor settings
vim.opt.termguicolors = true
vim.opt.laststatus = 3        -- Global statusline (required for edgy.nvim collapse)
vim.opt.splitkeep = "screen"  -- Prevent main splits jumping with edgebar
vim.opt.clipboard = "unnamedplus"
vim.opt.mouse = "a"
vim.opt.grepprg = "rg --vimgrep"

-- Register zsh as bash for treesitter
vim.treesitter.language.register("bash", "zsh")
