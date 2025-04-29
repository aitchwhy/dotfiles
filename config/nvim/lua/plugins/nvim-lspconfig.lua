-----------------------------------------------------------------------------------
-- LSP CONFIGURATION - LANGUAGE SERVER PROTOCOL CLIENTS
-----------------------------------------------------------------------------------
-- This file configures the LSP clients for various programming languages
-- Documentation: https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md
return {
  -- lspconfig
  {
    "neovim/nvim-lspconfig",
    dependencies = { "saghen/blink.cmp" },
    ---@class PluginLspOpts
    ---
    --- The syntax for adding, deleting and changing LSP Keymaps, is the same as for plugin keymaps, but you need to configure it using the opts() method.
    opts = {
      servers = {
        ---------------------------------
        -- TYPESCRIPT SERVER CONFIGURATION
        ---------------------------------
        eslint = {
          settings = {
            -- helps eslint find the eslintrc when it's placed in a subfolder instead of the cwd root
            workingDirectories = { mode = "auto" },
            format = "auto_format",
          },
        },
        terraformls = {},
        ruff = {
          cmd_env = { RUFF_TRACE = "messages" },
          init_options = {
            settings = {
              logLevel = "error",
            },
          },
          keys = {
            {
              "<leader>co",
              LazyVim.lsp.action["source.organizeImports"],
              desc = "Organize Imports",
            },
          },
        },
        ruff_lsp = {
          keys = {
            {
              "<leader>co",
              LazyVim.lsp.action["source.organizeImports"],
              desc = "Organize Imports",
            },
          },
        },

        --- @deprecated -- tsserver renamed to ts_ls but not yet released
        --- the proper approach is to check  ssthe nvim-lspconfig release version when it's released
        tsserver = {
          enabled = false, -- Disabled in favor of vtsls
        },
        ts_ls = {
          enabled = false, -- Disabled in favor of vtsls
        },
        -- Use vtsls (Verbose TS Language Server) instead of tsserver
        vtsls = {
          -- Define supported filetypes
          filetypes = {
            "javascript",
            "javascriptreact",
            "javascript.jsx",
            "typescript",
            "typescriptreact",
            "typescript.tsx",
          },
          -- Server configuration
          settings = {
            complete_function_calls = true,
            vtsls = {
              -- Enable move-to-file refactoring
              enableMoveToFileCodeAction = true,
              -- Automatically use local TypeScript version
              autoUseWorkspaceTsdk = true,
              experimental = {
                maxInlayHintLength = 30,
                completion = {
                  enableServerSideFuzzyMatch = true,
                },
              },
            },
            -- TypeScript-specific settings
            typescript = {
              updateImportsOnFileMove = { enabled = "always" },
              suggest = {
                completeFunctionCalls = true,
              },
              -- Configure inlay hints (inline type information)
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
              desc = "Goto Source Definition",
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
              desc = "File References",
            },
            {
              "<leader>co",
              LazyVim.lsp.action["source.organizeImports"],
              desc = "Organize Imports",
            },
            {
              "<leader>cM",
              LazyVim.lsp.action["source.addMissingImports.ts"],
              desc = "Add missing imports",
            },
            {
              "<leader>cu",
              LazyVim.lsp.action["source.removeUnused.ts"],
              desc = "Remove unused imports",
            },
            {
              "<leader>cD",
              LazyVim.lsp.action["source.fixAll.ts"],
              desc = "Fix all diagnostics",
            },
            {
              "<leader>cV",
              function()
                LazyVim.lsp.execute({ command = "typescript.selectTypeScriptVersion" })
              end,
              desc = "Select TS workspace version",
            },
          },
        },

        nil_ls = {},
        marksman = {},
      },
    },
    config = function(_, opts)
      local lspconfig = require("lspconfig")
      for server, config in pairs(opts.servers) do
        -- passing config.capabilities to blink.cmp merges with the capabilities in your
        -- `opts[server].capabilities, if you've defined it
        config.capabilities = require("blink.cmp").get_lsp_capabilities(config.capabilities)
        lspconfig[server].setup(config)
      end
    end,
  },
}
