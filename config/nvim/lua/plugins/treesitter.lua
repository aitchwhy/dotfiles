-- add more treesitter parsers
return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "bash",
        "html",
        "javascript",
        "json",
        "lua",
        "markdown",
        "markdown_inline",
        "python",
        "query",
        "regex",
        "tsx",
        "typescript",
        "vim",
        "yaml",
        "rust",
      },
      highlight = {
        enable = true,
      },
      indent = {
        enable = true,
      },
      incremental_selection = {
        enable = true,
      },
      textobjects = {
        enable = true,

        -- select = {
        --   enable = true,
        --   lookahead = true,
        --   keymaps = {
        --     ["af"] = "@function.outer",
        --     ["if"] = "@function.inner",
        --     ["ac"] = "@class.outer",
        --     ["ic"] = "@class.inner",
        --   },
        -- },
        -- swap = {
        --   enable = true,
        --   swap_next = {
        --     ["<leader>a"] = "@parameter.inner",
        --   },
        --   swap_previous = {
        --     ["<leader>A"] = "@parameter.inner",
        --   },
        -- },
        -- move = {
        --   enable = true,
        --   set_jumps = true,
        --   goto_next_start = {
        --     ["]m"] = "@function.outer",
        --     ["]]"] = "@class.outer",
        --   },
        --   goto_next_end = {
        --     ["]M"] = "@function.outer",
        --     ["]["] = "@class.outer",
        --   },
        --   goto_previous_start = {
        --     ["[m"] = "@function.outer",
        --     ["[["] = "@class.outer",
        --   },
        --   goto_previous_end = {
        --     ["[M"] = "@function.outer",
        --     ["[]"] = "@class.outer",
        --   },
        -- },
      },
    },
  },
}
