return {

    -- add any tools you want to have installed below
    {
        "williamboman/mason.nvim",
        opts = {
            ensure_installed = {
                "shellcheck",
                "flake8",
                -- Modern LSP servers
                -- "rust-analyzer", -- Rust
                "pyright", -- Python
                "ruff-lsp", -- Python (modern linter + formatter)
                "typescript-language-server", -- TypeScript/JavaScript
                "lua-language-server", -- Lua
                "gopls", -- Go
                -- "ruby-lsp", -- Ruby
                -- "tailwindcss-language-server", -- Tailwind CSS
                "ast-grep", -- Universal AST tool
                "json-lsp", -- JSON
                -- "dockerfile-language-server", -- Dockerfile
                "yaml-language-server", -- YAML
                --
                -- -- Modern formatters
                "prettier", -- Web technologies
                -- "black", -- Python
                -- "stylua", -- Lua
                -- "gofumpt", -- Go
                -- "rubyfmt", -- Ruby
                -- "nixpkgs-fmt", -- Nix
                -- "shfmt", -- Shell
                --
                -- -- Modern linters
                "eslint_d", -- JavaScript/TypeScript (fast daemon)
                "ruff", -- Python (ultra-fast)
                "selene", -- Lua
                -- "hadolint", -- Dockerfile
                -- "actionlint", -- GitHub Actions
                "markdownlint", -- Markdown
                --
                -- -- Debug adapters
                -- "codelldb", -- Rust/C/C++
                "debugpy", -- Python
                "js-debug-adapter", -- JavaScript/TypeScript
                -- "delve", -- Go
            },
        },
    },
    -- add any tools you want to have installed below
    { "williamboman/mason-lspconfig.nvim", config = function() end },
}

-- return {
--     -- Mason with modern tools and lazy loading
--     "williamboman/mason.nvim",
--     -- cmd = "Mason",
--     -- keys = { { "<leader>cm", "<cmd>Mason<cr>", desc = "Mason" } },
--     -- build = ":MasonUpdate",
--     opts = {
--         ensure_installed = {
--             -- Modern LSP servers
--             -- "rust-analyzer", -- Rust
--             "pyright", -- Python
--             "ruff-lsp", -- Python (modern linter + formatter)
--             "typescript-language-server", -- TypeScript/JavaScript
--             "lua-language-server", -- Lua
--             "gopls", -- Go
--             -- "ruby-lsp", -- Ruby
--             -- "tailwindcss-language-server", -- Tailwind CSS
--             "ast-grep", -- Universal AST tool
--             "json-lsp", -- JSON
--             -- "dockerfile-language-server", -- Dockerfile
--             "yaml-language-server", -- YAML
--             --
--             -- -- Modern formatters
--             "prettier", -- Web technologies
--             -- "black", -- Python
--             -- "stylua", -- Lua
--             -- "gofumpt", -- Go
--             -- "rubyfmt", -- Ruby
--             -- "nixpkgs-fmt", -- Nix
--             "shfmt", -- Shell
--             --
--             -- -- Modern linters
--             "eslint_d", -- JavaScript/TypeScript (fast daemon)
--             "ruff", -- Python (ultra-fast)
--             "selene", -- Lua
--             -- "hadolint", -- Dockerfile
--             -- "actionlint", -- GitHub Actions
--             "markdownlint", -- Markdown
--             --
--             -- -- Debug adapters
--             -- "codelldb", -- Rust/C/C++
--             "debugpy", -- Python
--             "js-debug-adapter", -- JavaScript/TypeScript
--             -- "delve", -- Go
--         },
--         ui = {
--             border = "rounded",
--             icons = {
--                 package_installed = "✓",
--                 package_pending = "➜",
--                 package_uninstalled = "✗",
--             },
--         },
--         max_concurrent_installers = 4,
--     },
-- }
