-- Mason configuration for LazyVim 15.x
-- Excludes tools that are installed via Nix
return {
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        -- Debug adapters (DAP)
        "js-debug-adapter", -- TypeScript/JavaScript debugging
        "debugpy",          -- Python debugging
        "delve",            -- Go debugging
        -- Note: codelldb for Rust is installed via rust extra

        -- Formatters & Linters
        "biome",            -- JS/TS/JSON formatting + linting

        -- Additional linters
        "markdownlint",     -- Markdown linting
        "yamllint",         -- YAML linting
        "hadolint",         -- Dockerfile linting
        "sqlfluff",         -- SQL linting
      },
    },
  },
  {
    "mason-org/mason-lspconfig.nvim",
    opts = {
      automatic_installation = {
        exclude = { "nil_ls" }, -- Use nixd from Nix instead
      },
    },
  },
}
