-- Debug Adapter Protocol configuration
-- Extends LazyVim's dap.core and lang.typescript with attach configs for Node.js
return {
  {
    "mfussenegger/nvim-dap",
    keys = {
      {
        "<leader>dB",
        function()
          require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
        end,
        desc = "Breakpoint Condition",
      },
      {
        "<leader>db",
        function()
          require("dap").toggle_breakpoint()
        end,
        desc = "Toggle Breakpoint",
      },
      {
        "<leader>dc",
        function()
          require("dap").continue()
        end,
        desc = "Run/Continue",
      },
      {
        "<leader>dC",
        function()
          require("dap").run_to_cursor()
        end,
        desc = "Run to Cursor",
      },
      {
        "<leader>di",
        function()
          require("dap").step_into()
        end,
        desc = "Step Into",
      },
      {
        "<leader>do",
        function()
          require("dap").step_out()
        end,
        desc = "Step Out",
      },
      {
        "<leader>dO",
        function()
          require("dap").step_over()
        end,
        desc = "Step Over",
      },
      {
        "<leader>dp",
        function()
          require("dap").pause()
        end,
        desc = "Pause",
      },
      {
        "<leader>dr",
        function()
          require("dap").repl.toggle()
        end,
        desc = "Toggle REPL",
      },
      {
        "<leader>ds",
        function()
          require("dap").session()
        end,
        desc = "Session Info",
      },
      {
        "<leader>dt",
        function()
          require("dap").terminate()
        end,
        desc = "Terminate",
      },
      {
        "<leader>dw",
        function()
          require("dap.ui.widgets").hover()
        end,
        desc = "Widgets",
      },
      -- Direct attach to Node.js inspector (most common workflow)
      {
        "<leader>dA",
        function()
          require("dap").run({
            type = "pwa-node",
            request = "attach",
            name = "Attach to localhost:9229",
            address = "localhost",
            port = 9229,
            cwd = vim.fn.getcwd(),
            sourceMaps = true,
            skipFiles = { "<node_internals>/**", "${workspaceFolder}/node_modules/**" },
            resolveSourceMapLocations = { "${workspaceFolder}/**", "!**/node_modules/**" },
          })
        end,
        desc = "Attach to Node (9229)",
      },
    },

    opts = function()
      local dap = require("dap")
      local js_filetypes = { "typescript", "javascript", "typescriptreact", "javascriptreact" }

      for _, language in ipairs(js_filetypes) do
        dap.configurations[language] = dap.configurations[language] or {}

        -- Insert direct attach at the TOP of the list (appears first in picker)
        table.insert(dap.configurations[language], 1, {
          type = "pwa-node",
          request = "attach",
          name = "Attach to localhost:9229",
          address = "localhost",
          port = 9229,
          cwd = "${workspaceFolder}",
          sourceMaps = true,
          restart = true, -- Auto-reconnect on server restart (tsx watch)
          skipFiles = { "<node_internals>/**", "${workspaceFolder}/node_modules/**" },
          resolveSourceMapLocations = { "${workspaceFolder}/**", "!**/node_modules/**" },
        })

        -- Custom port attach option (for non-standard ports)
        table.insert(dap.configurations[language], 2, {
          type = "pwa-node",
          request = "attach",
          name = "Attach to custom port",
          address = "localhost",
          port = function()
            return tonumber(vim.fn.input("Port: ", "9229"))
          end,
          cwd = "${workspaceFolder}",
          sourceMaps = true,
          restart = true,
          skipFiles = { "<node_internals>/**", "${workspaceFolder}/node_modules/**" },
          resolveSourceMapLocations = { "${workspaceFolder}/**", "!**/node_modules/**" },
        })
      end
    end,
  },

}
