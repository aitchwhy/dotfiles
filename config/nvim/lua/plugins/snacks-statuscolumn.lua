-----------------------------------------------------------------------------------
-- SNACKS STATUSCOLUMN CONFIGURATION
-----------------------------------------------------------------------------------

return {
  {
    "snacks.nvim",
    opts = {
      -- Enable the statuscolumn functionality
      statuscolumn = {
        enabled = true, -- Enable statuscolumn
        
        -- Configuration for the line numbers and signs
        line_number = {
          enable = true,         -- Show line numbers
          relative = true,       -- Use relative line numbers
          inlay_enabled = false, -- Don't use inlay line numbers
          inlay_pattern = "^%d+$",
        },
        
        -- Sign column configuration
        sign_column = {
          enable = true,
          git = {
            enable = true,           -- Show git signs
            priority = 10,           -- Priority of git signs
            enable_sign_text = true, -- Show git sign text
          },
          diagnostics = {
            enable = true,           -- Show diagnostic signs
            priority = 20,           -- Priority of diagnostic signs
            enable_sign_text = true, -- Show diagnostic sign text
          },
        },
        
        -- Fold column configuration
        fold_column = {
          enable = true,       -- Show fold column
          dynamic_width = true, -- Adjust width based on fold levels
          min_width = 1,        -- Minimum width
          max_width = 2,        -- Maximum width
        },
        
        -- Separator configuration
        separator = {
          enable = true,   -- Show separator
          char = "│",      -- Character for separator
          padding = 0,     -- Padding around separator
          hl = "LineNr",   -- Highlight group
        },
      },
    },
  },
}