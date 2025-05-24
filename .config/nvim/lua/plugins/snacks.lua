return {
  {
    "folke/snacks.nvim",
    ---@type snacks.Config
    opts = {
      bigfile = { enabled = false },
      dashboard = { enabled = false },
      explorer = { enabled = false },
      indent = { enabled = false },
      input = { enabled = false },
      notifier = {
        enabled = false,
        timeout = 3000,
      },
      picker = { enabled = false },
      quickfile = { enabled = false },
      scope = { enabled = false },
      scroll = { enabled = false },
      statuscolumn = { enabled = false },
      words = { enabled = false },
      styles = {
        notification = {
          -- wo = { wrap = false } -- Wrap notifications
        },
      },
    },
  },
}
