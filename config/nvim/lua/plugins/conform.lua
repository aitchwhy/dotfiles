return {
    -- Modern code formatter
    {
        name = "conform-nvim",
        opts = function()
            local plugin = require("lazy.core.config").plugins["conform.nvim"]
            if plugin.config ~= M.setup then
                LazyVim.error({
                    "Don't set `plugin.config` for `conform.nvim`.\n",
                    "This will break **LazyVim** formatting.\n",
                    "Please refer to the docs at https://www.lazyvim.org/plugins/formatting",
                }, { title = "LazyVim" })
            end
            ---@type conform.setupOpts
            local opts = {
                default_format_opts = {
                    timeout_ms = 3000,
                    async = false, -- not recommended to change
                    quiet = false, -- not recommended to change
                    lsp_format = "fallback", -- not recommended to change
                },
                formatters_by_ft = {
                    -- ["markdown"] = { "prettier", "markdownlint-cli2", "markdown-toc" },
                    -- ["markdown.mdx"] = { "prettier", "markdownlint-cli2", "markdown-toc" },
                    lua = { "stylua" },
                    fish = { "fish_indent" },
                    sh = { "shfmt" },
                    zsh = { "shfmt" },
                    nix = { "nixfmt" },
                    ts = { "prettier", "prettierd", "biome" },
                    javascript = { "prettier", "prettierd", "biome" },
                    typescriptreact = { "prettier", "prettierd", "biome" },
                    javascriptreact = { "prettier", "prettierd", "biome" },
                    html = { "prettier" },
                    css = { "prettier" },
                    scss = { "prettier" },
                    less = { "prettier" },
                    json = { "jsonlint" },
                    jsonc = { "jsonlint" },
                    yaml = { "yamlfix" },
                    markdown = { "markdownlint" },
                },
                -- The options you set here will be merged with the builtin formatters.
                -- You can also define any custom formatters here.
                ---@type table<string, conform.FormatterConfigOverride|fun(bufnr: integer): nil|conform.FormatterConfigOverride>
                formatters = {
                    injected = { options = { ignore_errors = true } },
                    -- # Example of using dprint only when a dprint.json file is present
                    dprint = {
                        condition = function(ctx)
                            return vim.fs.find({ "dprint.json" }, { path = ctx.filename, upward = true })[1]
                        end,
                    },

                    -- # Example of using shfmt with extra args
                    shfmt = {
                        prepend_args = { "-i", "2", "-ci" },
                    },
                    ["markdown-toc"] = {
                        condition = function(_, ctx)
                            for _, line in ipairs(vim.api.nvim_buf_get_lines(ctx.buf, 0, -1, false)) do
                                if line:find("<!%-%- toc %-%->") then
                                    return true
                                end
                            end
                        end,
                    },
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
    -- --
    --   {
    --       name = "stevearc/conform.nvim",
    --       event = { "BufWritePre" }, -- Load before writing buffer
    --       cmd = { "ConformInfo" }, -- Also load on ConformInfo command
    --       keys = {
    --           {
    --               -- Format with <leader>f
    --               "<leader>f",
    --               function()
    --                   require("conform").format({ async = true, lsp_fallback = true })
    --               end,
    --               desc = "Format buffer",
    --           },
    --           {
    --               -- Format with <leader>F and choose formatter
    --               "<leader>F",
    --               function()
    --                   require("conform").format({
    --                       async = true,
    --                       lsp_fallback = true,
    --                       formatters_by_ft = {
    --                           lua = { "stylua" },
    --                           python = { "ruff_format", "black" },
    --                           javascript = { "prettier", "prettierd", "biome" },
    --                           typescript = { "prettier", "prettierd", "biome" },
    --                           -- Add any other specific formatter overrides here
    --                       },
    --                       timeout_ms = 3000,
    --                   })
    --               end,
    --               desc = "Format buffer with options",
    --           },
    --       },
    --       --
    --       -- -- Formatter configuration
    --       -- opts = {
    --       --   -- Define formatting options
    --       --   -- format_on_save = function(bufnr)
    --       --   --   -- Don't format on save for certain files or if file is too large
    --       --   --   local bufname = vim.api.nvim_buf_get_name(bufnr)
    --       --   --   local file_size = vim.fn.getfsize(bufname)
    --       --
    --       --   --   -- Skip minified files or files larger than 500KB
    --       --   --   if bufname:match("%.min%.[^.]+$") or (file_size > 500 * 1024) then
    --       --   --     return
    --       --   --   end
    --       --
    --       --   --   return {
    --       --   --     timeout_ms = 500,      -- 500ms timeout for formatting
    --       --   --     lsp_fallback = true,   -- Use LSP formatting if formatter not available
    --       --   --   }
    --       --   -- end,
    --       --
    --       --   -- Formatter setup by filetype
    --       --   formatters_by_ft = {
    --       --     -- Lua
    --       --     lua = { "stylua" },
    --       --
    --       --     -- -- Web Technologies
    --       --     -- javascript = { "prettier", "biome" },
    --       --     -- typescript = { "prettier", "biome" },
    --       --     -- javascriptreact = { "prettier", "biome" },
    --       --     -- typescriptreact = { "prettier", "biome" },
    --       --     -- svelte = { "prettier" },
    --       --     -- vue = { "prettier" },
    --       --     -- css = { "prettier" },
    --       --     -- scss = { "prettier" },
    --       --     -- less = { "prettier" },
    --       --     -- html = { "prettier" },
    --       --     -- json = { "prettier", "biome" },
    --       --     -- jsonc = { "prettier", "biome" },
    --       --     -- yaml = { "prettier" },
    --       --     -- markdown = { "prettier" },
    --       --     -- graphql = { "prettier" },
    --       --
    --       --     -- -- Python
    --       --     -- python = { "ruff_format", "black" },
    --       --
    --       --     -- -- Go
    --       --     -- go = { "gofumpt", "goimports" },
    --       --
    --       --     -- -- Rust
    --       --     -- rust = { "rustfmt" },
    --       --
    --       --     -- -- Ruby
    --       --     -- ruby = { "rubyfmt" },
    --       --
    --       --     -- -- Shell
    --       --     -- sh = { "shfmt" },
    --       --     -- bash = { "shfmt" },
    --       --     -- zsh = { "shfmt" },
    --       --
    --       --     -- -- C/C++
    --       --     -- c = { "clang_format" },
    --       --     -- cpp = { "clang_format" },
    --       --
    --       --     -- -- Java
    --       --     -- java = { "google-java-format" },
    --       --
    --       --     -- -- Special file types
    --       --     -- nix = { "nixpkgs_fmt" },
    --       --     -- toml = { "taplo" },
    --       --     -- dockerfile = { "hadolint" },
    --       --
    --       --     -- Apply to all files
    --       --     ["*"] = { "trim_whitespace", "trim_newlines", "squeeze_blanks" },
    --       --   },
    --       --
    --       --   -- Customize formatter options
    --       --   formatters = {
    --       --     -- Configure specific formatter options
    --       --     prettier = {
    --       --       -- Use prefer local project version of prettier
    --       --       prepend_args = { "--config-precedence", "prefer-file" },
    --       --     },
    --       --
    --       --     -- Shell formatting with 2 space indentation
    --       --     shfmt = {
    --       --       prepend_args = { "-i", "2", "-ci" },
    --       --     },
    --       --
    --       --     -- Black with line length of 88
    --       --     black = {
    --       --       prepend_args = { "--line-length", "88" },
    --       --     },
    --       --
    --       --     -- Stylua with config from project
    --       --     stylua = {
    --       --       prepend_args = function()
    --       --         local root = require("conform.util").root_file({ ".stylua.toml", "stylua.toml" })
    --       --         if root then
    --       --           return { "--config-path", root }
    --       --         end
    --       --         return {}
    --       --       end,
    --       --     },
    --       --   },
    --       --
    --       --   -- Support for multiple formatters
    --       --   format_after_save = {
    --       --     lsp_fallback = true,
    --       --   },
    --       --
    --       --   -- Notify on formatting errors
    --       --   notify_on_error = true,
    --   },
    --   --
    --   --   -- Initialize and load the plugin
    --   --   init = function()
    --   --     -- Register the ConformAutoFormat command
    --   --     vim.api.nvim_create_user_command("ConformAutoFormat", function(args)
    --   --       local conform = require("conform")
    --   --       local range = nil
    --   --       if args.range > 0 then
    --   --         range = {
    --   --           start = { args.line1, 0 },
    --   --           ["end"] = { args.line2, 999999 },
    --   --         }
    --   --       end
    --   --       conform.format({ async = true, lsp_fallback = true, range = range })
    --   --     end, { range = true })
    --   --   end,
}
