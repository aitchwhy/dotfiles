-----------------------------------------------------------------------------------
-- CONFORM.NVIM - CODE FORMATTING CONFIGURATION
-----------------------------------------------------------------------------------
-- Modern code formatter plugin with LSP integration
-- Documentation: https://github.com/stevearc/conform.nvim
-- Features:
-- * Format-on-save functionality
-- * Multiple formatter support and chaining
-- * Formatter installation via Mason
-- * LSP integration for fallback
return {
    -- Main formatter configuration
    {
        "stevearc/conform.nvim",
        optional = true, -- Make it optional so it can be disabled in certain configs
        opts = function()
            local LazyVim = require("lazyvim.util")
            
            ---@type conform.setupOpts
            local opts = {
                -----------------------------------------------------------------------------------
                -- FORMATTER DEFINITIONS BY FILETYPE
                -----------------------------------------------------------------------------------
                formatters_by_ft = {
                    -- Lua
                    lua = { "stylua" },
                    -- Shell scripts
                    fish = { "fish_indent" },
                    sh = { "shfmt" },
                    zsh = { "shfmt" },
                    -- Nix config files
                    nix = { "nixfmt" },
                    -- JavaScript/TypeScript
                    javascript = { "prettier", "prettierd", "biome" }, -- Try prettier first, fallback to biome
                    typescript = { "prettier", "prettierd", "biome" },
                    typescriptreact = { "prettier", "prettierd", "biome" },
                    javascriptreact = { "prettier", "prettierd", "biome" },
                    -- Web related languages
                    html = { "prettier" },
                    css = { "prettier" },
                    scss = { "prettier" },
                    less = { "prettier" },
                    -- Data languages
                    json = { "jsonlint" },
                    jsonc = { "jsonlint" },
                    yaml = { "yamlfix" },
                    -- Markdown
                    markdown = { "markdownlint" },
                    -- Apply to all files
                    ["*"] = { "trim_whitespace" }, -- Remove trailing whitespace in all files
                },
                -----------------------------------------------------------------------------------
                -- CUSTOM FORMATTER CONFIGURATIONS
                -----------------------------------------------------------------------------------
                -- Options to override built-in formatter configurations
                ---@type table<string, conform.FormatterConfigOverride|fun(bufnr: integer): nil|conform.FormatterConfigOverride>
                formatters = {
                    -- Configure injected filetypes formatter
                    injected = {
                        options = {
                            ignore_errors = true
                        }
                    },

                    -- Only use dprint when a config file is present
                    dprint = {
                        condition = function(ctx)
                            return vim.fs.find({ "dprint.json" }, { path = ctx.filename, upward = true })[1]
                        end,
                    },
                    -- Configure shfmt with consistent settings
                    shfmt = {
                        prepend_args = {
                            "-i", "2", -- 2 space indentation
                            "-ci"      -- Switch cases indented
                        },
                    },

                    -- Only apply markdown-toc when <!-- toc --> is present
                    ["markdown-toc"] = {
                        condition = function(_, ctx)
                            for _, line in ipairs(vim.api.nvim_buf_get_lines(ctx.buf, 0, -1, false)) do
                                if line:find("<!%-%- toc %-%->") then
                                    return true
                                end
                            end
                        end,
                    },
                    -- Only use markdownlint when there are markdownlint issues
                    ["markdownlint-cli2"] = {
                        condition = function(_, ctx)
                            local diag = vim.tbl_filter(function(d)
                                return d.source == "markdownlint"
                            end, vim.diagnostic.get(ctx.buf))
                            return #diag > 0
                        end,
                    },
                },
            }
            return opts
        end,
    },
}
