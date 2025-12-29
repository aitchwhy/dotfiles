-- edgy.nvim - IDE-like window/pane management
-- Manages sidebar and panel layouts for snacks explorer, terminal, sidekick, etc.
return {
  {
    "folke/edgy.nvim",
    opts = function()
      local opts = {
        -- Left sidebar: Explorer, Symbols
        left = {
          {
            title = "Explorer",
            ft = "snacks_picker_list",
            -- Filter to only capture sidebar explorer, NOT floating pickers
            filter = function(buf, win)
              return vim.w[win].snacks_win
                and vim.w[win].snacks_win.position == "left"
                and vim.w[win].snacks_win.relative == "editor"
            end,
          },
          { title = "Symbols", ft = "Outline", size = { height = 0.4 } },
          { title = "Neotest Summary", ft = "neotest-summary" },
        },
        -- Right sidebar: AI Sidekick, Grug Far
        right = {
          { title = "Sidekick", ft = "sidekick", size = { width = 0.35 } },
          { title = "Grug Far", ft = "grug-far", size = { width = 0.4 } },
        },
        -- Bottom: Neotest Output, QuickFix
        bottom = {
          { title = "Neotest Output", ft = "neotest-output-panel", size = { height = 15 } },
          { ft = "qf", title = "QuickFix" },
        },
        -- Resize keybindings
        keys = {
          ["<C-Right>"] = function(win)
            win:resize("width", 2)
          end,
          ["<C-Left>"] = function(win)
            win:resize("width", -2)
          end,
          ["<C-Up>"] = function(win)
            win:resize("height", 2)
          end,
          ["<C-Down>"] = function(win)
            win:resize("height", -2)
          end,
        },
      }

      -- Dynamic snacks_terminal integration for all positions
      -- Only captures split terminals (relative == "editor"), not floating ones
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
