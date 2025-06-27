-----------------------------------------------------------------------------------
-- LUASNIP - SNIPPET ENGINE
-----------------------------------------------------------------------------------
-- A flexible and powerful snippet engine for Neovim
-- Documentation: https://github.com/L3MON4D3/LuaSnip
-- Features:
-- * Supports multiple snippet formats (VS Code, Snipmate, etc.)
-- * Dynamic snippets, including transformations
-- * Integrates with nvim-cmp for completion
-- * LazyVim integration with common snippets
return {
  {
    "L3MON4D3/LuaSnip",
    opts = {
      history = true,
      delete_check_events = "TextChanged",
    },
  },
  { "saadparwaiz1/cmp_luasnip" },
}
