-- FZF-LUA CONFIGURATION FOR LAZYVIM 8.X
-- Configures fzf-lua as the default fuzzy finder for LazyVim
return {
  {
    "ibhagwan/fzf-lua",
    -- optional for icon support
    dependencies = { "nvim-tree/nvim-web-devicons" },
    -- or if using mini.icons/mini.nvim
    -- dependencies = { "echasnovski/mini.icons" },
    opts = {},
  },
}
