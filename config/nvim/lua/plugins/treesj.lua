-- TreeSJ - Split/join code blocks
return {
  {
    "Wansmer/treesj",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    keys = {
      { "<leader>j", "<cmd>TSJToggle<cr>", desc = "Toggle split/join" },
    },
    opts = {
      use_default_keymaps = false,
      max_join_length = 120,
    },
  },
}
