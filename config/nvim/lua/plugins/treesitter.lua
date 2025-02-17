return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      -- append to the ensure_installed list
      vim.list_extend(opts.ensure_installed, { "go", "ruby", "rust" })
    end,
  }
}

