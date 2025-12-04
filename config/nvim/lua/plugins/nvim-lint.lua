-- Linting configuration for LazyVim 15.x
return {
  {
    "mfussenegger/nvim-lint",
    opts = {
      events = { "BufWritePost", "BufReadPost", "InsertLeave" },
      linters = {
        selene = {
          condition = function(ctx)
            return vim.fs.find({ "selene.toml" }, { path = ctx.filename, upward = true })[1]
          end,
        },
        eslint_d = {
          condition = function(ctx)
            return vim.fs.find({ "eslint.config.js", ".eslintrc.js", ".eslintrc.json" }, { path = ctx.filename, upward = true })[1]
          end,
        },
        ruff = {
          condition = function(ctx)
            return vim.fs.find({ "pyproject.toml", "ruff.toml" }, { path = ctx.filename, upward = true })[1]
          end,
        },
      },
      linters_by_ft = {
        fish = { "fish" },
        lua = { "selene" },
        python = { "ruff" },
        javascript = { "eslint_d" },
        typescript = { "eslint_d" },
        javascriptreact = { "eslint_d" },
        typescriptreact = { "eslint_d" },
        markdown = { "markdownlint" },
        yaml = { "yamllint" },
        dockerfile = { "hadolint" },
        nix = { "statix" },
      },
    },
  },
}
