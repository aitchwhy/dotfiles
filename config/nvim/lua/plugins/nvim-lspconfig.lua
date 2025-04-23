-- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md
return {
    {
        "nvim-lspconfig",
        dependencies = {
            "jose-elias-alvarez/typescript.nvim",
            init = function()
                require("lazyvim.util").lsp.on_attach(function(_, buffer)
                    -- stylua: ignore
                    vim.keymap.set("n", "<leader>co", "TypescriptOrganizeImports",
                        { buffer = buffer, desc = "Organize Imports" })
                    vim.keymap.set("n", "<leader>cR", "TypescriptRenameFile", { desc = "Rename File", buffer = buffer })
                end)
            end,
        },
        ---@class PluginLspOpts
        opts = {
            -- If your project is using eslint with eslint-plugin-prettier, then this will automatically fix eslint errors and format with prettier on save. Important: make sure not to add prettier to null-ls, otherwise this won't work!
            servers = {
                --- @deprecated -- tsserver renamed to ts_ls but not yet released, so keep this for now
                --- the proper approach is to check the nvim-lspconfig release version when it's released to determine the server name dynamically
                tsserver = {
                    enabled = false,
                },
                ts_ls = {
                    enabled = false,
                },
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
                vtsls = {
                    -- explicitly add default filetypes, so that we can extend
                    -- them in related extras
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
                            suggest = {
                                completeFunctionCalls = true,
                            },
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
            },
            --- @deprecated -- tsserver renamed to ts_ls but not yet released, so keep this for now
            --- the proper approach is to check the nvim-lspconfig release version when it's released to determine the server name dynamically
            tsserver = function()
                -- disable tsserver
                return true
            end,
            ts_ls = function()
                -- disable tsserver
                return true
            end,
            vtsls = function(_, opts)
                LazyVim.lsp.on_attach(function(client, buffer)
                    client.commands["_typescript.moveToFileRefactoring"] = function(command, ctx)
                        ---@type string, string, lsp.Range
                        local action, uri, range = unpack(command.arguments)

                        local function move(newf)
                            client.request("workspace/executeCommand", {
                                command = command.command,
                                arguments = { action, uri, range, newf },
                            })
                        end

                        local fvim.uri_to_fname(uri)
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
                            table.insert(files, 1, "Enter new path...")
                            vim.ui.select(files, {
                                prompt = "Select move destination:",
                                format_item = function(f)
                                    return vim.fn.fnamemodify(f, ":~:.")
                                end,
                            }, function(f)
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
                -- copy typescript settings to javascript
                opts.settings.javascript =
                    vim.tbl_deep_extend("force", {}, opts.settings.typescript, opts.settings.javascript or {})
            end,
            eslint = {
                settings = {
                    -- helps eslint find the eslintrc when it's placed in a subfolder instead of the cwd root
                    workingDirectories = { mode = "auto" },
                    format = "auto_format",
                },
            },
            nil_ls = {},
            marksman = {},
            yamlls = {
                -- Have to add this for yamlls to understand that we support line folding
                capabilities = {
                    textDocument = {
                        foldingRange = {
                            dynamicRegistration = false,
                            lineFoldingOnly = true,
                        },
                    },
                },
                -- lazy-load schemastore when needed
                on_new_config = function(new_config)
                    new_config.settings.yaml.schemas = vim.tbl_deep_extend(
                        "force",
                        new_config.settings.yaml.schemas or {},
                        require("schemastore").yaml.schemas()
                    )
                end,
                settings = {
                    redhat = { telemetry = { enabled = false } },
                    yaml = {
                        keyOrdering = false,
                        format = {
                            enable = true,
                        },
                        validate = true,
                        schemaStore = {
                            -- Must disable built-in schemaStore support to use
                            -- schemas from SchemaStore.nvim plugin
                            enable = false,
                            -- Avoid TypeError: Cannot read properties of undefined (reading 'length')
                            url = "",
                        },
                    },
                },
            },
            jsonls = {
                -- lazy-load schemastore when needed
                on_new_config = function(new_config)
                    new_config.settings.json.schemas = new_config.settings.json.schemas or {}
                    vim.list_extend(new_config.settings.json.schemas, require("schemastore").json.schemas())
                end,
                settings = {
                    json = {
                        format = {
                            enable = true,
                        },
                        validate = { enable = true },
                    },
                },
            },
        },
        setup = {
            [ruff] = function()
                LazyVim.lsp.on_attach(function(client, _)
                    -- Disable hover in favor of Pyright
                    client.server_capabilities.hoverProvider = false
                end, ruff)
            end,
            eslint = function()
                require("lazyvim.util").lsp.on_attach(function(client)
                    if client.name == "eslint" then
                        client.server_capabilities.documentFormattingProvider = true
                    elseif client.name == "tsserver" then
                        client.server_capabilities.documentFormattingProvider = false
                    end
                end)
            end,
            yamlls = function()
                -- Neovim < 0.10 does not have dynamic registration for formatting
                if vim.fn.has("nvim-0.10") == 0 then
                    LazyVim.lsp.on_attach(function(client, _)
                        client.server_capabilities.documentFormattingProvider = true
                    end, "yamlls")
                end
            end,
        },
    },
    --     ---@type lspconfig.options
    --     servers = {
    --         -- tsserver will be automatically installed with mason and loaded with lspconfig
    --         tsserver = {},
    --     },
    --     -- you can do any additional lsp server setup here
    --     -- return true if you don't want this server to be setup with lspconfig
    --     ---@type table<string, fun(server:string, opts:_.lspconfig.options):boolean?>
    --     setup = {
    --         -- example to setup with typescript.nvim
    --         tsserver = function(_, opts)
    --             require("typescript").setup({ server = opts })
    --             return true
    --         end,
    --         -- Specify * to use this function as a fallback for any server
    --         -- ["*"] = function(server, opts) end,
    -- },
    -- },
}
