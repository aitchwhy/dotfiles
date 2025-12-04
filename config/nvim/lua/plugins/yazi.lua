-- Yazi file manager integration for LazyVim
return {
  {
    "mikavilpas/yazi.nvim",
    event = "VeryLazy",
    dependencies = {
      "folke/snacks.nvim",
    },
    opts = {
      open_for_directories = true,
      use_as_default_explorer = false, -- neo-tree is default in LazyVim

      keymaps = {
        show_help = "<F1>",
        back = "<Esc>",
        quit = "q",
        edit_split = "<C-s>",
        edit_vsplit = "<C-v>",
        edit_tab = "<C-t>",
        go_home = "~",
        go_parent = "..",
        copy_path = "yp",
        copy_name = "yn",
      },
    },
  },
}
