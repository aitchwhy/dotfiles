-- Mason configuration for LazyVim 15.x
-- Only debug adapters - all linters/formatters are installed via Nix
return {
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        -- Debug adapters only (IDE-specific, complex binaries)
        "js-debug-adapter", -- TypeScript/JavaScript debugging
        "debugpy", -- Python debugging
        "delve", -- Go debugging
        -- Note: codelldb for Rust is installed via rust extra
      },
    },
  },
  {
    "mason-org/mason-lspconfig.nvim",
    opts = {
      automatic_installation = {
        exclude = { "nil_ls", "nixd" }, -- Nix LSPs from Nix packages
      },
    },
  },
}
