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
        biome = {
          condition = function(ctx)
            return vim.fs.find({ "biome.json", "biome.jsonc" }, { path = ctx.filename, upward = true })[1]
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
        -- Biome for JS/TS ecosystem (replaces eslint_d)
        javascript = { "biome" },
        typescript = { "biome" },
        javascriptreact = { "biome" },
        typescriptreact = { "biome" },
        json = { "biome" },
        jsonc = { "biome" },
        -- Other languages
        markdown = { "markdownlint" },
        yaml = { "yamllint" },
        dockerfile = { "hadolint" },
        nix = { "statix" },
      },
    },
  },
}
