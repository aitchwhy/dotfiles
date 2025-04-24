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
        optional = true, -- Make it optional for configurations that don't need debugging

        -----------------------------------------------------------------------------------
        -- DEPENDENCIES AND EXTENSIONS
        -----------------------------------------------------------------------------------
        dependencies = {
            -- UI for nvim-dap with windows for variables, watches, etc.
            {
                "rcarriga/nvim-dap-ui",
                dependencies = { "nvim-neotest/nvim-nio" }, -- Required for async operations
                opts = {},                                  -- Use default configuration
                config = function(_, opts)
                    -- Setup UI integration
                    local dap = require("dap")
                    local dapui = require("dapui")
                    -- Initialize dapui with options
                    dapui.setup(opts)
                    -- Automatically open/close dapui when debugging sessions start/end
                    dap.listeners.after.event_initialized["dapui_config"] = function()
                        dapui.open({})
                    end
                    dap.listeners.before.event_terminated["dapui_config"] = function()
                        dapui.close({})
                    end
                    dap.listeners.before.event_exited["dapui_config"] = function()
                        dapui.close({})
                    end
                end,
            },
            -- Show debug information in virtual text
            {
                "theHamsta/nvim-dap-virtual-text",
                opts = {},
            },
        },
        -----------------------------------------------------------------------------------
        -- KEYMAPS
        -----------------------------------------------------------------------------------
        keys = {
            -- Set a conditional breakpoint
            {
                "<leader>dB",
                function()
                    require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
                end,
                desc = "Breakpoint Condition",
            },
            -- Toggle a breakpoint at current line
            {
                "<leader>db",
                function()
                    require("dap").toggle_breakpoint()
                end,
                desc = "Toggle Breakpoint",
            },
            -- Start/Continue debugging
            {
                "<leader>dc",
                function()
                    require("dap").continue()
                end,
                desc = "Continue",
            },
            -- Run to cursor position
            {
                "<leader>dC",
                function()
                    require("dap").run_to_cursor()
                end,
                desc = "Run to Cursor",
            },
            -- Go to specified line
            {
                "<leader>dg",
                function()
                    require("dap").goto_()
                end,
                desc = "Go to Line (no execute)",
            },
            -- Step into function/method
            {
                "<leader>di",
                function()
                    require("dap").step_into()
                end,
                desc = "Step Into",
            },
            -- Go down in stacktrace
            {
                "<leader>dj",
                function()
                    require("dap").down()
                end,
                desc = "Down",
            },
            -- Go up in stacktrace
            {
                "<leader>dk",
                function()
                    require("dap").up()
                end,
                desc = "Up",
            },
            -- Run last debug configuration
            {
                "<leader>dl",
                function()
                    require("dap").run_last()
                end,
                desc = "Run Last",
            },
            -- Step out of current function
            {
                "<leader>do",
                function()
                    require("dap").step_out()
                end,
                desc = "Step Out",
            },
            -- Step over function calls
            {
                "<leader>dO",
                function()
                    require("dap").step_over()
                end,
                desc = "Step Over",
            },
            -- Pause execution
            {
                "<leader>dp",
                function()
                    require("dap").pause()
                end,
                desc = "Pause",
            },
            -- Toggle REPL (Read-Eval-Print Loop)
            {
                "<leader>dr",
                function()
                    require("dap").repl.toggle()
                end,
                desc = "Toggle REPL",
            },
            -- Show current debug session info
            {
                "<leader>ds",
                function()
                    require("dap").session()
                end,
                desc = "Session",
            },
            -- Terminate debug session
            {
                "<leader>dt",
                function()
                    require("dap").terminate()
                end,
                desc = "Terminate",
            },
            -- Show variable values on hover
            {
                "<leader>dw",
                function()
                    require("dap.ui.widgets").hover()
                end,
                desc = "Widgets",
            },
        },
        -----------------------------------------------------------------------------------
        -- DEBUGGER CONFIGURATION
        -----------------------------------------------------------------------------------
        config = function()
            local LazyVim = require("lazyvim.util")
            
            -- Load nvim-dap configuration from LazyVim
            local Config = require("lazyvim.config")
            -- Configure highlighting for stopped line
            vim.api.nvim_set_hl(0, "DapStoppedLine", { default = true, link = "Visual" })

            -- Configure debug signs in the gutter
            for name, sign in pairs(Config.icons.dap) do
                sign = type(sign) == "table" and sign or { sign }
                vim.fn.sign_define(
                    "Dap" .. name,
                    { text = sign[1], texthl = sign[2] or "DiagnosticInfo", linehl = sign[3], numhl = sign[3] }
                )
            end
            
            -----------------------------------------------------------------------------------
            -- JAVASCRIPT/TYPESCRIPT DEBUGGER SETUP
            -----------------------------------------------------------------------------------

            -- Setup DAP adapter
            local dap = require("dap")
            -- Configure the Node.js debug adapter
            dap.adapters["pwa-node"] = {
                type = "server",
                host = "localhost",
                port = "${port}",
                executable = {
                    command = "node",
                    args = {
                        -- Find the path to the debug adapter
                        LazyVim.get_pkg_path("js-debug-adapter", "/js-debug/src/dapDebugServer.js"),
                        "${port}",
                    },
                },
            }
            
            -- Configure Node.js debugger for JavaScript files
            dap.configurations.javascript = {
                {
                    type = "pwa-node",
                    request = "launch",
                    name = "Launch file",
                    program = "${file}",        -- Debug current file
                    cwd = "${workspaceFolder}", -- Use project root directory
                },
            }

            -- Configure Chrome debugger for React/web applications
            dap.configurations.javascriptreact = {
                {
                    type = "pwa-chrome",
                    request = "launch",
                    name = "Launch Chrome",
                    url = "http://localhost:3000",  -- Default React dev server port
                    webRoot = "${workspaceFolder}", -- Project root directory
                },
            }

            -- Apply JavaScript config to TypeScript as well
            dap.configurations.typescript = dap.configurations.javascript
            dap.configurations.typescriptreact = dap.configurations.javascriptreact
        end,
    },
}
