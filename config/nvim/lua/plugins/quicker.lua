-- quicker.nvim - Enhanced quickfix with context and editing
return {
  {
    "stevearc/quicker.nvim",
    event = "FileType qf",
    opts = {
      -- Keymaps active inside quickfix buffer
      keys = {
        {
          ">",
          function()
            require("quicker").expand({ before = 2, after = 2, add_to_existing = true })
          end,
          desc = "Expand context",
        },
        {
          "<",
          function()
            require("quicker").collapse()
          end,
          desc = "Collapse context",
        },
      },
      -- Better highlighting
      highlight = {
        treesitter = true,
        lsp = false,
        load_buffers = false,
      },
    },
  },
}
