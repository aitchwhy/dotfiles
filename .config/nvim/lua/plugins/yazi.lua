return {
  {
    "mikavilpas/yazi.nvim",
    event = "VeryLazy",
    dependencies = {
      -- "nvim-lua/plenary.nvim",
      -- "nvim-tree/nvim-web-devicons",
      -- check the installation instructions at
      -- https://github.com/folke/snacks.nvim
      "folke/snacks.nvim",
    },
    -- keys = {
    --   -- Main keybindings
    --   {
    --     "<leader>-",
    --     mode = { "n", "v" },
    --     "<cmd>Yazi<cr>",
    --     desc = "Open yazi at the current file",
    --   },
    --   {
    --     "<leader>fw",
    --     "<cmd>Yazi cwd<cr>",
    --     desc = "Browse files in current working directory",
    --   },
    --   {
    --     "<leader>fh",
    --     "<cmd>Yazi ~<cr>",
    --     desc = "Browse files in home directory",
    --   },
    --   {
    --     "<leader>fc",
    --     "<cmd>Yazi ~/.config<cr>",
    --     desc = "Browse configuration files",
    --   },
    --   {
    --     "<leader>fd",
    --     "<cmd>Yazi ~/dotfiles<cr>",
    --     desc = "Browse dotfiles repository",
    --   },
    --   {
    --     "<leader>fy",
    --     "<cmd>Yazi toggle<cr>",
    --     desc = "Toggle Yazi file browser",
    --   },
    --   {
    --     "<C-\\>",
    --     "<cmd>Yazi toggle<cr>",
    --     desc = "Toggle Yazi file browser (quick access)",
    --   },
    -- },
    ---@type YaziConfig | {}
    opts = {
      -- Replace netrw with Yazi for directory browsing
      open_for_directories = true,

      -- Appearance settings
      appearance = {
        -- Match Neovim color scheme (Tokyo Night)
        theme = "tokyo-night",
        -- Show borders similar to Neovim windows
        border = "rounded",
        -- Transparent background to match Neovim
        transparent = true,
        -- Show file icons from nvim-web-devicons
        use_web_devicons = true,
      },

      -- Window display settings
      window = {
        -- Centered layout for better visibility
        width = 0.9,
        height = 0.9,
        -- Window placement
        position = "center",
        -- Window behavior
        follow_cursor = true,
        -- Preserve state between sessions
        save_state = true,
      },

      -- Advanced keymaps for better navigation
      keymaps = {
        show_help = "<F1>",
        -- Quick navigation keys
        back = "<Esc>",
        quit = "q",
        -- Open file in different modes
        edit_split = "<C-s>",
        edit_vsplit = "<C-v>",
        edit_tab = "<C-t>",
        -- Quick directory navigation
        go_home = "~",
        go_parent = "..",
        -- File operations
        copy_path = "yp",
        copy_name = "yn",
        copy_contents = "yc",
      },

      -- Better performance on Apple Silicon
      -- performance = {
      --   -- Optimized values for faster rendering
      --   preview_debounce_ms = 30, -- Reduced for more responsive previews
      --   max_preview_size_mb = 15, -- Increased for larger files
      --   -- Enable file watching for auto-refresh with throttling
      --   watch_files = true,
      --   watch_throttle_ms = 100, -- Added throttling to prevent excessive updates
      --   -- Use nvim's native LSP when available
      --   use_nvim_lsp = true, -- Leverage LSP for syntax highlighting
      -- },
    },

    -- init = function()
    --   -- Disable netrw
    --   vim.g.loaded_netrw = 1
    --   vim.g.loaded_netrwPlugin = 1
    --
    --   -- Set up file icons with caching for better performance
    --   require("nvim-web-devicons").setup({
    --     default = true,
    --     strict = true,
    --     override_by_extension = {
    --       ["lua"] = {
    --         icon = "",
    --         color = "#51a0cf",
    --         name = "Lua",
    --       },
    --       ["md"] = {
    --         icon = "",
    --         color = "#519aba",
    --         name = "Markdown",
    --       },
    --       ["toml"] = {
    --         icon = "",
    --         color = "#6d8086",
    --         name = "Toml",
    --       },
    --     },
    --   })
    --
    --   -- Use plenary for async file operations
    --   vim.g.yazi_use_plenary = true
    --
    --   -- Enhanced handling of temporary files
    --   vim.api.nvim_create_autocmd("User", {
    --     pattern = "YaziTempfileCreated",
    --     callback = function(args)
    --       -- Handle the temporary file created by Yazi with better error handling
    --       if args.data and args.data.path then
    --         local path = args.data.path
    --         -- Check if path exists before opening
    --         if vim.fn.filereadable(path) == 1 then
    --           -- Use pcall to handle potential errors
    --           local ok, err = pcall(function()
    --             vim.cmd("e " .. vim.fn.fnameescape(path))
    --           end)
    --           if not ok then
    --             vim.notify("Error opening file: " .. err, vim.log.levels.ERROR)
    --           end
    --         else
    --           vim.notify("File not readable: " .. path, vim.log.levels.WARN)
    --         end
    --       end
    --     end,
    --   })
    -- end,
  },
}
