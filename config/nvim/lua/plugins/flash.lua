return {
  -- flash.nvim (Flash enhances the built-in search functionality by showing labels at the end of each match, letting you quickly jump to a specific location.)
  {
    "folke/flash.nvim",
    keys = {
      -- disable the default flash keymap
      { "s", mode = { "n", "x", "o" }, false },
    },
  },
}
