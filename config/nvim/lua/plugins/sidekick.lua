-- Sidekick.nvim - Unified AI with NES (Next Edit Suggestions)
-- Primary: Claude CLI | Backend: Zellij (ENFORCED - no tmux)
return {
  {
    "folke/sidekick.nvim",
    opts = {
      nes = {
        enabled = true,
        debounce = 100,
        diff = { inline = "words" }, -- Show word-level inline diffs
      },
      cli = {
        watch = true, -- Auto-reload files changed by AI CLI
        mux = {
          backend = "zellij", -- ENFORCED: Zellij only (no tmux)
          enabled = true,     -- Persist sessions across NeoVim restarts
        },
        win = {
          layout = "right",
          split = { width = 80, height = 20 },
          float = { width = 0.9, height = 0.9 },
        },
        -- Configure Claude as the primary/default tool
        tools = {
          claude = {
            cmd = { "claude", "--dangerously-skip-permissions" },
            url = "https://github.com/anthropics/claude-code",
          },
        },
        -- Custom prompts for Claude
        prompts = {
          explain = "Explain this code",
          fix = { msg = "Fix the issues in this code", diagnostics = true },
          review = { msg = "Review this code for issues or improvements", diagnostics = true },
          optimize = "How can this code be optimized?",
          tests = "Write tests for this code",
        },
      },
      copilot = {
        status = { enabled = true }, -- Track Copilot status for NES
      },
    },
    keys = {
      -- Tab to jump/apply next edit suggestions (NES)
      {
        "<tab>",
        function()
          if not require("sidekick").nes_jump_or_apply() then
            return "<Tab>"
          end
        end,
        expr = true,
        desc = "Goto/Apply Next Edit Suggestion",
      },
      -- Claude CLI (primary tool)
      {
        "<leader>aa",
        function()
          require("sidekick.cli").toggle({ focus = true })
        end,
        mode = { "n", "v" },
        desc = "Sidekick Toggle CLI",
      },
      {
        "<leader>ac",
        function()
          require("sidekick.cli").toggle({ name = "claude", focus = true })
        end,
        mode = { "n", "v" },
        desc = "Claude CLI",
      },
      {
        "<leader>as",
        function()
          require("sidekick.cli").select()
        end,
        desc = "Select AI CLI Tool",
      },
      {
        "<leader>ap",
        function()
          require("sidekick.cli").prompt()
        end,
        mode = { "n", "v" },
        desc = "AI Prompt",
      },
      {
        "<leader>at",
        function()
          require("sidekick.cli").send({ msg = "{this}" })
        end,
        mode = { "n", "x" },
        desc = "Send This to AI",
      },
      {
        "<leader>af",
        function()
          require("sidekick.cli").send({ msg = "{file}" })
        end,
        desc = "Send File to AI",
      },
      -- Focus toggle
      {
        "<C-.>",
        function()
          require("sidekick.cli").focus()
        end,
        mode = { "n", "x", "i", "t" },
        desc = "Sidekick Switch Focus",
      },
    },
  },
}
