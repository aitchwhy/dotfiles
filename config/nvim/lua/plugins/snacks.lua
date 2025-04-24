-----------------------------------------------------------------------------------
-- SNACKS.NVIM - QUICK ACCESS UTILITIES
-----------------------------------------------------------------------------------
-- A utility plugin that provides quick access to files, commands and more
-- Documentation: https://github.com/kevinhwang91/snacks.nvim
-- Features:
-- * Fast file navigation and fuzzy finding
-- * Project-aware file browsing
-- * Integrated with LazyVim keymaps
return {
    {
        "kevinhwang91/snacks.nvim",
        lazy = false, -- Load on startup, as it's core functionality
        opts = function()
            local LazyVim = require("lazyvim.util")
            
            return {
                -- Register toggle functionality with LazyVim's keymap helpers
                -- This ensures proper integration with LazyVim's key handling
                toggle = {
                    map = LazyVim.safe_keymap_set
                },

                -- Configure file picker appearance and behavior
                picker = {
                    prompt_title = "Snack Explorer", -- Custom title for file picker
                    cwd_only = false,                -- Show files outside of current working dir
                },
                -- Additional components can be enabled here:
                -- input = { enabled = true },       -- Enhanced input handling
                -- notifier = { enabled = true },    -- Notification system
                -- scope = { enabled = true },       -- Scoped file finder
                -- scroll = { enabled = true },      -- Smooth scrolling
            }
        end,
    },
}
