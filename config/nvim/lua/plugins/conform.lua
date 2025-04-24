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
					markdown = { "prettier", "markdownlint-cli2", "markdown-toc" },
					-- Apply to all files
					["*"] = { "trim_whitespace" }, -- Remove trailing whitespace in all files
				},
				-- The options you set here will be merged with the builtin formatters.
				-- You can also define any custom formatters here.
				---@type table<string, conform.FormatterConfigOverride|fun(bufnr: integer): nil|conform.FormatterConfigOverride>
				formatters = {
					-- # Example of using dprint only when a dprint.json file is present
					-- dprint = {
					--   condition = function(ctx)
					--     return vim.fs.find({ "dprint.json" }, { path = ctx.filename, upward = true })[1]
					--   end,
					-- },
					--
					-- # Example of using shfmt with extra args
					-- shfmt = {
					--   prepend_args = { "-i", "2", "-ci" },
					-- },
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
							"-ci" -- Switch cases indented
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

				},
			}
			return opts
		end
	},
}
