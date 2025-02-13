-- ui.lua: UI enhancements (theme, statusline, bufferline, etc.) and tools like Telescope and NvimTree
return {

  -- lua/plugins/ui.lua
  -- Example UI plugins: colorscheme + file explorer

  -- COLORSCHEME
  {
    "folke/tokyonight.nvim",
    opts = {
      transparent = true,
      styles = {
        sidebars = "transparent",
        floats = "transparent",
      },
    },
  },

  {
    "nvim-lualine/lualine.nvim",
    dependencies = {
      "linrongbin16/lsp-progress.nvim",
    },
    opts = {
      options = { theme = "zenburn" },
      sections = {
        lualine_c = { { "filename", path = 2 } },
        -- use lsp-progress plugin to show LSP activity
        lualine_x = {
          function()
            return require("lsp-progress").progress()
          end,
        },
      },
    },
  },

  -- BUFFERLINE (tabs for buffers)
  {
    "akinsho/bufferline.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("bufferline").setup({
        options = {
          diagnostics = "nvim_lsp",
          separator_style = "slant",
          show_close_icon = false,
          show_buffer_close_icons = false,
        },
      })
    end,
  },

  -- INDENT BLANKLINE (indent guides)
  {
    "lukas-reineke/indent-blankline.nvim",
    event = "BufReadPost",
    config = function()
      require("indent_blankline").setup({
        show_current_context = true,
        show_trailing_blankline_indent = false,
      })
    end,
  },

  -- FILE EXPLORER
  {
    "nvim-tree/nvim-tree.lua",
    cmd = "NvimTreeToggle", -- load on executing the toggle command
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("nvim-tree").setup({
        renderer = {
          group_empty = true,
          icons = { show = { git = true, file = true, folder = true, folder_arrow = false } },
        },
        view = { width = 30, side = "left" },
        filters = { dotfiles = false },
        git = { ignore = false },
      })
    end,
  },

  -- GIT SIGNS
  {
    "lewis6991/gitsigns.nvim",
    event = "BufReadPre",
    config = function()
      require("gitsigns").setup({
        signs = {
          add = { text = "│" },
          change = { text = "│" },
          delete = { text = "_" },
          topdelete = { text = "‾" },
          changedelete = { text = "~" },
        },
        current_line_blame = true, -- Toggle with :Gitsigns toggle_current_line_blame
      })
    end,
  },
}
