-----------------------------------------------------------------------------------
-- LSP CONFIGURATION - LANGUAGE SERVER PROTOCOL CLIENTS
-----------------------------------------------------------------------------------
-- This file configures the LSP clients for various programming languages
-- Documentation: https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md
return {
    {
        "nvim-lspconfig",
        dependencies = {
            -- TypeScript language server integration
            "jose-elias-alvarez/typescript.nvim",
            init = function()
                local LazyVim = require("lazyvim.util")

                -- Add TypeScript-specific keymaps
                LazyVim.lsp.on_attach(function(_, buffer)
                    -- stylua: ignore
                    vim.keymap.set("n", "<leader>co", "TypescriptOrganizeImports",
                        { buffer = buffer, desc = "Organize Imports" })
                    vim.keymap.set("n", "<leader>cR", "TypescriptRenameFile", { desc = "Rename File", buffer = buffer })
                end)
            end,
        },
        
        ---@class PluginLspOpts
        opts = {
            -- Servers that Mason will install and configure
            servers = {
                ---------------------------------
                -- TYPESCRIPT SERVER CONFIGURATION
                ---------------------------------

                --- @deprecated -- tsserver renamed to ts_ls but not yet released
                --- the proper approach is to check the nvim-lspconfig release version when it's released
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
                                variableTypes = { enabled = false },
                            },
                        },
                    },
                    -- TypeScript-specific keymaps
                    keys = {
                        -- Go to source definition (TypeScript-specific)
                        {
                            "gD",
                            function()
                                local LazyVim = require("lazyvim.util")
                                local params = vim.lsp.util.make_position_params()
                                LazyVim.lsp.execute({
                                    command = "typescript.goToSourceDefinition",
                                    arguments = { params.textDocument.uri, params.position },
                                    open = true,
                                })
                            end,
                            desc = "Goto Source Definition",
                        },
                        -- Find all file references
                        {
                            "gR",
                            function()
                                local LazyVim = require("lazyvim.util")
                                LazyVim.lsp.execute({
                                    command = "typescript.findAllFileReferences",
                                    arguments = { vim.uri_from_bufnr(0) },
                                    open = true,
                                })
                            end,
                            desc = "File References",
                        },
                        -- Code action: Organize imports
                        {
                            "<leader>co",
                            function()
                                local LazyVim = require("lazyvim.util")
                                return LazyVim.lsp.action["source.organizeImports"]
                            end,
                            desc = "Organize Imports",
                        },
                        -- Code action: Add missing imports
                        {
                            "<leader>cM",
                            function()
                                local LazyVim = require("lazyvim.util")
                                return LazyVim.lsp.action["source.addMissingImports.ts"]
                            end,
                            desc = "Add missing imports",
                        },
                        -- Code action: Remove unused imports
                        {
                            "<leader>cu",
                            function()
                                local LazyVim = require("lazyvim.util")
                                return LazyVim.lsp.action["source.removeUnused.ts"]
                            end,
                            desc = "Remove unused imports",
                        },
                        -- Code action: Fix all diagnostics
                        {
                            "<leader>cD",
                            function()
                                local LazyVim = require("lazyvim.util")
                                return LazyVim.lsp.action["source.fixAll.ts"]
                            end,
                            desc = "Fix all diagnostics",
                        },
                        -- Select TypeScript version
                        {
                            "<leader>cV",
                            function()
                                local LazyVim = require("lazyvim.util")
                                LazyVim.lsp.execute({ command = "typescript.selectTypeScriptVersion" })
                            end,
                            desc = "Select TS workspace version",
                        },
                    },
                },
            },
            
            setup = {
                ---------------------------------
                -- CUSTOM SERVER CONFIGURATIONS
                ---------------------------------

                -- Disable default tsserver in favor of vtsls
                tsserver = function()
                    return true -- Skip automatic setup
                end,
                -- Disable ts_ls in favor of vtsls (future-proofing)
                ts_ls = function()
                    return true -- Skip automatic setup
                end,
                -- Setup vtsls with custom configs
                vtsls = function(_, opts)
                    local LazyVim = require("lazyvim.util")
                    -- Register custom move-to-file refactoring helper
                    LazyVim.lsp.on_attach(function(client, buffer)
                        client.commands["_typescript.moveToFileRefactoring"] = function(command, ctx)
                            ---@type string, string, lsp.Range
                            local action, uri, range = unpack(command.arguments)

                            -- Helper function to execute the move
                            local function move(newf)
                                client.request("workspace/executeCommand", {
                                    command = command.command,
                                    arguments = { action, uri, range, newf },
                                })
                            end

                            -- Get list of potential destination files
                            local fname = vim.uri_to_fname(uri)
                            client.request("workspace/executeCommand", {
                                command = "typescript.tsserverRequest",
                                arguments = {
                                    "getMoveToRefactoringFileSuggestions",
                                    {
                                        file = fname,
                                        startLine = range.start.line + 1,
                                        startOffset = range.start.character + 1,
                                        endLine = range["end"].line + 1,
                                        endOffset = range["end"].character + 1,
                                    },
                                },
                            }, function(_, result)
                                ---@type string[]
                                local files = result.body.files
                                -- Add custom new file option
                                table.insert(files, 1, "Enter new path...")
                                -- Show UI for selecting destination
                                vim.ui.select(files, {
                                    prompt = "Select move destination:",
                                    format_item = function(f)
                                        return vim.fn.fnamemodify(f, ":~:.")
                                    end,
                                }, function(f)
                                    -- Handle custom file path entry
                                    if f and f:find("^Enter new path") then
                                        vim.ui.input({
                                            prompt = "Enter move destination:",
                                            default = vim.fn.fnamemodify(fname, ":h") .. "/",
                                            completion = "file",
                                        }, function(newf)
                                            return newf and move(newf)
                                        end)
                                    elseif f then
                                        move(f)
                                    end
                                end)
                            end)
                        end
                    end, "vtsls")
                    -- Copy TypeScript settings to JavaScript for consistency
                    opts.settings.javascript =
                        vim.tbl_deep_extend("force", {}, opts.settings.typescript, opts.settings.javascript or {})
                end,
            },
        },
    },
}
