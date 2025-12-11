-- Snacks.nvim - The Swiss Army Knife for Neovim
-- Replaces: fzf-lua, yazi.nvim, lazygit.nvim, trouble.nvim
return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    ---@type snacks.Config
    opts = {
      -- File explorer (replaces yazi.nvim + neo-tree for quick nav)
      explorer = {
        enabled = true,
      },
      picker = {
        enabled = true,
        sources = {
          explorer = {
            layout = { preset = "sidebar", preview = false },
            git_status = true,
            git_untracked = true,
            diagnostics = true,
            watch = true,
          },
        },
      },
      -- LazyGit integration (replaces lazygit.nvim)
      lazygit = {
        enabled = true,
      },
      -- Notifications (enhanced vim.notify)
      notifier = {
        enabled = true,
        timeout = 3000,
        style = "compact",
      },
      -- Dashboard with Tokyo Night aesthetic
      dashboard = {
        enabled = true,
        preset = {
          keys = {
            { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.picker.files()" },
            { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
            { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.picker.grep()" },
            { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.picker.recent()" },
            {
              icon = " ",
              key = "c",
              desc = "Config",
              action = ":lua Snacks.picker.files({cwd = vim.fn.stdpath('config')})",
            },
            { icon = " ", key = "s", desc = "Restore Session", section = "session" },
            { icon = "󰒲 ", key = "l", desc = "Lazy", action = ":Lazy" },
            { icon = " ", key = "q", desc = "Quit", action = ":qa" },
          },
          header = [[
    ███╗   ██╗██╗██╗  ██╗██╗   ██╗██╗███╗   ███╗
    ████╗  ██║██║╚██╗██╔╝██║   ██║██║████╗ ████║
    ██╔██╗ ██║██║ ╚███╔╝ ██║   ██║██║██╔████╔██║
    ██║╚██╗██║██║ ██╔██╗ ╚██╗ ██╔╝██║██║╚██╔╝██║
    ██║ ╚████║██║██╔╝ ██╗ ╚████╔╝ ██║██║ ╚═╝ ██║
    ╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝  ╚═══╝  ╚═╝╚═╝     ╚═╝
          ]],
        },
        sections = {
          { section = "header" },
          { section = "keys", gap = 1, padding = 1 },
          { section = "startup" },
        },
      },
      -- Input (better vim.ui.input)
      input = {
        enabled = true,
      },
      -- Indentation guides
      indent = {
        enabled = true,
        animate = { enabled = false }, -- Disable animation for cleaner look
      },
      -- Smooth scrolling
      scroll = {
        enabled = true,
        animate = {
          duration = { step = 15, total = 150 },
          easing = "linear",
        },
      },
      -- Quick file opening
      quickfile = {
        enabled = true,
      },
      -- Word highlighting
      words = {
        enabled = true,
      },
      -- Status column
      statuscolumn = {
        enabled = true,
      },
      -- Scope detection
      scope = {
        enabled = true,
      },
      -- Big file handling
      bigfile = {
        enabled = true,
      },
    },
    -- Setup global debug functions
    init = function()
      vim.api.nvim_create_autocmd("User", {
        pattern = "VeryLazy",
        callback = function()
          -- Debug helpers
          _G.dd = function(...)
            Snacks.debug.inspect(...)
          end
          _G.bt = function()
            Snacks.debug.backtrace()
          end

          -- LSP progress notification
          vim.api.nvim_create_autocmd("LspProgress", {
            callback = function(ev)
              local spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
              vim.notify(vim.lsp.status(), "info", {
                id = "lsp_progress",
                title = "LSP Progress",
                opts = function(notif)
                  notif.icon = ev.data.params.value.kind == "end" and " "
                    or spinner[math.floor(vim.uv.hrtime() / (1e6 * 80)) % #spinner + 1]
                end,
              })
            end,
          })
        end,
      })
    end,
    keys = {
      -- Picker (replaces fzf-lua)
      {
        "<leader><space>",
        function()
          Snacks.picker.files()
        end,
        desc = "Find Files",
      },
      {
        "<leader>ff",
        function()
          Snacks.picker.files()
        end,
        desc = "Find Files",
      },
      {
        "<leader>fg",
        function()
          Snacks.picker.git_files()
        end,
        desc = "Git Files",
      },
      {
        "<leader>fr",
        function()
          Snacks.picker.recent()
        end,
        desc = "Recent Files",
      },
      {
        "<leader>fb",
        function()
          Snacks.picker.buffers()
        end,
        desc = "Buffers",
      },
      {
        "<leader>/",
        function()
          Snacks.picker.grep()
        end,
        desc = "Grep",
      },
      {
        "<leader>sg",
        function()
          Snacks.picker.grep()
        end,
        desc = "Grep",
      },
      {
        "<leader>sw",
        function()
          Snacks.picker.grep_word()
        end,
        desc = "Grep Word",
        mode = { "n", "x" },
      },
      {
        "<leader>:",
        function()
          Snacks.picker.command_history()
        end,
        desc = "Command History",
      },
      {
        "<leader>sh",
        function()
          Snacks.picker.help()
        end,
        desc = "Help Pages",
      },
      {
        "<leader>sk",
        function()
          Snacks.picker.keymaps()
        end,
        desc = "Keymaps",
      },
      {
        "<leader>sm",
        function()
          Snacks.picker.marks()
        end,
        desc = "Marks",
      },
      {
        "<leader>sR",
        function()
          Snacks.picker.resume()
        end,
        desc = "Resume Last Picker",
      },

      -- Explorer (replaces yazi + neo-tree quick nav)
      {
        "<leader>e",
        function()
          Snacks.explorer()
        end,
        desc = "Explorer",
      },
      {
        "<leader>fe",
        function()
          Snacks.explorer()
        end,
        desc = "File Explorer",
      },

      -- Git (replaces lazygit.nvim)
      {
        "<leader>gg",
        function()
          Snacks.lazygit()
        end,
        desc = "LazyGit",
      },
      {
        "<leader>gf",
        function()
          Snacks.picker.git_log_file()
        end,
        desc = "Git File History",
      },
      {
        "<leader>gl",
        function()
          Snacks.picker.git_log()
        end,
        desc = "Git Log",
      },
      {
        "<leader>gs",
        function()
          Snacks.picker.git_status()
        end,
        desc = "Git Status",
      },
      {
        "<leader>gb",
        function()
          Snacks.picker.git_log_line()
        end,
        desc = "Git Blame Line",
      },
      {
        "<leader>gB",
        function()
          Snacks.gitbrowse()
        end,
        desc = "Git Browse",
        mode = { "n", "x" },
      },

      -- Diagnostics (replaces trouble.nvim basic usage)
      {
        "<leader>sd",
        function()
          Snacks.picker.diagnostics()
        end,
        desc = "Diagnostics",
      },
      {
        "<leader>sD",
        function()
          Snacks.picker.diagnostics_buffer()
        end,
        desc = "Buffer Diagnostics",
      },

      -- LSP
      {
        "gd",
        function()
          Snacks.picker.lsp_definitions()
        end,
        desc = "Goto Definition",
      },
      {
        "gr",
        function()
          Snacks.picker.lsp_references()
        end,
        desc = "References",
      },
      {
        "gI",
        function()
          Snacks.picker.lsp_implementations()
        end,
        desc = "Implementations",
      },
      {
        "gy",
        function()
          Snacks.picker.lsp_type_definitions()
        end,
        desc = "Type Definitions",
      },
      {
        "<leader>ss",
        function()
          Snacks.picker.lsp_symbols()
        end,
        desc = "LSP Symbols",
      },

      -- Terminal
      {
        "<leader>ft",
        function()
          Snacks.terminal()
        end,
        desc = "Terminal",
      },
      {
        "<c-/>",
        function()
          Snacks.terminal()
        end,
        desc = "Terminal",
      },

      -- Buffer management
      {
        "<leader>bd",
        function()
          Snacks.bufdelete()
        end,
        desc = "Delete Buffer",
      },
      {
        "<leader>bo",
        function()
          Snacks.bufdelete.other()
        end,
        desc = "Delete Other Buffers",
      },

      -- Toggles
      {
        "<leader>un",
        function()
          Snacks.notifier.hide()
        end,
        desc = "Dismiss Notifications",
      },
      {
        "<leader>uN",
        function()
          Snacks.notifier.show_history()
        end,
        desc = "Notification History",
      },
    },
  },
}
