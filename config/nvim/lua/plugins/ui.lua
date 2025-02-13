-- ui.lua: UI enhancements (theme, statusline, bufferline, etc.) and tools like Telescope and NvimTree
return {
  -- COLORSCHEME
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000, -- load immediately on startup&#8203;:contentReference[oaicite:55]{index=55}
    config = function()
      vim.cmd("colorscheme tokyonight-storm") -- set colorscheme (using "storm" variant here)
    end,
  },
  -- zenburn
  {
    "daler/zenburn.nvim",

    -- lazy.nvim recommends using these settings for colorschemes so they load
    -- quickly
    lazy = false,
    priority = 1000,
  },
  -- gruvbox is an example of an alternative colorscheme, here disabled
  {
    "morhetz/gruvbox",
    enabled = false,
    lazy = false,
    priority = 1000,
  },

  -- onedark is another colorscheme, here enabled as a fallback for terminals
  -- with no true-color support like the macOS Terminal.app.
  {
    "joshdick/onedark.vim",
    lazy = false,
    priority = 1000,
  },

  -- STATUSLINE
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lualine").setup({
        options = { theme = "tokyonight", globalstatus = true },
        sections = {
          lualine_c = { { "filename", path = 1 } }, -- show relative path
          lualine_x = { { "diagnostics", sources = { "nvim_diagnostic" } }, "encoding", "filetype" },
        },
      })
    end,
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

  -- FUZZY FINDER
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    },
    config = function()
      require("telescope").setup({
        defaults = {
          prompt_prefix = "🔍 ",
          selection_caret = " ",
          path_display = { "smart" },
          file_ignore_patterns = { "node_modules", ".git/" },
        },
      })
      require("telescope").load_extension("fzf") -- enable fzf-native for faster search
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

  -- FUGITIVE (Git commands)
  { "tpope/vim-fugitive", cmd = { "Git", "Gdiffsplit", "Gblame", "Glog", "Gpush", "Gpull" } },

  -- DRESSING (improved vim.ui)
  { "stevearc/dressing.nvim", event = "VeryLazy", config = true },

  -- NOTIFY (better notifications)
  {
    "rcarriga/nvim-notify",
    event = "VeryLazy",
    config = function()
      vim.notify = require("notify")
    end,
  },
}
