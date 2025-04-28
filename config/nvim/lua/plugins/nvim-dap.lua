-----------------------------------------------------------------------------------
-- NVIM-DAP - DEBUG ADAPTER PROTOCOL INTEGRATION
-----------------------------------------------------------------------------------
-- Debugger support for Neovim
-- Documentation: https://github.com/mfussenegger/nvim-dap
-- Features:
-- * Support for multiple programming languages
-- * UI integration with floating windows
-- * Customizable keymaps and configurations
-- * Virtual text support for debugging info
return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "theHamsta/nvim-dap-virtual-text",
      "jay-babu/mason-nvim-dap.nvim",
    },
    config = function()
      local dap = require("dap")

      -- Fix the Haskell adapter path
      dap.adapters.haskell = {
        type = 'executable',
        command = vim.fn.expand('~/.local/share/nvim/mason/bin/haskell-debug-adapter'),
        args = {}
      }

      -- Your other DAP configurations
    end,
  }
}
