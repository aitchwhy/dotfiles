-- Conform.nvim formatter configuration for LazyVim 15.x
return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        sh = { "shfmt" },
        json = { "yq" },
        lua = { "stylua" },
        toml = { "taplo" },
        nix = { "nixfmt" },
        go = { "goimports", "gofmt" },
        rust = { "rustfmt", lsp_format = "fallback" },
        python = function(bufnr)
          if require("conform").get_formatter_info("ruff_format", bufnr).available then
            return { "ruff_format" }
          else
            return { "isort", "black" }
          end
        end,
        ["*"] = { "codespell" },
        ["_"] = { "trim_whitespace" },
      },
      formatters = {
        injected = { options = { ignore_errors = true } },
        shfmt = { prepend_args = { "-i", "2", "-ci" } },
      },
    },
  },
}
