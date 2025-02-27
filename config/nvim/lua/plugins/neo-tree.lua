-----------------------------------------------------------------------------------
-- NEO-TREE CONFIGURATION - MODERN FILE EXPLORER
-----------------------------------------------------------------------------------

return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    cmd = "Neotree",
    -- Load when these keys are pressed
    keys = {
      { "<leader>e", "<cmd>Neotree toggle<cr>", desc = "Toggle Explorer" },
      { "<leader>o", "<cmd>Neotree focus<cr>", desc = "Focus Explorer" },
      { "<leader>E", "<cmd>Neotree reveal<cr>", desc = "Reveal File in Explorer" },
      {
        "<leader>ge",
        function()
          require("neo-tree.command").execute({ source = "git_status", toggle = true })
        end,
        desc = "Git Explorer",
      },
      {
        "<leader>be",
        function()
          require("neo-tree.command").execute({ source = "buffers", toggle = true })
        end,
        desc = "Buffer Explorer",
      },
    },
    
    -- Plugin configuration
    opts = {
      -- Close neo-tree when opening a file
      close_if_last_window = true,
      -- Enable cursor following for the current file
      enable_git_status = true,
      enable_diagnostics = true,
      
      -- Configure git integration
      git_status = {
        window = {
          position = "float",
          mappings = {
            ["A"] = "git_add_all",
            ["u"] = "git_unstage_file",
            ["a"] = "git_add_file",
            ["r"] = "git_revert_file",
            ["c"] = "git_commit",
            ["p"] = "git_push",
          },
        },
      },
      
      -- Configure popup window
      popup_border_style = "rounded",
      
      -- Configure the file system browser
      filesystem = {
        -- Follow current file when opening/switching buffers
        follow_current_file = { enabled = true },
        -- Use netrw when opening directories from vim command line
        hijack_netrw_behavior = "open_current",
        -- Use libuv file watcher for better performance
        use_libuv_file_watcher = true,
        -- Don't filter certain files/directories by default
        filtered_items = {
          visible = true, -- Show hidden files by default
          hide_dotfiles = false,
          hide_gitignored = false,
          hide_by_name = {
            ".git",
            "node_modules",
            ".cache",
          },
          never_show = {
            ".DS_Store",
            "thumbs.db",
          },
        },
      },
      
      -- Window configuration
      window = {
        width = 35, -- Default width
        mappings = {
          -- Remove space as a mapping
          ["<space>"] = "none",
          -- Add useful mappings
          ["h"] = "navigate_up", -- Go up one directory with 'h'
          ["l"] = "open", -- Open directory or file with 'l'
          ["H"] = "toggle_hidden", -- Toggle hidden files with 'H'
          ["C"] = "close_node",
          ["z"] = "close_all_nodes",
          ["Z"] = "expand_all_nodes",
          ["R"] = "refresh",
          ["a"] = { 
            "add",
            config = {
              show_path = "relative", -- Show relative paths in the add dialog
            },
          },
          ["d"] = "delete",
          ["r"] = "rename",
          ["y"] = "copy_to_clipboard",
          ["x"] = "cut_to_clipboard",
          ["p"] = "paste_from_clipboard",
          ["c"] = "copy", -- Copy file to a new location
          ["m"] = "move", -- Move file to a new location
          ["q"] = "close_window",
          ["?"] = "show_help",
          ["<"] = "prev_source",
          [">"] = "next_source",
        },
      },
      
      -- File nesting patterns (show related files together)
      nesting_rules = {
        -- Group React component files together
        ["package.json"] = { "package-lock.json", "yarn.lock", "pnpm-lock.yaml", ".npmrc" },
        -- Group configuration files together
        ["docker-compose.yml"] = { "docker-compose.*.yml" },
        -- Group test files with their implementation
        [".*.js"] = { "${capture}.test.js", "${capture}.spec.js" },
        [".*.ts"] = { "${capture}.test.ts", "${capture}.spec.ts", "${capture}.d.ts" },
        [".*.tsx"] = { "${capture}.test.tsx", "${capture}.spec.tsx" },
        [".*.jsx"] = { "${capture}.test.jsx", "${capture}.spec.jsx" },
      },
      
      -- File icons and decorations
      default_component_configs = {
        indent = {
          with_expanders = true, -- Use expander icons for folders
          expander_collapsed = "",
          expander_expanded = "",
          expander_highlight = "NeoTreeExpander",
        },
        icon = {
          folder_closed = "",
          folder_open = "",
          folder_empty = "",
          folder_empty_open = "",
        },
        git_status = {
          symbols = {
            -- Change symbols based on status
            added = "✓",
            deleted = "✕",
            modified = "",
            renamed = "➜",
            untracked = "★",
            ignored = "◌",
            unstaged = "✗",
            staged = "✓",
            conflict = "!",
          },
        },
        modified = {
          symbol = "●",
          highlight = "NeoTreeModified",
        },
      },
    },
  },
}
