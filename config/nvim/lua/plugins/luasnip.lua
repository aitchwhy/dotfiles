-----------------------------------------------------------------------------------
-- LUASNIP - SNIPPET ENGINE
-----------------------------------------------------------------------------------
-- A flexible and powerful snippet engine for Neovim
-- Documentation: https://github.com/L3MON4D3/LuaSnip
-- Features:
-- * Supports multiple snippet formats (VS Code, Snipmate, etc.)
-- * Dynamic snippets, including transformations
-- * Integrates with nvim-cmp for completion
-- * LazyVim integration with common snippets
return {
    {
        "L3MON4D3/LuaSnip",
        -- -- Automatically compile C snippets on non-Windows
        -- build = (not jit.os:find("Windows"))
        --     and "echo 'NOTE: jsregexp is optional, so not a big deal if it fails to build'; make install_jsregexp"
        --     or nil,
        -- dependencies = {
        --     -- Load friendly-snippets collection
        --     "rafamadriz/friendly-snippets",
        --     config = function()
        --         -- Load VS Code style snippets from friendly-snippets
        --         require("luasnip.loaders.from_vscode").lazy_load()
        --     end,
        -- },
        -- Core snippet engine options
        -- opts = {
        --     history = true,                      -- Keep track of snippet history for undo/redo
        --     delete_check_events = "TextChanged", -- When to check if snippets should be deleted
        -- },
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
        end
        -- config = function(_, opts)
        --     local LazyVim = require("lazyvim.util")

        --     -- Initialize with options if provided
        --     if opts then
        --         require("luasnip").config.setup(opts)
        --     end

        --     -----------------------------------------------------------------------------------
        --     -- LAZYVIM INTEGRATION
        --     -----------------------------------------------------------------------------------

        --     -- Define snippet forwarding function for LazyVim utilities
        --     -- This enables navigation within snippets via the utility functions
        --     LazyVim.cmp.actions = LazyVim.cmp.actions or {}
        --     LazyVim.cmp.actions.snippet_forward = function()
        --         return require("luasnip").jump(1)
        --     end

        --     -- Define snippet cancellation function for LazyVim utilities
        --     -- This provides a way to stop snippet expansion when needed
        --     LazyVim.cmp.actions.snippet_stop = function()
        --         return require("luasnip").unlink_current()
        --     end

        --     -----------------------------------------------------------------------------------
        --     -- KEYMAPS FOR SNIPPETS
        --     -----------------------------------------------------------------------------------

        --     -- Tab key to expand snippets or jump to next placeholder
        --     vim.keymap.set({ "i", "s" }, "<Tab>", function()
        --         if require("luasnip").expand_or_jumpable() then
        --             return require("luasnip").expand_or_jump()
        --         end
        --         return "<Tab>" -- Fallback to regular tab if not in snippet
        --     end, { expr = true, silent = true })

        --     -- Shift-Tab to jump to previous placeholder
        --     vim.keymap.set({ "i", "s" }, "<S-Tab>", function()
        --         if require("luasnip").jumpable(-1) then
        --             return require("luasnip").jump(-1)
        --         end
        --         return "<S-Tab>" -- Fallback to regular shift-tab if not in snippet
        --     end, { expr = true, silent = true })
        -- end,
    },
}
