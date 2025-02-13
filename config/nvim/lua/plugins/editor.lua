-- editor.lua: Editing UI, text manipulation, and AI plugins
return {

  -- grug-far (search/replace in multiple files)
  {
    "MagicDuck/grug-far.nvim",
    opts = { headerMaxWidth = 80 },
    cmd = "GrugFar",
    keys = {
      {
        "<leader>sr",
        function()
          local grug = require("grug-far")
          local ext = vim.bo.buftype == "" and vim.fn.expand("%:e")
          grug.open({
            transient = true,
            prefills = {
              filesFilter = ext and ext ~= "" and "*." .. ext or nil,
            },
          })
        end,
        mode = { "n", "v" },
        desc = "Search and Replace",
      },
    },
  },

  -- flash.nvim (Flash enhances the built-in search functionality by showing labels at the end of each match, letting you quickly jump to a specific location.)
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    vscode = true,
    ---@type Flash.Config
    opts = {},
  -- stylua: ignore
  keys = {
    { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
    { "S", mode = { "n", "o", "x" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
    { "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
    { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
    { "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle Flash Search" },
  },
  },

  -- which-key (which-key helps you remember key bindings by showing a popup with the active keybindings of the command you started typing.)
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts_extend = { "spec" },
    opts = {
      preset = "helix",
      defaults = {},
      spec = {
        {
          mode = { "n", "v" },
          { "<leader><tab>", group = "tabs" },
          { "<leader>c", group = "code" },
          { "<leader>d", group = "debug" },
          { "<leader>dp", group = "profiler" },
          { "<leader>f", group = "file/find" },
          { "<leader>g", group = "git" },
          { "<leader>gh", group = "hunks" },
          { "<leader>q", group = "quit/session" },
          { "<leader>s", group = "search" },
          { "<leader>u", group = "ui", icon = { icon = "󰙵 ", color = "cyan" } },
          { "<leader>x", group = "diagnostics/quickfix", icon = { icon = "󱖫 ", color = "green" } },
          { "[", group = "prev" },
          { "]", group = "next" },
          { "g", group = "goto" },
          { "gs", group = "surround" },
          { "z", group = "fold" },
          {
            "<leader>b",
            group = "buffer",
            expand = function()
              return require("which-key.extras").expand.buf()
            end,
          },
          {
            "<leader>w",
            group = "windows",
            proxy = "<c-w>",
            expand = function()
              return require("which-key.extras").expand.win()
            end,
          },
          -- better descriptions
          { "gx", desc = "Open with system app" },
        },
      },
    },
    keys = {
      {
        "<leader>?",
        function()
          require("which-key").show({ global = false })
        end,
        desc = "Buffer Keymaps (which-key)",
      },
      {
        "<c-w><space>",
        function()
          require("which-key").show({ keys = "<c-w>", loop = true })
        end,
        desc = "Window Hydra Mode (which-key)",
      },
    },
    config = function(_, opts)
      local wk = require("which-key")
      wk.setup(opts)
      if not vim.tbl_isempty(opts.defaults) then
        LazyVim.warn("which-key: opts.defaults is deprecated. Please use opts.spec instead.")
        wk.register(opts.defaults)
      end
    end,
  },

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

  -- SURROUND: manipulate surrounding characters
  { "kylechui/nvim-surround", event = "VeryLazy", config = true }, -- uses default setup

  -- COMMENT: toggle comments easily
  { "numToStr/Comment.nvim", event = "VeryLazy", config = true }, -- provides gc mapping&#8203;:contentReference[oaicite:48]{index=48}

  -- TODO HIGHLIGHTER
  {
    "folke/todo-comments.nvim",
    event = "VeryLazy",
    dependencies = "nvim-lua/plenary.nvim",
    config = function()
      require("todo-comments").setup({})
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
  { "github/copilot.vim", event = "InsertEnter", enabled = true }, -- Copilot suggestions (requires Node & login)

  -- AI: Codeium (alternative to Copilot, disabled by default here)
  {
    "Exafunction/codeium.vim",
    enabled = false,
    config = function()
      -- Codeium uses <Tab> by default, which we disable to avoid conflict with LuaSnip
      vim.g.codeium_no_map_tab = true
    end,
  },

  -- AI: ChatGPT integration
  {
    "jackMort/ChatGPT.nvim",
    cmd = { "ChatGPT", "ChatGPTActAs", "ChatGPTEditWithInstructions" },
    dependencies = { "MunifTanjim/nui.nvim", "nvim-lua/plenary.nvim", "nvim-telescope/telescope.nvim" },
    config = function()
      require("chatgpt").setup({
        -- (Add your OpenAI API key in your environment as OPENAI_API_KEY for this to work)
      })
    end,
  },
}
