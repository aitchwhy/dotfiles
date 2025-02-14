return {
    {
        "LazyVim/LazyVim",
        opts = {
            colorscheme = "catppuccin",
        }
    },

    -- nvim-web-devicons
    { "nvim-tree/nvim-web-devicons",                    opts = {} },

    -- mini.icons (standalone)
    { "echasnovski/mini.icons",                         version = false },





    -- use mini.starter instead of alpha
    { import = "lazyvim.plugins.extras.ui.mini-starter" },

    -- add jsonls and schemastore packages, and setup treesitter for json, json5 and jsonc
    { import = "lazyvim.plugins.extras.lang.json" },

    -- add any tools you want to have installed below
    {
        "williamboman/mason.nvim",
        opts = {
            ensure_installed = {
                "stylua",
                "shellcheck",
                "shfmt",
                "flake8",
            },
        },
    },

}
