-- edgy.nvim - IDE-like window/pane management
return {
  {
    "folke/edgy.nvim",
    opts = {
      -- Left sidebar: Explorer, Symbols
      left = {
        { title = "Explorer", ft = "snacks_picker_list" },
        { title = "Symbols", ft = "Outline", size = { height = 0.4 } },
        { title = "Neotest Summary", ft = "neotest-summary" },
      },
      -- Right sidebar: AI Sidekick, Grug Far
      right = {
        { title = "Sidekick", ft = "sidekick", size = { width = 0.3 } },
        { title = "Grug Far", ft = "grug-far", size = { width = 0.4 } },
        { title = "Copilot Chat", ft = "copilot-chat", size = { width = 0.4 } },
      },
      -- Bottom: Terminal, Trouble, Test Output
      bottom = {
        { title = "Terminal", ft = "snacks_terminal", size = { height = 0.3 } },
        { title = "Trouble", ft = "trouble" },
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
    },
  },
}
