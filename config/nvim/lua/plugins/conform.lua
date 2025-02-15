return {
    -- Modern formatting
    {
        "stevearc/conform.nvim",
        event = { "BufWritePre" },
        cmd = { "ConformInfo" },
        keys = {
            {
                "<leader>f",
                function()
                    require("conform").format({ async = true, lsp_fallback = true })
                end,
                desc = "Format buffer",
            },
        },
        opts = {
            formatters_by_ft = {
                lua = { "stylua" },
                python = { "ruff_format", "black" },
                javascript = { { "prettierd", "prettier" } },
                typescript = { { "prettierd", "prettier" } },
                javascriptreact = { { "prettierd", "prettier" } },
                typescriptreact = { { "prettierd", "prettier" } },
                json = { { "prettierd", "prettier" } },
                yaml = { { "prettierd", "prettier" } },
                markdown = { { "prettierd", "prettier" } },
                go = { "gofumpt" },
                ruby = { "rubyfmt" },
                rust = { "rustfmt" },
                ["*"] = { "trim_whitespace", "trim_newlines" },
            },
            format_on_save = {
                timeout_ms = 500,
                lsp_fallback = true,
            },
        },
    },
}
