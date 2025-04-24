-----------------------------------------------------------------------------------
-- BLINK.CMP - MODERN COMPLETION SYSTEM
-----------------------------------------------------------------------------------
-- A modern, sleek completion system that replaces nvim-cmp
-- Benefits over nvim-cmp:
-- * Better UI with more customization options
-- * Improved performance and responsiveness
-- * Better integration with LSP and snippets
-- * Supports both built-in and compatible sources
return {
    {
        "saghen/blink.cmp",
        -- Load dependencies required for completion
        dependencies = {
            -- Snippet collection
            "rafamadriz/friendly-snippets",
            -- Compatibility layer for nvim-cmp sources
            {
                "saghen/blink.compat",
                optional = true, -- Only enabled if extras need it
                opts = {},
            },
        },
        -- Only load when entering insert mode
        event = "InsertEnter",

        ---@type blink.cmp.Config
        opts = {
            -- Configure snippet expansion
            snippets = {
                expand = function(snippet, _)
                    return require("lazyvim.util").cmp.expand(snippet)
                end,
            },
            -- UI appearance settings
            appearance = {
                -- Sets fallback highlight groups to nvim-cmp's highlight groups
                -- Useful when your theme doesn't support blink.cmp yet
                use_nvim_cmp_as_default = false,
                -- 'mono' for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
                -- Adjusts spacing to ensure icons are aligned properly
                nerd_font_variant = "mono",
            },
            -- Completion behavior configuration
            completion = {
                -- Auto-brackets support (experimental)
                accept = {
                    auto_brackets = {
                        enabled = true,
                    },
                },
                -- Menu drawing configuration
                menu = {
                    draw = {
                        treesitter = { "lsp" },
                    },
                },
                -- Documentation window settings
                documentation = {
                    auto_show = true,
                    auto_show_delay_ms = 200,
                },
                -- Ghost text (inline completion preview)
                ghost_text = {
                    enabled = vim.g.ai_cmp, -- Enable if AI completion is available
                },
            },

            -- Experimental signature help support (commented out)
            -- signature = { enabled = true },

            -- Configure completion sources
            sources = {
                -- Compatible sources via blink.compat
                compat = {},
                -- Default sources to always enable
                default = { "lsp", "path", "snippets", "buffer" },
            },

            -- Command line completion (disabled)
            cmdline = {
                enabled = false,
            },

            -- Keybinding configuration
            keymap = {
                preset = "enter", -- Use enter to confirm completion
                ["<C-y>"] = { "select_and_accept" },
            },
        },
        -- Setup function runs after plugin loads
        config = function(_, opts)
            local LazyVim = require("lazyvim.util")
            ------------------
            -- SETUP SOURCES
            ------------------

            -- Configure compatibility sources
            local enabled = opts.sources.default
            for _, source in ipairs(opts.sources.compat or {}) do
                opts.sources.providers[source] = vim.tbl_deep_extend(
                    "force",
                    { source, module = "blink.compat.source" },
                    opts.sources.providers[source] or {}
                )
                if type(enabled) == "table" and not vim.tbl_contains(enabled, source) then
                    table.insert(enabled, source)
                end
            end

            ------------------
            -- SETUP KEYMAPS
            ------------------

            -- Add ai_accept to Tab key if not already configured
            if not opts.keymap["<Tab>"] then
                if opts.keymap.preset == "super-tab" then -- super-tab preset
                    opts.keymap["<Tab>"] = {
                        require("blink.cmp.keymap.presets")["super-tab"]["<Tab>"][1],
                        LazyVim.cmp.map({ "snippet_forward", "ai_accept" }),
                        "fallback",
                    }
                else -- other presets
                    opts.keymap["<Tab>"] = {
                        LazyVim.cmp.map({ "snippet_forward", "ai_accept" }),
                        "fallback",
                    }
                end
            end

            -- Remove compatibility settings to pass validation
            opts.sources.compat = nil

            ------------------
            -- SETUP SYMBOLS
            ------------------

            -- Override symbol kinds with custom icons if needed
            for _, provider in pairs(opts.sources.providers or {}) do
                ---@cast provider blink.cmp.SourceProviderConfig|{kind?:string}
                if provider.kind then
                    local CompletionItemKind = require("blink.cmp.types").CompletionItemKind
                    local kind_idx = #CompletionItemKind + 1

                    CompletionItemKind[kind_idx] = provider.kind
                    ---@diagnostic disable-next-line: no-unknown
                    CompletionItemKind[provider.kind] = kind_idx

                    ---@type fun(ctx: blink.cmp.Context, items: blink.cmp.CompletionItem[]): blink.cmp.CompletionItem[]
                    local transform_items = provider.transform_items
                    ---@param ctx blink.cmp.Context
                    ---@param items blink.cmp.CompletionItem[]
                    provider.transform_items = function(ctx, items)
                        items = transform_items and transform_items(ctx, items) or items
                        for _, item in ipairs(items) do
                            item.kind = kind_idx or item.kind
                            -- Apply LazyVim icons for consistency
                            item.kind_icon = LazyVim.config.icons.kinds[item.kind_name] or item.kind_icon or nil
                        end
                        return items
                    end

                    -- Remove custom prop to pass validation
                    provider.kind = nil
                end
            end

            -- Initialize blink.cmp with our options
            require("blink.cmp").setup(opts)
        end,
    },
}
