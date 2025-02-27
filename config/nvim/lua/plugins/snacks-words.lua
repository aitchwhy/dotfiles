-----------------------------------------------------------------------------------
-- SNACKS WORDS CONFIGURATION
-----------------------------------------------------------------------------------

return {
  {
    "snacks.nvim",
    opts = {
      -- Enable the words functionality
      words = {
        enabled = true, -- Enable words functionality
        
        -- Spell checking settings
        spell = {
          enabled = true,
          languages = { "en" },
        },
        
        -- Dictionary configuration
        dictionary = {
          sources = {
            { name = "spell" },
          },
          max_items = 10,
          exact_match_first = true,
        },
        
        -- Code completion configuration
        completion = {
          enabled = true,
          trigger_characters = 2,
          accept_on_select = false,
        },
      },
    },
  },
}