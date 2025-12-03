return {
    {
        "nvim-neotest/neotest",
        opts = {
            -- Can be a list of adapters like what neotest expects,
            -- or a list of adapter names,
            -- or a table of adapter names, mapped to adapter configs.
            -- The adapter will then be automatically loaded with the config.
            adapters = {},
            -- Example for loading neotest-golang with a custom config
            -- adapters = {
            --   ["neotest-golang"] = {
            --     go_test_args = { "-v", "-race", "-count=1", "-timeout=60s" },
            --     dap_go_enabled = true,
            --   },
            -- },
            status = { virtual_text = true },
            output = { open_on_run = true },
            quickfix = {
                open = function()
                    if LazyVim.has("trouble.nvim") then
                        require("trouble").open({ mode = "quickfix", focus = false })
                    else
                        vim.cmd("copen")
                    end
                end,
            },

        },
    },
}
