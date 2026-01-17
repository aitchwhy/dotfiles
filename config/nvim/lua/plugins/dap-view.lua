-- nvim-dap-view: Modern, minimalistic debug UI (SOTA Jan 2026)
-- Requires NeoVim 0.11+ (have 0.11.5)
-- Replaces nvim-dap-ui with consolidated tabbed interface
return {
  {
    "igorlfs/nvim-dap-view",
    dependencies = { "mfussenegger/nvim-dap" },
    lazy = true,
    cmd = { "DapViewOpen", "DapViewClose", "DapViewToggle", "DapViewWatch" },
    keys = {
      { "<leader>dv", "<cmd>DapViewToggle<cr>", desc = "Toggle DAP View" },
      { "<leader>dW", "<cmd>DapViewWatch<cr>", desc = "Add Watch Expression" },
    },
    opts = {
      winbar = {
        -- Show all 8 views in tabbed interface
        sections = { "watches", "scopes", "exceptions", "breakpoints", "threads", "repl", "sessions", "console" },
        -- Quick access keymaps (press key to switch view)
        default_section_keymaps = true,
      },
      windows = {
        -- 30% height, positioned below editor
        size = 0.3,
        position = "below",
        terminal = {
          -- Console/terminal hidden by default, toggle with 'c' key
          hide = true,
          size = 0.5,
          position = "left",
        },
      },
      -- Auto-open/close with debug session
      auto_toggle = true,
      -- Follow debugging across tab switches
      follow_tab = true,
      -- Clickable control bar on right side
      controls = {
        enabled = true,
        position = "right",
        buttons = { "play", "step_into", "step_over", "step_out", "run_last", "terminate" },
      },
    },
  },

  -- Disable nvim-dap-ui (replaced by dap-view)
  { "rcarriga/nvim-dap-ui", enabled = false },
  -- NOTE: nvim-nio kept enabled - used by neotest adapters
}
