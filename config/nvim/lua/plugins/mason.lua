-- Mason configuration for LazyVim 15.x
-- Excludes tools that are installed via Nix
return {
  {
    "mason-org/mason-lspconfig.nvim",
    opts = {
      automatic_installation = {
        exclude = { "nil_ls" }, -- Use nixd from Nix instead
      },
    },
  },
}
