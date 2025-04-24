-----------------------------------------------------------------------------------
-- TREESITTER CONFIGURATION - SYNTAX HIGHLIGHTING AND CODE NAVIGATION
-----------------------------------------------------------------------------------
return {
    -- Treesitter core configuration
    {
        "nvim-treesitter/nvim-treesitter",
        opts = {
            -- Enable highlighting
            highlight = { enable = true },

            -- Enable indentation support
            indent = { enable = true },

            -- Enable automatic tag closing and renaming for HTML/JSX/TSX
            autotag = { enable = true },

            -- Enable code folding based on treesitter
            fold = { enable = true },

            -- Language parsers to install
            ensure_installed = {
                "svelte",
                "dockerfile",
                "git_config",
                "gitcommit",
                "git_rebase",
                "gitignore",
                "gitattributes",

                "ninja",
                "rst",
                -- Web Development
                "html",
                "css",
                "javascript",
                "typescript",
                "tsx",
                "json",
                "jsonc",
                "json5",
                "yaml",
                "toml",
                "vue",
                "svelte",

                -- Programming Languages
                "python",
                "lua",
                "rust",
                "go",
                "c",
                "cpp",
                "java",
                "kotlin",
                "php",
                "ruby",

                -- Shell scripting
                "bash",
                "fish",
                "zsh",

                -- Query and Data
                "graphql",
                "sql",

                -- Markup and Docs
                "markdown",
                "markdown_inline",
                "regex",
                "comment",

                -- Configuration
                "dockerfile",
                "terraform",
                "hcl",
                "make",
                "cmake",
                "nix",
                "prisma",

                -- Version Control
                "git_config",
                "git_rebase",
                "gitattributes",
                "gitcommit",
                "gitignore",

                -- Build systems
                "ninja",

                -- Neovim specific
                "vim",
                "vimdoc",
                "query", -- For treesitter query debugging
            },
            incremental_selection = {
                enable = true,
                keymaps = {
                    init_selection = "<C-space>",
                    node_incremental = "<C-space>",
                    scope_incremental = false,
                    node_decremental = "<bs>",
                },
            },

            -- Treesitter text objects
            textobjects = {
                select = {
                    enable = true,
                    lookahead = true, -- Automatically jump forward to textobj
                    keymaps = {
                        -- Smart selection of various code objects
                        ["af"] = "@function.outer",
                        ["if"] = "@function.inner",
                        ["ac"] = "@class.outer",
                        ["ic"] = "@class.inner",
                        ["aa"] = "@parameter.outer",
                        ["ia"] = "@parameter.inner",
                        ["ai"] = "@conditional.outer",
                        ["ii"] = "@conditional.inner",
                        ["al"] = "@loop.outer",
                        ["il"] = "@loop.inner",
                        ["ab"] = "@block.outer",
                        ["ib"] = "@block.inner",
                        ["is"] = "@statement.inner",
                        ["as"] = "@statement.outer",
                        ["aC"] = "@comment.outer",
                        ["iC"] = "@comment.inner",
                    },
                },

                -- Move between text objects
                move = {
                    enable = true,
                    set_jumps = true, -- Track in jump list
                    goto_next_start = {
                        ["]f"] = "@function.outer",
                        ["]c"] = "@class.outer",
                        ["]i"] = "@conditional.outer",
                        ["]l"] = "@loop.outer",
                        ["]s"] = "@statement.outer",
                    },
                    goto_next_end = {
                        ["]F"] = "@function.outer",
                        ["]C"] = "@class.outer",
                        ["]I"] = "@conditional.outer",
                        ["]L"] = "@loop.outer",
                    },
                    goto_previous_start = {
                        ["[f"] = "@function.outer",
                        ["[c"] = "@class.outer",
                        ["[i"] = "@conditional.outer",
                        ["[l"] = "@loop.outer",
                        ["[s"] = "@statement.outer",
                    },
                    goto_previous_end = {
                        ["[F"] = "@function.outer",
                        ["[C"] = "@class.outer",
                        ["[I"] = "@conditional.outer",
                        ["[L"] = "@loop.outer",
                    },
                },

                -- Tree-sitter aware code swapping
                swap = {
                    enable = true,
                    swap_next = {
                        ["<leader>sn"] = "@parameter.inner",
                        ["<leader>sf"] = "@function.outer",
                    },
                    swap_previous = {
                        ["<leader>sp"] = "@parameter.inner",
                        ["<leader>sF"] = "@function.outer",
                    },
                },
            },
        },

        -- Configure Treesitter-based code navigation modules
        dependencies = {
            -- Treesitter text objects for smart navigation
            {
                "nvim-treesitter/nvim-treesitter-textobjects",
            },

            -- Automatically close HTML/JSX tags
            {
                "windwp/nvim-ts-autotag",
                opts = {},
            },

            -- Show code context at the top of the window
            {
                "nvim-treesitter/nvim-treesitter-context",
                opts = {
                    enable = true,
                    max_lines = 3,
                    min_window_height = 15,
                    line_numbers = true,
                    multiline_threshold = 5,
                    trim_scope = "outer",
                    mode = "cursor",
                    separator = "─", -- Nice horizontal line
                },
            },
        },
    },
}
