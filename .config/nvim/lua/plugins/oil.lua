return {
  {
    "stevearc/oil.nvim",
    ---@module 'oil'
    ---@type oil.SetupOpts
    opts = {
      default_file_explorer = true,
      watch_for_changes = false,
      view_options = {
        show_hidden = true,
      },
    },
    dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if you prefer nvim-web-devicons
  },
}
