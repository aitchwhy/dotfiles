-- lua/plugins/overrides.lua
return {
  { "echasnovski/mini.surround", opts = { mappings = { add = "gsa", delete = "gsd", replace = "gsr" } } },

  {
    "ggandor/leap.nvim",
    opts = function(_, opts)
      require("leap").add_default_mappings(false) -- disable
      vim.keymap.set({ "n", "x" }, "<leader>s", "<Plug>(leap-forward)")
    end,
  },
}
