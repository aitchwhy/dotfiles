-----------------------------------------------------------------------------------
-- NVIM-CMP CONFIGURATION - AUTOCOMPLETION ENGINE
-----------------------------------------------------------------------------------
-- This file configures the completion engine for Neovim
-- The setup includes snippets, sources, keybindings, and UI appearance
-- References:
-- * https://github.com/hrsh7th/nvim-cmp
-- * https://github.com/L3MON4D3/LuaSnip

return {
    -----------------------------------------------------------------------------------
    -- MAIN COMPLETION ENGINE CONFIGURATION
    -----------------------------------------------------------------------------------
    {
        "hrsh7th/nvim-cmp",
        version = false,                -- Last release is too old, so we use the latest commit
        event = "InsertEnter",          -- Only load when entering insert mode for performance
        dependencies = {
            "hrsh7th/cmp-nvim-lsp",     -- LSP completion source
            "hrsh7th/cmp-buffer",       -- Buffer words completion source
            "hrsh7th/cmp-path",         -- Path completion source
            "saadparwaiz1/cmp_luasnip", -- Snippet completion source
        },
        opts = function()
            local cmp = require("cmp")
            local luasnip = require("luasnip")
            local defaults = require("cmp.config.default")()
            local LazyVim = require("lazyvim.util")

            -- Helper function to check if there's text before cursor
            -- Used for smart tab completion behavior
            local has_words_before = function()
                unpack = unpack or table.unpack
                local line, col = unpack(vim.api.nvim_win_get_cursor(0))
                return col ~= 0 and
                vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
            end

            return {
                -- Configure completion popup appearance
                completion = {
                    completeopt = "menu,menuone,noinsert", -- Don't insert text until selected
                },
                -- Configure snippet expansion
                snippet = {
                    expand = function(args)
                        luasnip.lsp_expand(args.body)
                    end,
                },
                -- Configure key mappings
                mapping = cmp.mapping.preset.insert({
                    -- Navigate completion menu
                    ["<C-n>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
                    ["<C-p>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
                    -- Scroll documentation window
                    ["<C-b>"] = cmp.mapping.scroll_docs(-4), -- Scroll up
                    ["<C-f>"] = cmp.mapping.scroll_docs(4),  -- Scroll down

                    -- Other controls
                    ["<C-Space>"] = cmp.mapping.complete(), -- Force completion menu
                    ["<C-e>"] = cmp.mapping.abort(),        -- Close completion menu

                    -- Accept completion
                    ["<CR>"] = cmp.mapping.confirm({ select = true }), -- Accept selected item

                    -- Accept with replacement behavior
                    ["<S-CR>"] = cmp.mapping.confirm({
                        behavior = cmp.ConfirmBehavior.Replace,
                        select = true,
                    }),

                    -- Abort completion and execute command
                    ["<C-CR>"] = function(fallback)
                        cmp.abort()
                        fallback()
                    end,
                    -- Tab for navigation and snippet expansion
                    ["<Tab>"] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.select_next_item()
                        elseif luasnip.expand_or_locally_jumpable() then
                            luasnip.expand_or_jump()
                        elseif has_words_before() then
                            cmp.complete()
                        else
                            fallback()
                        end
                    end, { "i", "s" }),
                    -- Shift-Tab for backward navigation
                    ["<S-Tab>"] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.select_prev_item()
                        elseif luasnip.jumpable(-1) then
                            luasnip.jump(-1)
                        else
                            fallback()
                        end
                    end, { "i", "s" }),
                }),
                -- Configure completion sources and their priority
                sources = cmp.config.sources({
                    { name = "nvim_lsp" }, -- LSP completions (highest priority)
                    { name = "luasnip" },  -- Snippets
                    { name = "path" },     -- Filesystem paths
                }, {
                    -- Lower priority source group
                    { name = "buffer", keyword_length = 3 }, -- Buffer text (needs 3+ chars)
                }),
                -- Format completion items
                formatting = {
                    format = function(entry, vim_item)
                        -- Set custom icons based on icons module
                        local icons = LazyVim.config.icons.kinds
                        if icons[vim_item.kind] then
                            vim_item.kind = icons[vim_item.kind] .. vim_item.kind
                        end

                        -- Set source indication
                        vim_item.menu = ({
                            nvim_lsp = "[LSP]",
                            luasnip = "[Snip]",
                            buffer = "[Buf]",
                            path = "[Path]",
                        })[entry.source.name]
                        
                        return vim_item
                    end,
                },
                -- Experimental features
                experimental = {
                    ghost_text = {
                        hl_group = "LspCodeLens", -- Highlight group for ghost text
                    },
                },
                -- Use default sorting (by score)
                sorting = defaults.sorting,
            }
        end,
    },

    -----------------------------------------------------------------------------------
    -- COMPLETION SOURCES
    -----------------------------------------------------------------------------------
    -- Register additional sources with lazy-loading

    -- LSP source
    {
        "hrsh7th/cmp-nvim-lsp",
        event = "InsertEnter"
    },
    -- Buffer source
    {
        "hrsh7th/cmp-buffer",
        event = "InsertEnter"
    },
    -- Path source
    {
        "hrsh7th/cmp-path",
        event = "InsertEnter"
    },
    -- Snippet source
    {
        "saadparwaiz1/cmp_luasnip",
        event = "InsertEnter"
    },
}
