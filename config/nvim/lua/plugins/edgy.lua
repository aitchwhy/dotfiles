return {
  {
    -- configurable window layout
    "folke/edgy.nvim",
    event = "VeryLazy",
    opts = {
      --   -- Don't override the window navigation keymaps
      keys = {
        -- Disable the defaults to avoid conflicts
        ["<C-h>"] = false,
        ["<C-j>"] = false,
        ["<C-k>"] = false,
        ["<C-l>"] = false,
        --     -- Custom movement keys that don't conflict
        --     ["<M-h>"] = "left", -- Alt+h
        --     ["<M-j>"] = "down",  -- Alt+j
        --     ["<M-k>"] = "up", -- Alt+k
        --     ["<M-l>"] = "right", -- Alt+l
        --   },
        --   exit_when_last = true,
        --   bottom = {
        --     -- Use lower percentage for terminal height
        --     size = 0.3, -- 30% of screen height
        --   },
        --   left = {
        --     -- Use reasonable width for sidebar
        --     size = 0.25, -- 25% of screen width
        --   },
        --   right = {
        --     -- Use reasonable width for sidebar
        --     size = 0.25, -- 25% of screen width
        --   },
        --   animate = {
        --     enabled = true,
        --     fps = 100,
        --     cps = 120,
        --     on_enter = true,
        --     on_leave = true,
      },
    },
  },
}
