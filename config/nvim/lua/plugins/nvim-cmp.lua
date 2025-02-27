-----------------------------------------------------------------------------------
-- NVIM-CMP CONFIGURATION - AUTOCOMPLETION ENGINE
-----------------------------------------------------------------------------------

return {
  "hrsh7th/nvim-cmp",
  version = false, -- Last release is way too old
  event = "InsertEnter",
  dependencies = {
    -- Sources for completion
    "hrsh7th/cmp-nvim-lsp",           -- LSP source
    "hrsh7th/cmp-buffer",             -- Buffer source
    "hrsh7th/cmp-path",               -- Path source
    "hrsh7th/cmp-cmdline",            -- Command line source
    "saadparwaiz1/cmp_luasnip",       -- Snippet source
    "hrsh7th/cmp-nvim-lua",           -- Neovim Lua API
    "hrsh7th/cmp-emoji",              -- Emoji source
    
    -- Snippet engine (required for some completion items)
    "L3MON4D3/LuaSnip",               -- Snippet engine
    "rafamadriz/friendly-snippets",   -- Snippet collection
    
    -- Icons
    "onsails/lspkind.nvim",           -- VSCode-like pictograms
  },
  opts = function()
    local cmp = require("cmp")
    local luasnip = require("luasnip")
    local lspkind = require("lspkind")
    
    -- Load friendly-snippets
    require("luasnip.loaders.from_vscode").lazy_load()
    
    -- Helper function to check if text exists before the cursor
    local has_text_before_cursor = function()
      local line, col = unpack(vim.api.nvim_win_get_cursor(0))
      return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
    end
    
    return {
      -- Configure completion window appearance
      window = {
        completion = {
          winhighlight = "Normal:Pmenu,FloatBorder:Pmenu,CursorLine:PmenuSel,Search:None",
          col_offset = -3,
          side_padding = 0,
        },
        documentation = {
          winhighlight = "Normal:Pmenu,FloatBorder:Pmenu,Search:None",
          border = "rounded",
          max_width = 80,
          max_height = 20,
        },
      },
      
      -- Configure completion behavior
      completion = {
        completeopt = "menu,menuone,noinsert,noselect", 
        keyword_length = 1,          -- Min length to trigger completion
      },
      
      -- Configure snippet expansion
      snippet = {
        expand = function(args)
          luasnip.lsp_expand(args.body)
        end,
      },
      
      -- Configure key mappings
      mapping = cmp.mapping.preset.insert({
        -- Navigate completion menu
        ["<C-n>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
        ["<C-p>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
        ["<Down>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Select }),
        ["<Up>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }),
        
        -- Scroll documentation
        ["<C-b>"] = cmp.mapping.scroll_docs(-4),
        ["<C-f>"] = cmp.mapping.scroll_docs(4),
        
        -- Cancel completion
        ["<C-e>"] = cmp.mapping.abort(),
        
        -- Accept completion
        ["<CR>"] = cmp.mapping.confirm({ select = false }),
        ["<Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_next_item()
          elseif luasnip.expand_or_jumpable() then
            luasnip.expand_or_jump()
          elseif has_text_before_cursor() then
            cmp.complete()
          else
            fallback()
          end
        end, { "i", "s" }),
        ["<S-Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item()
          elseif luasnip.jumpable(-1) then
            luasnip.jump(-1)
          else
            fallback()
          end
        end, { "i", "s" }),
      }),
      
      -- Configure sources for autocompletion
      sources = cmp.config.sources({
        { name = "nvim_lsp", priority = 1000 },
        { name = "luasnip", priority = 750 },
        { name = "buffer", priority = 500 },
        { name = "path", priority = 250 },
        { name = "nvim_lua", priority = 700 },
        { name = "emoji", priority = 300 },
      }),
      
      -- Format completion items (VSCode-like pictograms)
      formatting = {
        format = lspkind.cmp_format({
          mode = "symbol_text",
          maxwidth = 50,
          ellipsis_char = "...",
          show_labelDetails = true, 
          before = function(entry, vim_item)
            -- Add source name to entry
            vim_item.menu = ({
              nvim_lsp = "[LSP]",
              luasnip = "[Snippet]",
              buffer = "[Buffer]",
              path = "[Path]",
              nvim_lua = "[Lua]",
              emoji = "[Emoji]",
            })[entry.source.name]
            return vim_item
          end,
        }),
      },
      
      -- Configure experimental features
      experimental = {
        ghost_text = {
          hl_group = "Comment",
        },
      },
    }
  end,
  
  -- Additional setup for Command line completion
  config = function(_, opts)
    -- Set up nvim-cmp with provided options
    local cmp = require("cmp")
    cmp.setup(opts)
    
    -- Set up specific completion sources for command mode
    cmp.setup.cmdline(":", {
      mapping = cmp.mapping.preset.cmdline(),
      sources = cmp.config.sources({
        { name = "path" },
        { name = "cmdline" },
      }),
    })
    
    -- Set up specific completion sources for search mode
    cmp.setup.cmdline("/", {
      mapping = cmp.mapping.preset.cmdline(),
      sources = {
        { name = "buffer" },
      },
    })
  end,
}
