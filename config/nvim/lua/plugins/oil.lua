return {
  -- {
  --   "stevearc/oil.nvim",
  --   dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if you prefer nvim-web-devicons
  --   ---@module 'oil'
  --   ---@type oil.SetupOpts
  --   opts = {
  --     default_file_explorer = false,
  --     watch_for_changes = true,
  --     view_options = {
  --       show_hidden = true,
  --     },
  --   },
  -- },
  {
    "stevearc/oil.nvim",
    ---@module 'oil'
    ---@type oil.SetupOpts
    opts = {
      watch_for_changes = true,
      view_options = {
        show_hidden = true,
      },
    },
    -- Optional dependencies
    dependencies = { { "nvim-mini/mini.icons", opts = {} } },
    -- dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if you prefer nvim-web-devicons
    -- Lazy loading is not recommended because it is very tricky to make it work correctly in all situations.
    lazy = false,
  },
}
