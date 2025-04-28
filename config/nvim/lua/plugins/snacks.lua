-----------------------------------------------------------------------------------
-- SNACKS.NVIM - QUICK ACCESS UTILITIES
-----------------------------------------------------------------------------------
-- A utility plugin that provides quick access to files, commands and more
-- Documentation: https://github.com/kevinhwang91/snacks.nvim
-- Features:
-- * Fast file navigation and fuzzy finding
-- * Project-aware file browsing
-- * Integrated with LazyVim keymaps
return {
  {
    "folke/snacks.nvim",
    ---@type snacks.Config
    opts = {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
      bigfile = { enabled = true },
      quickfile = { enabled = true },
      dashboard = { enabled = true },
      explorer = { enabled = false },
      terminal = { enabled = true },

      indent = { enabled = true },
      input = { enabled = true },
      notifier = { enabled = true },
      scope = { enabled = true },
      scroll = { enabled = true },
      statuscolumn = { enabled = false }, -- we set this in options.lua
      -- toggle = { map = LazyVim.safe_keymap_set },
      words = { enabled = true },

      picker = {
        enabled = true,
        -- win = {
        --   input = {
        --     keys = {
        --       ["<a-c>"] = {
        --         "toggle_cwd",
        --         mode = { "n", "i" },
        --       },
        --     },
        --   },
        -- },
        -- actions = {
        --   ---@param p snacks.Picker
        --   toggle_cwd = function(p)
        --     local root = LazyVim.root({ buf = p.input.filter.current_buf, normalize = true })
        --     local cwd = vim.fs.normalize((vim.uv or vim.loop).cwd() or ".")
        --     local current = p:cwd()
        --     p:set_cwd(current == root and cwd or root)
        --     p:find()
        --   end,
        -- },
      },
    },
  },
}
