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
    version = false,
    event = "VeryLazy",
    -- opts = function(_, opts)
    --   local ai = require("mini.ai")
    --   opts.custom_textobjects = {
    --     F = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }),
    --     T = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }),
    --   }
    -- end,
    opts = function()
      local ai = require("mini.ai")
      return {
        n_lines = 500,
        custom_textobjects = {
          o = ai.gen_spec.treesitter({ -- code block
            a = { "@block.outer", "@conditional.outer", "@loop.outer" },
            i = { "@block.inner", "@conditional.inner", "@loop.inner" },
          }),
          f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }), -- function
          c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }), -- class
          t = { "<([%p%w]-)%f[^<%w][^<>]->.-</%1>", "^<.->().*()</[^/]->$" }, -- tags
          d = { "%f[%d]%d+" }, -- digits
          e = { -- Word with case
            { "%u[%l%d]+%f[^%l%d]", "%f[%S][%l%d]+%f[^%l%d]", "%f[%P][%l%d]+%f[^%l%d]", "^[%l%d]+%f[^%l%d]" },
            "^().*()$",
          },
          g = LazyVim.mini.ai_buffer, -- buffer
          u = ai.gen_spec.function_call(), -- u for "Usage"
          U = ai.gen_spec.function_call({ name_pattern = "[%w_]" }), -- without dot in function name
        },
      }
    end
  },
}
-- {
--   "echasnovski/mini.ai",
--   version = false,  -- always latest
--   opts = function()
--     local ai = require("mini.ai")
--     return {
--       n_lines = 500,
--       custom_textobjects = {
--         o = ai.gen_spec.treesitter({ -- code block
--           a = { "@block.outer", "@conditional.outer", "@loop.outer" },
--           i = { "@block.inner", "@conditional.inner", "@loop.inner" },
--         }),
--         f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }), -- function
--         c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }), -- class
--         t = { "<([%p%w]-)%f[^<%w][^<>]->.-</%1>", "^<.->().*()</[^/]->$" }, -- tags
--         d = { "%f[%d]%d+" }, -- digits
--         e = { -- Word with case
--           { "%u[%l%d]+%f[^%l%d]", "%f[%S][%l%d]+%f[^%l%d]", "%f[%P][%l%d]+%f[^%l%d]", "^[%l%d]+%f[^%l%d]" },
--           "^().*()$",
--         },
--         g = LazyVim.mini.ai_buffer, -- buffer
--         u = ai.gen_spec.function_call(), -- u for "Usage"
--         U = ai.gen_spec.function_call({ name_pattern = "[%w_]" }), -- without dot in function name
--       },
--     }
--   end,
-- },
