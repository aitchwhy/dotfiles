-- lua/plugins/dap.lua

return {
  -- LazyVim DAP extra (core debugging setup: nvim-dap, nvim-dap-ui, etc.)
  { import = "lazyvim.plugins.extras.dap.core" },

  -- Mason integration for DAP adapters
  {
    "jay-babu/mason-nvim-dap.nvim",
    opts = {
      ensure_installed = {
        "debugpy", -- Python debugger
        "chrome", -- JS via Chrome debug
      },
      automatic_installation = true,
    },
  },
}
