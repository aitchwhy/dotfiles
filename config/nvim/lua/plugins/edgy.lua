-- edgy.nvim - IDE-like window/pane management
-- Merges with LazyVim defaults to preserve overseer, trouble, neotest integrations
return {
  {
    "folke/edgy.nvim",
    event = "VeryLazy",
    keys = {
      { "<leader>ue", function() require("edgy").toggle() end, desc = "Edgy Toggle" },
      { "<leader>uE", function() require("edgy").select() end, desc = "Edgy Select Window" },
      {
        "<leader>az",
        function()
          local edgy = require("edgy")
          -- If in an edgy window, zoom it; otherwise zoom Sidekick
          for _, w in ipairs(edgy.get_wins()) do
            if w.win == vim.api.nvim_get_current_win() then
              w:toggle_zoom()
              return
            end
          end
          -- Fallback: zoom Sidekick specifically
          for _, w in ipairs(edgy.get_wins()) do
            if w.view and w.view.ft == "sidekick" then
              w:toggle_zoom()
              return
            end
          end
        end,
        desc = "Zoom AI Pane",
      },
    },
    opts = function(_, opts)
      -- Initialize position tables
      opts.left = opts.left or {}
      opts.right = opts.right or {}
      opts.bottom = opts.bottom or {}

      -- LEFT SIDEBAR: Explorer, Symbols, Neotest Summary
      table.insert(opts.left, 1, {
        title = "Explorer",
        ft = "snacks_picker_list",
        filter = function(buf, win)
          return vim.w[win].snacks_win
            and vim.w[win].snacks_win.position == "left"
            and vim.w[win].snacks_win.relative == "editor"
        end,
      })
      table.insert(opts.left, { title = "Symbols", ft = "aerial", size = { height = 0.4 } })
      table.insert(opts.left, { title = "Neotest Summary", ft = "neotest-summary" })

      -- RIGHT SIDEBAR: Sidekick, Overseer, Grug Far
      table.insert(opts.right, 1, { title = "Sidekick", ft = "sidekick", size = { width = 0.5 } })
      table.insert(opts.right, {
        title = "Overseer",
        ft = "OverseerList",
        open = function() require("overseer").open() end,
        size = { width = 0.3 },
      })
      table.insert(opts.right, { title = "Grug Far", ft = "grug-far", size = { width = 0.4 } })

      -- BOTTOM: Neotest Output, QuickFix, Help
      table.insert(opts.bottom, { title = "Neotest Output", ft = "neotest-output-panel", size = { height = 15 } })
      table.insert(opts.bottom, { ft = "qf", title = "QuickFix" })
      table.insert(opts.bottom, {
        ft = "help",
        size = { height = 20 },
        filter = function(buf) return vim.bo[buf].buftype == "help" end,
      })

      -- DAP View Integration (Bottom Panel) - Modern minimalistic debug UI
      table.insert(opts.bottom, { title = "Debug", ft = "dap-view", size = { height = 0.3 } })
      table.insert(opts.bottom, { title = "Debug Terminal", ft = "dap-view-term", size = { height = 0.3 } })

      -- RESIZE KEYBINDINGS
      opts.keys = opts.keys or {}
      opts.keys["<C-Right>"] = function(win) win:resize("width", 2) end
      opts.keys["<C-Left>"] = function(win) win:resize("width", -2) end
      opts.keys["<C-Up>"] = function(win) win:resize("height", 2) end
      opts.keys["<C-Down>"] = function(win) win:resize("height", -2) end

      -- IDE-like window options (resizable, winbar visible)
      opts.animate = { enabled = false } -- Disable for snappier resize
      opts.wo = {
        winbar = true, -- Show winbar in edgy windows
        winfixwidth = false, -- Allow width changes
        winfixheight = false, -- Allow height changes
      }

      -- TROUBLE.NVIM INTEGRATION (all positions)
      for _, pos in ipairs({ "top", "bottom", "left", "right" }) do
        opts[pos] = opts[pos] or {}
        table.insert(opts[pos], {
          ft = "trouble",
          filter = function(_buf, win)
            return vim.w[win].trouble
              and vim.w[win].trouble.position == pos
              and vim.w[win].trouble.type == "split"
              and vim.w[win].trouble.relative == "editor"
              and not vim.w[win].trouble_preview
          end,
        })
      end

      -- SNACKS TERMINAL INTEGRATION (all positions)
      for _, pos in ipairs({ "top", "bottom", "left", "right" }) do
        opts[pos] = opts[pos] or {}
        table.insert(opts[pos], {
          ft = "snacks_terminal",
          size = { height = 0.3 },
          title = "%{b:snacks_terminal.id}: %{b:term_title}",
          filter = function(_buf, win)
            return vim.w[win].snacks_win
              and vim.w[win].snacks_win.position == pos
              and vim.w[win].snacks_win.relative == "editor"
          end,
        })
      end

      return opts
    end,
  },
}
