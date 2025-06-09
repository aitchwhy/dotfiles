return {
  -- Mason core (UI and package management)
  {
    "williamboman/mason.nvim",
    version = "2.*",
    -- build = ":MasonUpdate",
    opts = {
      ui = {
        icons = {
          package_installed = "✓",
          package_pending = "➜",
          package_uninstalled = "✗",
        },
      },
      -- Mason itself doesn't have ensure_installed
    },
  },

  -- Bridge for LSP servers only
  {
    "williamboman/mason-lspconfig.nvim",
    version = "2.*",
    dependencies = {
      "williamboman/mason.nvim",
      "neovim/nvim-lspconfig",
    },
    opts = {
      ensure_installed = {
        -- LSP servers only
        "ts_ls", -- TypeScript/JavaScript (formerly tsserver)
        "eslint", -- ESLint LSP
        "tailwindcss", -- Tailwind CSS
        "cssls", -- CSS
        "html", -- HTML
        "jsonls", -- JSON
        "emmet_ls", -- Emmet
        "pyright", -- Python
        "ruff_lsp", -- Ruff LSP
        "gopls", -- Go
        "rust_analyzer", -- Rust
        "lua_ls", -- Lua
        "clangd", -- C/C++
        "yamlls", -- YAML
        "dockerls", -- Dockerfile
        "terraformls", -- Terraform
        "marksman", -- Markdown
        "taplo", -- TOML
      },
      automatic_installation = true,
    },
  },
}
