-----------------------------------------------------------------------------------
-- MINI.AI - ENHANCED TEXT OBJECTS
-----------------------------------------------------------------------------------
-- Adds enhanced text object functionality for better code manipulation
-- Documentation: https://github.com/echasnovski/mini.ai
-- Features:
-- * Rich set of text objects for common programming constructs
-- * Treesitter integration for language-aware text objects
-- * Supports next/previous text object selection
-- * Buffer text objects and custom text objects
return {
    {
        "echasnovski/mini.ai",
        event = "VeryLazy", -- Load when needed, not on startup
        dependencies = { "nvim-treesitter/nvim-treesitter-textobjects" },
        opts = function()
            local LazyVim = require("lazyvim.util")
            local ai = require("mini.ai")
            
            return {
                n_lines = 500, -- Number of lines to search for text objects

                -----------------------------------------------------------------------------------
                -- CUSTOM TEXT OBJECTS
                -----------------------------------------------------------------------------------
                custom_textobjects = {
                    -- Code blocks (conditionals, loops)
                    o = ai.gen_spec.treesitter({
                        a = { "@block.outer", "@conditional.outer", "@loop.outer" },
                        i = { "@block.inner", "@conditional.inner", "@loop.inner" },
                    }, {}),
                    -- Functions
                    f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }, {}),
                    -- Classes
                    c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }, {}),
                    -- HTML/XML tags
                    t = { "<([%p%w]-)%f[^<%w][^<>]->.-</%1>", "^<.->().*()</[^/]->$" },
                    -- Digits/numbers
                    d = { "%f[%d]%d+" },

                    -- Word with case
                    e = {
                        {
                            "%u[%l%d]+%f[^%l%d]",
                            "%f[%S][%l%d]+%f[^%l%d]",
                            "%f[%P][%l%d]+%f[^%l%d]",
                            "^[%l%d]+%f[^%l%d]",
                        },
                        "^().*()$",
                    },
                    -- Buffer text object
                    g = LazyVim.mini.ai_buffer,

                    -- Function call
                    u = ai.gen_spec.function_call(),

                    -- Function call without dot
                    U = ai.gen_spec.function_call({ name_pattern = "[%w_]" }),
                },
                -----------------------------------------------------------------------------------
                -- KEY MAPPINGS
                -----------------------------------------------------------------------------------
                mappings = {
                    -- Standard text object mappings
                    around = "a",
                    inside = "i",
                    -- Next/previous text object
                    around_next = "an",
                    inside_next = "in",
                    around_last = "al",
                    inside_last = "il",
                    -- Move cursor to edges of text object
                    goto_left = "g[",
                    goto_right = "g]",
                    -- Buffer level text objects
                    g = LazyVim.mini.ai_buffer,
                },
            }
        end,
        config = function(_, opts)
            -- Setup mini.ai with the options
            require("mini.ai").setup(opts)

            -----------------------------------------------------------------------------------
            -- WHICH-KEY INTEGRATION
            -----------------------------------------------------------------------------------
            -- Register text objects with which-key for better discoverability
            local LazyVim = require("lazyvim.util")
            if LazyVim.has("which-key.nvim") then
                ---@type table<string, string|table>
                local i = {
                    [" "] = "Whitespace",
                    ['"'] = 'Balanced "',
                    ["'"] = "Balanced '",
                    ["`"] = "Balanced `",
                    ["("] = "Balanced (",
                    [")"] = "Balanced ) including white-space",
                    [">"] = "Balanced > including white-space",
                    ["<lt>"] = "Balanced <",
                    ["]"] = "Balanced ] including white-space",
                    ["["] = "Balanced [",
                    ["}"] = "Balanced } including white-space",
                    ["{"] = "Balanced {",
                    ["?"] = "User Prompt",
                    _ = "Underscore",
                    a = "Argument",
                    b = "Balanced ), ], }",
                    c = "Class",
                    f = "Function",
                    o = "Block, conditional, loop",
                    q = "Quote `, \", '",
                    t = "Tag",
                    g = "Buffer",
                }
                -- Create the "around" version by removing the "including white-space" text
                local a = vim.deepcopy(i)
                for k, v in pairs(a) do
                    a[k] = v:gsub(" including.*", "")
                end

                -- Create next/previous submenus by combining with inside/around
                local ic = vim.deepcopy(i)
                local ac = vim.deepcopy(a)
                for key, name in pairs({ n = "Next", l = "Last" }) do
                    i[key] = vim.tbl_extend("force", { name = "Inside " .. name .. " textobject" }, ic)
                    a[key] = vim.tbl_extend("force", { name = "Around " .. name .. " textobject" }, ac)
                end

                -- Register with which-key for visual and operator pending modes
                require("which-key").register({
                    mode = { "o", "x" },
                    i = i,
                    a = a,
                })
            end
        end,
    },
}
