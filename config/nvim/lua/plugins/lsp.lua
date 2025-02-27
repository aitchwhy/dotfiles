-----------------------------------------------------------------------------------
-- LSP CONFIGURATION - LANGUAGE SERVER PROTOCOL SETTINGS
-----------------------------------------------------------------------------------

return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      -- Ensure required dependencies are loaded
      "mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "hrsh7th/cmp-nvim-lsp",
    },
    opts = {
      -- Diagnostics configuration
      diagnostics = {
        underline = true,
        update_in_insert = false,
        virtual_text = {
          spacing = 4,
          prefix = "●", -- Or use "■", "▎", "●", etc.
          source = "if_many",
        },
        severity_sort = true,
        float = {
          border = "rounded",
          source = "always",
          header = "",
          prefix = "",
        },
      },
      
      -- Customize how LSP appears in various UIs
      inlay_hints = {
        enabled = true, -- Modern LSP servers provide type hints inline
      },
      
      -- Configure specific LSP servers
      servers = {
        -- Web Development
        tsserver = {
          settings = {
            typescript = {
              inlayHints = {
                includeInlayParameterNameHints = "all",
                includeInlayParameterNameHintsWhenArgumentMatchesName = false,
                includeInlayFunctionParameterTypeHints = true,
                includeInlayVariableTypeHints = true,
                includeInlayPropertyDeclarationTypeHints = true,
                includeInlayFunctionLikeReturnTypeHints = true,
                includeInlayEnumMemberValueHints = true,
              },
            },
            javascript = {
              inlayHints = {
                includeInlayParameterNameHints = "all",
                includeInlayParameterNameHintsWhenArgumentMatchesName = false,
                includeInlayFunctionParameterTypeHints = true,
                includeInlayVariableTypeHints = true,
                includeInlayPropertyDeclarationTypeHints = true,
                includeInlayFunctionLikeReturnTypeHints = true,
                includeInlayEnumMemberValueHints = true,
              },
            },
          },
        },
        eslint = {
          settings = {
            -- Customize ESLint behavior
            workingDirectory = { mode = "auto" },
            format = { enable = true },
            lint = { enable = true },
          },
        },
        
        -- Python
        pyright = {
          settings = {
            python = {
              analysis = {
                typeCheckingMode = "basic",
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
                diagnosticMode = "workspace",
              },
            },
          },
        },
        ruff_lsp = {
          settings = {
            -- Use Ruff's default rules for linting
          },
        },
        
        -- Rust
        rust_analyzer = {
          settings = {
            ["rust-analyzer"] = {
              checkOnSave = {
                command = "clippy",
                extraArgs = { "--all", "--", "-W", "clippy::all" },
              },
              procMacro = {
                enable = true,
              },
              cargo = {
                buildScripts = {
                  enable = true,
                },
                features = "all",
              },
            },
          },
        },
        
        -- Go
        gopls = {
          settings = {
            gopls = {
              analyses = {
                unusedparams = true,
                nilness = true,
                shadow = true,
                unusedwrite = true,
                useany = true,
              },
              staticcheck = true,
              gofumpt = true,
              hints = {
                assignVariableTypes = true,
                compositeLiteralFields = true,
                compositeLiteralTypes = true,
                constantValues = true,
                functionTypeParameters = true,
                parameterNames = true,
                rangeVariableTypes = true,
              },
            },
          },
        },
        
        -- Lua
        lua_ls = {
          settings = {
            Lua = {
              completion = {
                callSnippet = "Replace",
              },
              diagnostics = {
                globals = { "vim", "describe", "it", "before_each", "after_each", "lazy" },
              },
              hint = {
                enable = true,
                arrayIndex = "All",
                setType = true,
              },
              workspace = {
                checkThirdParty = false,
                library = {
                  [vim.fn.expand("$VIMRUNTIME/lua")] = true,
                  [vim.fn.expand("$VIMRUNTIME/lua/vim/lsp")] = true,
                  [vim.fn.stdpath("data") .. "/lazy/lazy.nvim/lua/lazy"] = true,
                },
                maxPreload = 5000,
                preloadFileSize = 10000,
              },
            },
          },
        },
        
        -- Configuration files
        yamlls = {
          settings = {
            yaml = {
              schemaStore = {
                enable = true,
                url = "https://www.schemastore.org/api/json/catalog.json",
              },
              schemas = {
                kubernetes = "*.{yml,yaml}",
                ["http://json.schemastore.org/github-workflow"] = ".github/workflows/*.{yml,yaml}",
                ["http://json.schemastore.org/github-action"] = ".github/action.{yml,yaml}",
                ["https://raw.githubusercontent.com/OAI/OpenAPI-Specification/main/schemas/v3.1/schema.json"] = "*api*.{yml,yaml}",
                ["https://json.schemastore.org/prettierrc.json"] = ".prettierrc.{yml,yaml}",
                ["https://json.schemastore.org/chart.json"] = "Chart.{yml,yaml}",
                ["https://json.schemastore.org/docker-compose.json"] = "docker-compose.{yml,yaml}",
              },
              format = { enable = true },
              validate = true,
              completion = true,
              hover = true,
            },
          },
        },
        
        -- Default config for all other LSP servers
        -- They will use the default settings
        tailwindcss = {},
        cssls = {},
        html = {},
        jsonls = {},
        taplo = {},  -- TOML
        marksman = {}, -- Markdown
        dockerls = {},
        terraformls = {},
        clangd = {},
      },
      
      -- Configure LSP-specific settings that apply to all servers
      setup = {
        -- For example, to customize rust-analyzer setup:
        rust_analyzer = function(_, opts)
          require("lazyvim.util").lsp.on_attach(function(client, buffer)
            -- Add any custom on_attach logic here
            if client.name == "rust_analyzer" then
              vim.keymap.set("n", "<leader>cc", function()
                vim.cmd.RustLsp("openCargo")
              end, { buffer = buffer, desc = "Open Cargo.toml" })
            end
          end)
          return true -- Continue with the default setup
        end,
      },
    },
  },
  
  -- LSP UI improvements
  {
    "nvimdev/lspsaga.nvim",
    event = "LspAttach",
    config = function()
      require("lspsaga").setup({
        lightbulb = {
          enable = true,
          sign = true,
          virtual_text = true,
        },
        ui = {
          border = "rounded",
          code_action = "💡",
        },
      })
    end,
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
  },
}
