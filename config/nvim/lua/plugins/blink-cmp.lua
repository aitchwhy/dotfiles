-- Blink.cmp completion engine for LazyVim 15.x
-- NOTE: Copilot integration handled by lazyvim.plugins.extras.ai.copilot
return {
  {
    "saghen/blink.cmp",
    opts = {
      snippets = {
        preset = "luasnip",
      },
      appearance = {
        use_nvim_cmp_as_default = false,
        nerd_font_variant = "mono",
      },
      completion = {
        accept = {
          auto_brackets = { enabled = true },
        },
        menu = {
          draw = {
            treesitter = { "lsp" },
          },
        },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 200,
        },
        ghost_text = {
          enabled = vim.g.ai_cmp,
        },
      },
      signature = { enabled = true },
    },
  },
  {
    "saghen/blink.compat",
  },
}
