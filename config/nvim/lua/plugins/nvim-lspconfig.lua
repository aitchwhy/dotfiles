-- LSP configuration for LazyVim 15.x
return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      lua_ls = {
        settings = {
          Lua = {
            diagnostics = {
              disable = { "mixed-table" },
            },
          },
        },
      },
      nixd = {}, -- Nix LSP (installed via Nix)
    },
  },
}
