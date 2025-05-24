-----------------------------------------------------------------------------------
-- CONFORM.NVIM - CODE FORMATTING CONFIGURATION
-----------------------------------------------------------------------------------
-- Modern code formatter plugin with LSP integration
-- Documentation: https://github.com/stevearc/conform.nvim
-- Features:
-- * Format-on-save functionality
-- * Multiple formatter support and chaining
-- * Formatter installation via Mason
-- * LSP integration for fallback
return {
  -- Main formatter configuration
  {
    "stevearc/conform.nvim",
    opts = {
      lua = { "stylua" },
      javascript = { "prettier" },
      markdown = { "mdformat" },
      -- if you really want to bridge to none-ls:
    },
    -- OPTIONAL: disable the real none-ls plugin to avoid double-loading
    dependencies = {},
  },
}
