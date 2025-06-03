return {
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {
      modes = {
        -- We turn off the stock char-jump on `s`
        char = { enabled = false },

        -- Treesitter picker on  <leader>S
        treesitter = {
          labels = "arstneio", -- pick any label set you like
        },
      },
    },
    keys = {
      -- Remote operator-pending jump
      {
        "<leader>s",
        function()
          require("flash").remote()
        end,
        mode = { "o" },
        desc = "Flash Remote",
      },

      -- Fancy treesitter jump
      {
        "<leader>S",
        function()
          require("flash").treesitter()
        end,
        mode = { "n", "x", "o" },
        desc = "Flash Treesitter",
      },

      -- If you still want two-char leap, map it somewhere that
      -- doesn’t start with plain `s` so Surround keeps working:
      {
        "gl",
        function()
          require("flash").jump()
        end,
        mode = { "n", "x", "o" },
        desc = "Flash jump (2-char)",
      },
    },
  },
}
