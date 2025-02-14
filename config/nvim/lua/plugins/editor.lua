-- editor.lua: Editing UI, text manipulation, and AI plugins
return {

  -- nvim-web-devicons
  { "nvim-tree/nvim-web-devicons", opts = {} },

  -- mini.icons (standalone)
  { "echasnovski/mini.icons",      version = false },

  -- flash.nvim (Flash enhances the built-in search functionality by showing labels at the end of each match, letting you quickly jump to a specific location.)
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
      {
        "s",
        mode = { "n", "x", "o" },
        function()
          require("flash").jump()
        end,
        desc = "Flash",
      },
      {
        "S",
        mode = { "n", "x", "o" },
        function()
          require("flash").treesitter()
        end,
        desc = "Flash Treesitter",
      },
      {
        "<c-s>",
        mode = { "c" },
        function()
          require("flash").toggle()
        end,
        desc = "Toggle Flash Search",
      },
    },
  },

  -- grug-far (search/replace in multiple files)

  -- which-key (which-key helps you remember key bindings by showing a popup with the active keybindings of the command you started typing.)
  -- AUTOPAIRS: auto-close brackets, integrate with cmp
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      require("nvim-autopairs").setup({})
      -- If using nvim-cmp, integrate autopairs into completion confirmations:
      local cmp_ok, cmp = pcall(require, "cmp")
      if cmp_ok then
        require("nvim-autopairs.completion.cmp").setup({ map_cr = true })
      end
    end,
  },


  -- HOP/LEAP: quick navigation within buffer
  {
    "ggandor/leap.nvim",
    keys = { "s", "S" },
    config = function()
      require("leap").add_default_mappings()
    end,
  },

  -- AI: GitHub Copilot
  -- { "github/copilot.vim", event = "InsertEnter", enabled = true }, -- Copilot suggestions (requires Node & login)

  -- AI: Codeium (alternative to Copilot, disabled by default here)
  -- {
  --   "Exafunction/codeium.vim",
  --   enabled = false,
  --   config = function()
  --     -- Codeium uses <Tab> by default, which we disable to avoid conflict with LuaSnip
  --     vim.g.codeium_no_map_tab = true
  --   end,
  -- },

  -- -- AI: ChatGPT integration
  -- {
  --   "jackMort/ChatGPT.nvim",
  --   cmd = { "ChatGPT", "ChatGPTActAs", "ChatGPTEditWithInstructions" },
  --   dependencies = { "MunifTanjim/nui.nvim", "nvim-lua/plenary.nvim", "nvim-telescope/telescope.nvim" },
  --   config = function()
  --     require("chatgpt").setup({
  --       -- (Add your OpenAI API key in your environment as OPENAI_API_KEY for this to work)
  --     })
  --   end,
  -- },
}
