return {
    {
        "saghen/blink.cmp",
        opts = {
            -- 'default' for mappings similar to built-in completion
            -- 'super-tab' for mappings similar to vscode (tab to accept, arrow keys to navigate)
            -- 'enter' for mappings similar to 'super-tab' but with 'enter' to accept
            -- See the full "keymap" documentation for information on defining your own keymap.
            keymap = { preset = "enter" },

            -- -- Default list of enabled providers defined so that you can extend it
            -- -- elsewhere in your config, without redefining it, due to `opts_extend`
            -- sources = {
            --     default = { "lsp", "path", "snippets", "buffer" },
            -- },
        },
    },
}
