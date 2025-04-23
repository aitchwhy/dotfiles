return {
    {
        "L3MON4D3/LuaSnip",
        opts = function()
            LazyVim.cmp.actions.snippet_forward = function()
                if require("luasnip").jumpable(1) then
                    vim.schedule(function()
                        require("luasnip").jump(1)
                    end)
                    return true
                end
            end
            LazyVim.cmp.actions.snippet_stop = function()
                if require("luasnip").expand_or_jumpable() then -- or just jumpable(1) is fine?
                    require("luasnip").unlink_current()
                    return true
                end
            end
        end,
    },
}
