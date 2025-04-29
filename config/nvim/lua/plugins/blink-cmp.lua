return {
  {
    "saghen/blink.cmp",

    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {

      -- Use a preset for snippets, check the snippets documentation for more information
      snippets = { preset = "default" },

      -- 'prefix' will fuzzy match on the text before the cursor
      -- 'full' will fuzzy match on the text before _and_ after the cursor
      -- example: 'foo_|_bar' will match 'foo_' for 'prefix' and 'foo__bar' for 'full'
      keyword = { range = "full" },

      -- Don't select by default, auto insert on selection
      list = { selection = { preselect = false, auto_insert = true } },
      -- Display a preview of the selected item on the current line
      ghost_text = { enabled = true },

      fuzzy = { implementation = "prefer_rust_with_warning" },

      sources = {
        -- Remove 'buffer' if you don't want text completions, by default it's only enabled when LSP returns no items
        -- add lazydev to your completion providers
        default = { "lazydev", "lsp", "path", "snippets", "buffer" },
        providers = {
          lazydev = {
            name = "LazyDev",
            module = "lazydev.integrations.blink",
            -- make lazydev completions top priority (see `:h blink.cmp`)
            score_offset = 100,
          },
        },
      },

      -- snippets = {
      --   preset = "default",
      -- },
      --
    },
  },
}
