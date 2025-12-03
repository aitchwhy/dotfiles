--------------------------------------------------------------------------------
-- TREESITTER CONFIGURATION – SYNTAX HIGHLIGHT & NAVIGATION
--------------------------------------------------------------------------------
return {
  ------------------------------------------------------------------------------
  -- 1. Core Treesitter plugin
  ------------------------------------------------------------------------------
  {
    "nvim-treesitter/nvim-treesitter",
    -- -- build = ":TSUpdate",
    -- -- event = { "BufReadPost", "BufNewFile" },
    --
    version = false,
    build = ":TSUpdate",
    ---@type TSConfig
    ---@diagnostic disable-next-line: missing-fields
    opts = {
      --------------------------------------------------------------------------
      -- Language parsers ------------------------------------------------------
      --------------------------------------------------------------------------
      highlight = { enable = true },
      indent = { enable = true },
      ensure_installed = {
        "bash",
        "c",
        "diff",
        "html",
        "javascript",
        "jsdoc",
        "json",
        "jsonc",
        "lua",
        "luadoc",
        "luap",
        "markdown",
        "markdown_inline",
        "printf",
        "python",
        "query",
        "regex",
        "toml",
        "tsx",
        "typescript",
        "vim",
        "vimdoc",
        "xml",
        "yaml",

        -- "bash",
        -- "comment",
        -- "dockerfile",
        -- "git_config",
        -- "git_rebase",
        -- "gitattributes",
        -- "gitcommit",
        -- "gitignore",
        -- "go",
        -- "hcl",
        -- "html",
        -- "javascript",
        -- "jsdoc",
        -- "json",
        -- "jsonc",
        -- "luadoc",
        -- "luap",
        "markdown",
        -- "markdown_inline",
        -- "printf",
        -- "python",
        -- "query",
        -- "regex",
        "ruby",
        -- "rust",
        -- "sql",
        -- "svelte",
        -- "terraform",
        "toml",
        "tsx",
        "typescript",
        -- "vim",
        -- "vimdoc",
        "xml",
        "yaml",
      },

      ---  --------------------------------------------------------------------------
      ---  -- Text-objects, motions, swaps -----------------------------------------
      ---  --------------------------------------------------------------------------
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<C-space>",
          node_incremental = "<C-space>",
          scope_incremental = false,
          node_decremental = "<bs>",
        },
      },
      textobjects = {
        move = {
          enable = true,
          goto_next_start = { ["]f"] = "@function.outer", ["]c"] = "@class.outer", ["]a"] = "@parameter.inner" },
          goto_next_end = { ["]F"] = "@function.outer", ["]C"] = "@class.outer", ["]A"] = "@parameter.inner" },
          goto_previous_start = { ["[f"] = "@function.outer", ["[c"] = "@class.outer", ["[a"] = "@parameter.inner" },
          goto_previous_end = { ["[F"] = "@function.outer", ["[C"] = "@class.outer", ["[A"] = "@parameter.inner" },
        },
      },
      ---  textobjects = {
      ---
      ---    -- ➊ selection
      ---    select = {
      ---      enable = true,
      ---      lookahead = true,
      ---      keymaps = {
      ---        ["af"] = "@function.outer",
      ---        ["if"] = "@function.inner",
      ---        ["ac"] = "@class.outer",
      ---        ["ic"] = "@class.inner",
      ---        ["aa"] = "@parameter.outer",
      ---        ["ia"] = "@parameter.inner",
      ---        ["ai"] = "@conditional.outer",
      ---        ["ii"] = "@conditional.inner",
      ---        ["al"] = "@loop.outer",
      ---        ["il"] = "@loop.inner",
      ---        ["ab"] = "@block.outer",
      ---        ["ib"] = "@block.inner",
      ---        ["as"] = "@statement.outer",
      ---        ["is"] = "@statement.inner",
      ---        ["aC"] = "@comment.outer",
      ---        ["iC"] = "@comment.inner",
      ---      },
      ---    },
      ---
      ---    -- ➋ movement
      ---    move = {
      ---      enable = true,
      ---      set_jumps = true,
      ---      goto_next_start = {
      ---        ["]f"] = "@function.outer",
      ---        ["]c"] = "@class.outer",
      ---        ["]i"] = "@conditional.outer",
      ---        ["]l"] = "@loop.outer",
      ---        ["]s"] = "@statement.outer",
      ---      },
      ---      goto_next_end = {
      ---        ["]F"] = "@function.outer",
      ---        ["]C"] = "@class.outer",
      ---        ["]I"] = "@conditional.outer",
      ---        ["]L"] = "@loop.outer",
      ---      },
      ---      goto_prev_start = {
      ---        ["[f"] = "@function.outer",
      ---        ["[c"] = "@class.outer",
      ---        ["[i"] = "@conditional.outer",
      ---        ["[l"] = "@loop.outer",
      ---        ["[s"] = "@statement.outer",
      ---      },
      ---      goto_prev_end = {
      ---        ["[F"] = "@function.outer",
      ---        ["[C"] = "@class.outer",
      ---        ["[I"] = "@conditional.outer",
      ---        ["[L"] = "@loop.outer",
      ---      },
      ---    },
      ---
      ---    -- ➌ swapping
      ---    swap = {
      ---      enable = true,
      ---      swap_next = {
      ---        ["<leader>sn"] = "@parameter.inner",
      ---        ["<leader>sf"] = "@function.outer",
      ---      },
      ---      swap_previous = {
      ---        ["<leader>sp"] = "@parameter.inner",
      ---        ["<leader>sF"] = "@function.outer",
      ---      },
      ---    },
      ---  },
      ---},
      -----------------------------------------------------------------------------
      ----- Extra modules driven by Treesitter
      -----------------------------------------------------------------------------
      ---dependencies = {
      ---  "nvim-treesitter/nvim-treesitter-textobjects",
      ---
      ---  -- auto-tagging for html/react
      ---  { "windwp/nvim-ts-autotag", opts = {} },
      ---
      ---  -- sticky context window at top
      ---  {
      ---    "nvim-treesitter/nvim-treesitter-context",
      ---    opts = {
      ---      enabled = true,
      ---      max_lines = 3,
      ---      min_window_height = 15,
      ---      line_numbers = true,
      ---      multiline_threshold = 5,
      ---      trim_scope = "outer",
      ---      mode = "cursor",
      ---      separator = "─",
      ---    },
      ---  },
    },
  },

  {
    "nvim-treesitter/nvim-treesitter-context",
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
      },
    },
  },

  {
    "JoosepAlviste/nvim-ts-context-commentstring",
    opts = {},
  },
}
