return {
  -- Modern linting
  {
    "mfussenegger/nvim-lint",
    opts = {
      -- Event to trigger linters
      events = { "BufWritePost", "BufReadPost", "InsertLeave" },
      -- LazyVim extension to easily override linter options
      -- or add custom linters.
      ---@type table<string,table>
      -- LazyVim extension to easily override linter options
      -- or add custom linters.
      ---@type table<string,table>
      linters = {
        -- -- Example of using selene only when a selene.toml file is present
        -- selene = {
        --   -- `condition` is another LazyVim extension that allows you to
        --   -- dynamically enable/disable linters based on the context.
        --   condition = function(ctx)
        --     return vim.fs.find({ "selene.toml" }, { path = ctx.filename, upward = true })[1]
        --   end,
        -- },

        -- Example of using selene only when a selene.toml file is present
        selene = {
          -- `condition` is another LazyVim extension that allows you to
          -- dynamically enable/disable linters based on the context.
          condition = function(ctx)
            return vim.fs.find({ "selene.toml" }, { path = ctx.filename, upward = true })[1]
          end,
        },
        shfmt = {
          condition = function(ctx)
            return vim.fs.find({ ".shfmt.toml" }, { path = ctx.filename, upward = true })[1]
          end,
        },
        eslint_d = {
          condition = function(ctx)
            return vim.fs.find({ "eslint.config.js" }, { path = ctx.filename, upward = true })[1]
          end,
        },
        eslint = {
          condition = function(ctx)
            return vim.fs.find({ "eslint.config.js" }, { path = ctx.filename, upward = true })[1]
          end,
        },
        prettier = {
          condition = function(ctx)
            return vim.fs.find({ ".prettierrc" }, { path = ctx.filename, upward = true })[1]
          end,
        },
        markdownlint = {
          condition = function(ctx)
            return vim.fs.find({ ".markdownlint.json" }, { path = ctx.filename, upward = true })[1]
          end,
        },
        yaml = {
          condition = function(ctx)
            return vim.fs.find({ ".yaml" }, { path = ctx.filename, upward = true })[1]
          end,
        },
        shfmt = {
          condition = function(ctx)
            return vim.fs.find({ ".shfmt.toml" }, { path = ctx.filename, upward = true })[1]
          end,
        },
        ruff = {
          condition = function(ctx)
            return vim.fs.find({ "pyproject.toml" }, { path = ctx.filename, upward = true })[1]
          end,
        },
        isort = {
          condition = function(ctx)
            return vim.fs.find({ "pyproject.toml" }, { path = ctx.filename, upward = true })[1]
          end,
        },
      },
      -- events = { "BufWritePost", "BufReadPost", "InsertLeave" },
      linters_by_ft = {
        fish = { "fish" },
        -- Use the "*" filetype to run linters on all filetypes.
        lua = { "selene" },
        python = { "ruff" },
        javascript = { "eslint_d" },
        typescript = { "eslint_d" },
        javascriptreact = { "eslint_d" },
        typescriptreact = { "eslint_d" },
        markdown = { "markdownlint" },
        yml = { "yaml" },
        yaml = { "yaml" },
        zsh = { "shfmt" },
        dockerfile = { "hadolint" },

        -- Use the "_" filetype to run linters on filetypes that don't have other linters configured.
        ["_"] = { "prettier" },
        -- ['_'] = { 'fallback linter' },
        -- ["*"] = { "dprint" },
        -- ['*'] = { 'global linter' },
      },
    },
  },
}
