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
    opts = function()
      LazyVim.cmp.actions.snippet_forward = function()
        if require("luasnip").jumpable(1) then
          vim.schedule(function()
            require("luasnip").jump(1)
          end)
          return true
        end
      end
      LazyVim.cmp.actions.snippet_stop = function()
        if require("luasnip").expand_or_jumpable() then -- or just jumpable(1) is fine?
          require("luasnip").unlink_current()
          return true
        end
      end
    end,
  },
  { "saadparwaiz1/cmp_luasnip" },
}
