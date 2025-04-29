-- return {
--   {
--     "saghen/blink.cmp",
--
--     ---@module 'blink.cmp'
--     ---@type blink.cmp.Config
--     opts = {
--
--       -- Use a preset for snippets, check the snippets documentation for more information
--       snippets = { preset = "default" },
--
--       -- 'prefix' will fuzzy match on the text before the cursor
--       -- 'full' will fuzzy match on the text before _and_ after the cursor
--       -- example: 'foo_|_bar' will match 'foo_' for 'prefix' and 'foo__bar' for 'full'
--       keyword = { range = "full" },
--
--       -- Don't select by default, auto insert on selection
--       list = { selection = { preselect = false, auto_insert = true } },
--       -- Display a preview of the selected item on the current line
--       ghost_text = { enabled = true },
--
--       fuzzy = { implementation = "prefer_rust_with_warning" },
--
--       sources = {
--         -- Remove 'buffer' if you don't want text completions, by default it's only enabled when LSP returns no items
--         -- add lazydev to your completion providers
--         default = { "lazydev", "lsp", "path", "snippets", "buffer" },
--         providers = {
--           lazydev = {
--             name = "LazyDev",
--             module = "lazydev.integrations.blink",
--             -- make lazydev completions top priority (see `:h blink.cmp`)
--             score_offset = 100,
--           },
--         },
--       },
--
--       -- snippets = {
--       --   preset = "default",
--       -- },
--       --
--     },
--   },
-- }

-- ~/.config/nvim/lua/plugins/blink-cmp.lua
return {
  {
    "saghen/blink.cmp",
    -- Load on entering Insert mode
    event = "InsertEnter",

    -- Optional dependency if you use lazydev as a source
    dependencies = {
      "saghen/blink.nvim", -- core blink engine
      {
        "LazyVim/LazyVim", -- ensure LazyDev integration is present
        optional = true,
      },
    },

    -- Plugin options
    opts = {
      -- Use snippet presets shipped with blink
      snippets = { preset = "default" },

      -- Fuzzy match keyword before & after cursor
      keyword = { range = "full" },

      -- Control list behavior: no pre-selection, auto-insert on selection
      list = {
        preselect = false,
        auto_insert = true,
      },

      -- Show ghost text inline on the current line
      ghost_text = { enabled = true },

      -- Fuzzy-matching implementation
      fuzzy = {
        implementation = "prefer_rust_with_warning",
      },

      -- Completion sources & their priority
      sources = {
        -- Default ordering (buffer only if no LSP items)
        -- default = { "lazydev", "lsp", "path", "snippets", "buffer" },
        compat = { "codeium" },
        providers = {
          codeium = {
            kind = "Codeium",
            score_offset = 100,
            async = true,
          },
          lazydev = {
            name = "LazyDev",
            module = "lazydev.integrations.blink",
            score_offset = 100, -- boost LazyDev completions above others
          },
        },
      },
    },

    -- Setup function: merge user opts & call setup
    config = function(_, opts)
      -- blink.cmp will merge these opts against its defaults
      require("blink.cmp").setup(opts)
    end,
  },
}
