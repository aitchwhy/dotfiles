return {
    -- add colorscheme
    {
        "folke/tokyonight.nvim",
        opts = {
            style = "moon",
        },
    },

    -- Configure LazyVim to load tokyonight
    {
        "LazyVim/LazyVim",
        opts = {
            colorscheme = "tokyonight",
        },
    },
}
