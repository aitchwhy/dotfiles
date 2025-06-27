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
    ---@type conform.setupOpts
    opts = {
      formatters_by_ft = {
        sh = { "shfmt" },
        json = { "yq" },
        lua = { "stylua" },
        toml = { "taplo" },
        nix = { "nixfmt" },
        -- Conform will run multiple formatters sequentially
        go = { "goimports", "gofmt" },
        -- You can also customize some of the format options for the filetype
        rust = { "rustfmt", lsp_format = "fallback" },
        -- You can use a function here to determine the formatters dynamically
        python = function(bufnr)
          if require("conform").get_formatter_info("ruff_format", bufnr).available then
            return { "ruff_format" }
          else
            return { "isort", "black" }
          end
        end,
        -- Use the "*" filetype to run formatters on all filetypes.
        ["*"] = { "codespell" },
        -- Use the "_" filetype to run formatters on filetypes that don't
        -- have other formatters configured.
        ["_"] = { "trim_whitespace" },
      },
      formatters = {
        injected = { options = { ignore_errors = true } },
        -- # Example of using dprint only when a dprint.json file is present
        -- dprint = {
        --   condition = function(ctx)
        --     return vim.fs.find({ "dprint.json" }, { path = ctx.filename, upward = true })[1]
        --   end,
        -- },
        --
        -- # Example of using shfmt with extra args
        shfmt = {
          prepend_args = { "-i", "2", "-ci" },
        },
        yq = {},
        taplo = {},
        nixfmt = {},
        goimports = {},
        gofmt = {},
        rustfmt = {},
        isort = {},
        black = {},
        stylua = {},
        ruff = {},
      },
    },
  },
}
