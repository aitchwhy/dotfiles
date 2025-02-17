return {
  -- Mason with modern tools and lazy loading
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        -- Modern formatters
        "stylua",     -- Lua
        "shfmt",      -- Shell
        "shellcheck", -- Shell
        "prettier",   -- Web technologies
        -- "nixpkgs-fmt", -- Nix

        -- Modern LSP servers
        "rust-analyzer",               -- Rust
        "pyright",                     -- Python
        "ruff-lsp",                    -- Python (modern linter + formatter)
        "typescript-language-server",  -- TypeScript/JavaScript
        "lua-language-server",         -- Lua
        "gopls",                       -- Go
        "ruby-lsp",                    -- Ruby
        "tailwindcss-language-server", -- Tailwind CSS
        "ast-grep",                    -- Universal AST tool
        "json-lsp",                    -- JSON
        "dockerfile-language-server",  -- Dockerfile
        "yaml-language-server",        -- YAML

        -- Modern linters
        "eslint_d",     -- JavaScript/TypeScript (fast daemon)
        "ruff",         -- Python (ultra-fast)
        "selene",       -- Lua
        "hadolint",     -- Dockerfile
        "actionlint",   -- GitHub Actions
        "markdownlint", -- Markdown

        -- Debug adapters
        "codelldb",         -- Rust/C/C++
        "debugpy",          -- Python
        "js-debug-adapter", -- JavaScript/TypeScript
        "delve",            -- Go
      },
      ui = {
        border = "rounded",
        icons = {
          package_installed = "✓",
          package_pending = "➜",
          package_uninstalled = "✗",
        },
      },
      max_concurrent_installers = 4,
    },
  },
}
