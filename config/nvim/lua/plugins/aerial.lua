-- Aerial configuration - override LazyVim defaults
-- Treesitter backend FIRST to show const declarations in TypeScript
return {
  "stevearc/aerial.nvim",
  opts = {
    -- Treesitter first - shows const/variable declarations that LSP misses
    backends = { "treesitter", "lsp", "markdown", "man" },
  },
}
