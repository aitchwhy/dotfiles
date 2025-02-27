-----------------------------------------------------------------------------------
-- MASON CONFIGURATION - PACKAGE MANAGER FOR LSP, DAP, LINTERS, FORMATTERS
-----------------------------------------------------------------------------------

return {
  -- Mason core configuration
  {
    "williamboman/mason.nvim",
    opts = {
      -- Configure the UI
      ui = {
        border = "rounded",
        icons = {
          package_installed = "✓",
          package_pending = "➜",
          package_uninstalled = "✗",
        },
        width = 0.8,
        height = 0.8,
      },
      
      -- Automatically install these tools
      ensure_installed = {
        -- LSP (Language Servers)
        -----------------------------
        -- Web Development
        "typescript-language-server", -- TypeScript/JavaScript
        "eslint-lsp",                 -- ESLint with LSP capabilities
        "tailwindcss-language-server", -- Tailwind CSS
        "css-lsp",                    -- CSS
        "html-lsp",                   -- HTML
        "json-lsp",                   -- JSON
        "emmet-ls",                   -- Emmet
        
        -- Backend/Systems Programming
        "pyright",                    -- Python type checking
        "ruff-lsp",                   -- Fast Python linting
        "gopls",                      -- Go
        "rust-analyzer",              -- Rust
        "lua-language-server",        -- Lua
        "clangd",                     -- C/C++
        
        -- DevOps/Configuration
        "yaml-language-server",       -- YAML
        "dockerfile-language-server", -- Dockerfile
        "terraform-ls",               -- Terraform
        "marksman",                   -- Markdown
        "taplo",                      -- TOML
        
        -- Formatters
        -----------------------------
        "prettier",                   -- Web technologies
        "black",                      -- Python
        "stylua",                     -- Lua
        "shfmt",                      -- Shell
        "gofumpt",                    -- Go
        "rustfmt",                    -- Rust
        "markdownlint",               -- Markdown
        "biome",                      -- Fast JS/TS formatter (modern alternative)
        
        -- Linters
        -----------------------------
        "eslint_d",                   -- JavaScript/TypeScript (fast daemon)
        "ruff",                       -- Python (ultra-fast)
        "selene",                     -- Lua
        "hadolint",                   -- Dockerfile
        "actionlint",                 -- GitHub Actions
        "shellcheck",                 -- Shell
        "flake8",                     -- Python (traditional)
        "vale",                       -- Prose/documentation linter
        
        -- DAP (Debug Adapters)
        -----------------------------
        "debugpy",                    -- Python
        "js-debug-adapter",           -- JavaScript/TypeScript
        "delve",                      -- Go
        "codelldb",                   -- Rust/C/C++
        
        -- Tools
        -----------------------------
        "ast-grep",                   -- Universal AST tool for code search
      },
      
      -- Limit concurrent installations
      max_concurrent_installers = 4,
    },
    config = function(_, opts)
      require("mason").setup(opts)
      
      -- Create a command to install all configured tools
      vim.api.nvim_create_user_command("MasonInstallAll", function()
        vim.cmd("MasonInstall " .. table.concat(opts.ensure_installed, " "))
      end, {})
      
      -- Create a command to update all installed tools
      vim.api.nvim_create_user_command("MasonUpdateAll", function()
        vim.cmd("MasonUpdate")
      end, {})
    end,
  },
  
  -- Ensure mason-lspconfig is properly initialized but don't override LazyVim's setup
  { "williamboman/mason-lspconfig.nvim", config = function() end },
}
