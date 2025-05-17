return {
  {
    "zbirenbaum/copilot.lua",
    opts = {
      suggestion = {
        enabled = not vim.g.ai_cmp,
        auto_trigger = true,
        hide_during_completion = vim.g.ai_cmp,
        keymap = {
          accept = false, -- handled by nvim-cmp / blink.cmp
          next = "<M-]>",
          prev = "<M-[>",
        },
      },
      panel = { enabled = true },
      filetypes = {
        markdown = true,
        help = true,
        typescript = true,
        nix = true,
        ["*"] = false, -- disable for all other filetypes
      },
    },
  },
}
