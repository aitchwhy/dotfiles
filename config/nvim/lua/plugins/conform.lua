return {
    -- Modern formatting
    {
        "stevearc/conform.nvim",
        -- event = { "BufWritePre" },
        -- cmd = { "ConformInfo" },
        -- keys = {
        --     {
        --         "<leader>f",
        --         function()
        --             require("conform").format({ async = true, lsp_fallback = true })
        --         end,
        --         desc = "Format buffer",
        --     },
        -- },
        -- -- This will provide type hinting with LuaLS
        -- ---@module "conform"
        -- ---@type conform.setupOpts
        -- opts = {
        --     formatters_by_ft = {
        --         lua = { "stylua" },
        --         python = { "ruff_format", "black" },
        --         javascript = { "prettierd", "prettier" },
        --         typescript = { "prettierd", "prettier" },
        --         javascriptreact = { "prettierd", "prettier" },
        --         typescriptreact = { "prettierd", "prettier" },
        --         json = { "prettierd", "prettier" },
        --         yaml = { "prettierd", "prettier" },
        --         markdown = { "prettierd", "prettier" },
        --         -- go = { "gofumpt" },
        --         ruby = { "rubyfmt" },
        --         rust = { "rustfmt" },
        --         ["*"] = { "trim_whitespace", "trim_newlines" },
        --     },
        --     -- -- Customize formatters
        --     -- formatters = {
        --     --     shfmt = {
        --     --         prepend_args = { "-i", "2" },
        --     --     },
        --     -- },
        -- },
    },
}
