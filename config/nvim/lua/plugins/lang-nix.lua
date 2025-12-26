-- Override LazyVim nix extra to use nixd instead of nil_ls
-- nil_ls is LazyVim's default but we use nixd from Nix packages
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        nil_ls = false, -- Disable nil_ls (LazyVim default)
        nixd = {}, -- Use nixd from Nix instead
      },
    },
  },
}
