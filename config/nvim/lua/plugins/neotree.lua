return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    lazy = false, -- neo-tree will lazily load itself
    ---@module "neo-tree"
    ---@type neotree.Config?
    opts = {
      -- fill any relevant options here
      bind_to_cwd = true,
      follow_current_file = { enabled = true },
    },
  },
}
