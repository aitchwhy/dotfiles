-- Options for LazyVim 15.x
-- Loaded before lazy.nvim startup

-- LazyVim settings
vim.g.lazyvim_cmp = "blink.cmp"
vim.g.lazyvim_picker = "snacks"
vim.g.autoformat = true
vim.g.snacks_animate = false
vim.g.ai_cmp = false -- Disable ghost text for AI completions (set true to enable)

-- Editor settings
vim.opt.termguicolors = true
vim.opt.clipboard = "unnamedplus"
vim.opt.mouse = "a"
vim.opt.grepprg = "rg --vimgrep"

-- Register zsh as bash for treesitter
vim.treesitter.language.register("bash", "zsh")
