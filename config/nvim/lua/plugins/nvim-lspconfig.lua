-- LSP configuration for LazyVim 15.x
-- Single source of truth for all custom LSP server configurations
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- Lua LSP with custom diagnostics
        lua_ls = {
          settings = {
            Lua = {
              diagnostics = {
                disable = { "mixed-table" },
              },
            },
          },
        },
        -- Nix LSP (installed via Nix, not Mason)
        nixd = {},
        -- Disable LazyVim's default nil_ls (we use nixd)
        nil_ls = false,
      },
    },
  },
}
