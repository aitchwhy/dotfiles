return {
  -- AUTOPAIRS: auto-close brackets, integrate with cmp
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      require("nvim-autopairs").setup({})
      -- If using nvim-cmp, integrate autopairs into completion confirmations:
      local cmp_ok, cmp = pcall(require, "cmp")
      if cmp_ok then
        require("nvim-autopairs.completion.cmp").setup({ map_cr = true })
      end
    end,
  },

}
