return {

    -- -- add jsonls and schemastore packages, and setup treesitter for json, json5 and jsonc
    -- { import = "lazyvim.plugins.extras.lang.json" },
    --
    -- -- for typescript, LazyVim also includes extra specs to properly setup lspconfig,
    -- -- treesitter, mason and typescript.nvim. So instead of the above, you can use:
    -- { import = "lazyvim.plugins.extras.lang.typescript" },

    -- -- add more treesitter parsers
    -- {
    --     "nvim-treesitter/nvim-treesitter",
    --     opts = {
    --         ensure_installed = {
    --             "bash",
    --             "html",
    --             "javascript",
    --             "json",
    --             "lua",
    --             "markdown",
    --             "markdown_inline",
    --             "python",
    --             "query",
    --             "regex",
    --             "tsx",
    --             "typescript",
    --             "vim",
    --             "yaml",
    --         },
    --     },
    -- },

    -- since `vim.tbl_deep_extend`, can only merge tables and not lists, the code above
    -- would overwrite `ensure_installed` with the new value.
    -- If you'd rather extend the default config, use the code below instead:
    {
        "nvim-treesitter/nvim-treesitter",
        opts = function(_, opts)
            -- add tsx and treesitter
            vim.list_extend(opts.ensure_installed, {
                "tsx",
                "typescript",
            })
        end,
    },
}
