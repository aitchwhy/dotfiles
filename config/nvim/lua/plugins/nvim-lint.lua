return {
    -- Modern linting
    {
        "mfussenegger/nvim-lint",
        opts = {
            -- Event to trigger linters
            -- events = { "BufWritePost", "BufReadPost", "InsertLeave" },
            linters_by_ft = {
                fish = { "fish" },
                -- Use the "*" filetype to run linters on all filetypes.
                -- ['*'] = { 'global linter' },
                python = { "ruff" },
                javascript = { "eslint_d" },
                typescript = { "eslint_d" },
                javascriptreact = { "eslint_d" },
                typescriptreact = { "eslint_d" },
                lua = { "selene" },
                markdown = { "markdownlint" },
                yaml = { "actionlint" },
                dockerfile = { "hadolint" },

                -- Use the "_" filetype to run linters on filetypes that don't have other linters configured.
                -- ['_'] = { 'fallback linter' },
                -- ["*"] = { "typos" },
            },

            -- LazyVim extension to easily override linter options
            -- or add custom linters.
            ---@type table<string,table>
            linters = {
                -- -- Example of using selene only when a selene.toml file is present
                -- selene = {
                --   -- `condition` is another LazyVim extension that allows you to
                --   -- dynamically enable/disable linters based on the context.
                --   condition = function(ctx)
                --     return vim.fs.find({ "selene.toml" }, { path = ctx.filename, upward = true })[1]
                --   end,
                -- },
            },
        },
    },
}
