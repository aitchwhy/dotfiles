-- ~/.config/nvim/lua/plugins/lspconfig.lua
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
    },
  },
}
