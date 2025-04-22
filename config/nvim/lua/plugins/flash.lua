return {
    -- flash.nvim (Flash enhances the built-in search functionality by showing labels at the end of each match, letting you quickly jump to a specific location.)
    {
        name = "folke/flash.nvim",
        event = "VeryLazy",
        opts = {},
        -- keys = {
        --     {
        --         name = "s",
        --         mode = { "n", "x", "o" },
        --         function()
        --             require("flash").jump()
        --         end,
        --         desc = "Flash",
        --     },
        --     {
        --         "S",
        --         mode = { "n", "x", "o" },
        --         function()
        --             require("flash").treesitter()
        --         end,
        --         desc = "Flash Treesitter",
        --     },
        --     {
        --         "<c-s>",
        --         mode = { "c" },
        --         function()
        --             require("flash").toggle()
        --         end,
        --         desc = "Toggle Flash Search",
        --     },
        -- },
    },
}
