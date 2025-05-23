-- ~/.config/nvim/lua/plugins/lspconfig.lua
return {
  {
    "neovim/nvim-lspconfig",
    -- Load when a buffer with a language server–handled file is opened:
    -- event = { "BufReadPre", "BufNewFile" },

    -- blink.cmp integration (for capabilities):
    dependencies = {
      "saghen/blink.cmp",
    },

    -- Pure map of server → config
    ---@class PluginLspOpts
    opts = {
      ---@type lspconfig.options
      servers = {
        -- ---------------------------------------------------------------------
        -- ESLINT SERVER (provides diagnostics + code actions)
        -- ---------------------------------------------------------------------
        eslint = {
          settings = {
            workingDirectories = { mode = "auto" },
            format = "auto_format",
          },
        },

        -- ---------------------------------------------------------------------
        -- TERRAFORMLS
        -- ---------------------------------------------------------------------
        terraformls = {},

        -- ---------------------------------------------------------------------
        -- RUFF (linter + code actions)
        -- ---------------------------------------------------------------------
        ruff = {
          cmd_env = { RUFF_TRACE = "messages" },
          init_options = {
            settings = { logLevel = "error" },
          },

          -- Example: override / add keymaps for this server
          keys = {
            {
              "<leader>co",
              LazyVim.lsp.action["source.organizeImports"],
              desc = "ESLint: Organize Imports",
            },
          },
        },

        -- ---------------------------------------------------------------------
        -- RUFF_LSP (alternative entrypoint)
        -- ---------------------------------------------------------------------
        ruff_lsp = {
          keys = {
            {
              "<leader>co",
              LazyVim.lsp.action["source.organizeImports"],
              desc = "Ruff LSP: Organize Imports",
            },
          },
        },

        -- ---------------------------------------------------------------------
        -- TYPESCRIPT FAMILY
        -- ---------------------------------------------------------------------
        -- we disable the built-in `tsserver`/`ts_ls` in favor of vtsls:
        tsserver = { enabled = false },
        ts_ls = { enabled = false },

        vtsls = {
          filetypes = {
            "javascript",
            "javascriptreact",
            "javascript.jsx",
            "typescript",
            "typescriptreact",
            "typescript.tsx",
          },
          settings = {
            complete_function_calls = true,
            vtsls = {
              enableMoveToFileCodeAction = true,
              autoUseWorkspaceTsdk = true,
              experimental = {
                maxInlayHintLength = 30,
                completion = {
                  enableServerSideFuzzyMatch = true,
                },
              },
            },
            typescript = {
              updateImportsOnFileMove = { enabled = "always" },
              suggest = { completeFunctionCalls = true },
              inlayHints = {
                enumMemberValues = { enabled = true },
                functionLikeReturnTypes = { enabled = true },
                parameterNames = { enabled = "literals" },
                parameterTypes = { enabled = true },
                propertyDeclarationTypes = { enabled = true },
                variableTypes = { enabled = true },
              },
            },
          },
          keys = {
            {
              "gD",
              function()
                local params = vim.lsp.util.make_position_params()
                LazyVim.lsp.execute({
                  command = "typescript.goToSourceDefinition",
                  arguments = { params.textDocument.uri, params.position },
                  open = true,
                })
              end,
              desc = "TS: Go To Source Definition",
            },
            {
              "gR",
              function()
                LazyVim.lsp.execute({
                  command = "typescript.findAllFileReferences",
                  arguments = { vim.uri_from_bufnr(0) },
                  open = true,
                })
              end,
              desc = "TS: File References",
            },
            {
              "<leader>co",
              LazyVim.lsp.action["source.organizeImports"],
              desc = "TS: Organize Imports",
            },
            {
              "<leader>cM",
              LazyVim.lsp.action["source.addMissingImports.ts"],
              desc = "TS: Add Missing Imports",
            },
            {
              "<leader>cu",
              LazyVim.lsp.action["source.removeUnused.ts"],
              desc = "TS: Remove Unused Imports",
            },
            {
              "<leader>cD",
              LazyVim.lsp.action["source.fixAll.ts"],
              desc = "TS: Fix All Diagnostics",
            },
            {
              "<leader>cV",
              function()
                LazyVim.lsp.execute({ command = "typescript.selectTypeScriptVersion" })
              end,
              desc = "TS: Select Workspace TS Version",
            },
          },
        },

        -- ---------------------------------------------------------------------
        -- NIL-LS (formatting + diagnostics for various languages)
        -- ---------------------------------------------------------------------
        nil_ls = {},

        -- ---------------------------------------------------------------------
        -- MARKSMAN (Markdown LSP)
        -- ---------------------------------------------------------------------
        marksman = {},
      },
      -- you can do any additional lsp server setup here
      -- return true if you don't want this server to be setup with lspconfig
      ---@type table<string, fun(server:string, opts:_.lspconfig.options):boolean?>
      setup = {
        -- example to setup with typescript.nvim
        tsserver = function(_, opts)
          require("typescript").setup({ server = opts })
          return true
        end,
        -- Specify * to use this function as a fallback for any server
        -- ["*"] = function(server, opts) end,
        --
      },
    },

    -- -- Merge blink.cmp capabilities & setup each server
    -- config = function(_, opts)
    --   local lspconfig = require("lspconfig")
    --
    --   for server, cfg in pairs(opts.servers) do
    --     if cfg.enabled == false then
    --       -- skip disabled servers
    --     else
    --       cfg.capabilities = require("blink.cmp").get_lsp_capabilities(cfg.capabilities)
    --       lspconfig[server].setup(cfg)
    --     end
    --   end
    -- end,
  },
}

-- -----------------------------------------------------------------------------------
-- -- LSP CONFIGURATION - LANGUAGE SERVER PROTOCOL CLIENTS
-- -----------------------------------------------------------------------------------
-- -- This file configures the LSP clients for various programming languages
-- -- Documentation: https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md
-- return {
--   -- lspconfig
--   {
--     "neovim/nvim-lspconfig",
--     dependencies = { "saghen/blink.cmp" },
--     ---@class PluginLspOpts
--     ---
--     --- The syntax for adding, deleting and changing LSP Keymaps, is the same as for plugin keymaps, but you need to configure it using the opts() method.
--     opts = {
--       servers = {
--         ---------------------------------
--         -- TYPESCRIPT SERVER CONFIGURATION
--         ---------------------------------
--         eslint = {
--           settings = {
--             -- helps eslint find the eslintrc when it's placed in a subfolder instead of the cwd root
--             workingDirectories = { mode = "auto" },
--             format = "auto_format",
--           },
--         },
--         terraformls = {},
--         ruff = {
--           cmd_env = { RUFF_TRACE = "messages" },
--           init_options = {
--             settings = {
--               logLevel = "error",
--             },
--           },
--           keys = {
--             {
--               "<leader>co",
--               LazyVim.lsp.action["source.organizeImports"],
--               desc = "Organize Imports",
--             },
--           },
--         },
--         ruff_lsp = {
--           keys = {
--             {
--               "<leader>co",
--               LazyVim.lsp.action["source.organizeImports"],
--               desc = "Organize Imports",
--             },
--           },
--         },
--
--         --- @deprecated -- tsserver renamed to ts_ls but not yet released
--         --- the proper approach is to check  ssthe nvim-lspconfig release version when it's released
--         tsserver = {
--           enabled = false, -- Disabled in favor of vtsls
--         },
--         ts_ls = {
--           enabled = false, -- Disabled in favor of vtsls
--         },
--         -- Use vtsls (Verbose TS Language Server) instead of tsserver
--         vtsls = {
--           -- Define supported filetypes
--           filetypes = {
--             "javascript",
--             "javascriptreact",
--             "javascript.jsx",
--             "typescript",
--             "typescriptreact",
--             "typescript.tsx",
--           },
--           -- Server configuration
--           settings = {
--             complete_function_calls = true,
--             vtsls = {
--               -- Enable move-to-file refactoring
--               enableMoveToFileCodeAction = true,
--               -- Automatically use local TypeScript version
--               autoUseWorkspaceTsdk = true,
--               experimental = {
--                 maxInlayHintLength = 30,
--                 completion = {
--                   enableServerSideFuzzyMatch = true,
--                 },
--               },
--             },
--             -- TypeScript-specific settings
--             typescript = {
--               updateImportsOnFileMove = { enabled = "always" },
--               suggest = {
--                 completeFunctionCalls = true,
--               },
--               -- Configure inlay hints (inline type information)
--               inlayHints = {
--                 enumMemberValues = { enabled = true },
--                 functionLikeReturnTypes = { enabled = true },
--                 parameterNames = { enabled = "literals" },
--                 parameterTypes = { enabled = true },
--                 propertyDeclarationTypes = { enabled = true },
--                 variableTypes = { enabled = true },
--               },
--             },
--           },
--           keys = {
--             {
--               "gD",
--               function()
--                 local params = vim.lsp.util.make_position_params()
--                 LazyVim.lsp.execute({
--                   command = "typescript.goToSourceDefinition",
--                   arguments = { params.textDocument.uri, params.position },
--                   open = true,
--                 })
--               end,
--               desc = "Goto Source Definition",
--             },
--             {
--               "gR",
--               function()
--                 LazyVim.lsp.execute({
--                   command = "typescript.findAllFileReferences",
--                   arguments = { vim.uri_from_bufnr(0) },
--                   open = true,
--                 })
--               end,
--               desc = "File References",
--             },
--             {
--               "<leader>co",
--               LazyVim.lsp.action["source.organizeImports"],
--               desc = "Organize Imports",
--             },
--             {
--               "<leader>cM",
--               LazyVim.lsp.action["source.addMissingImports.ts"],
--               desc = "Add missing imports",
--             },
--             {
--               "<leader>cu",
--               LazyVim.lsp.action["source.removeUnused.ts"],
--               desc = "Remove unused imports",
--             },
--             {
--               "<leader>cD",
--               LazyVim.lsp.action["source.fixAll.ts"],
--               desc = "Fix all diagnostics",
--             },
--             {
--               "<leader>cV",
--               function()
--                 LazyVim.lsp.execute({ command = "typescript.selectTypeScriptVersion" })
--               end,
--               desc = "Select TS workspace version",
--             },
--           },
--         },
--
--         nil_ls = {},
--         marksman = {},
--       },
--     },
--     config = function(_, opts)
--       local lspconfig = require("lspconfig")
--       for server, config in pairs(opts.servers) do
--         -- passing config.capabilities to blink.cmp merges with the capabilities in your
--         -- `opts[server].capabilities, if you've defined it
--         config.capabilities = require("blink.cmp").get_lsp_capabilities(config.capabilities)
--         lspconfig[server].setup(config)
--       end
--     end,
--   },
-- }
