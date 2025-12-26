-- Conform.nvim formatter configuration for LazyVim 15.x
return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        -- Biome for JS/TS ecosystem (replaces Prettier)
        javascript = { "biome" },
        javascriptreact = { "biome" },
        typescript = { "biome" },
        typescriptreact = { "biome" },
        json = { "biome" },
        jsonc = { "biome" },

        -- Shell
        sh = { "shfmt" },

        -- Lua
        lua = { "stylua" },

        -- Config formats
        toml = { "taplo" },
        nix = { "nixfmt" },

        -- Go
        go = { "goimports", "gofmt" },

        -- Rust
        rust = { "rustfmt", lsp_format = "fallback" },

        -- Python (ruff if available, else isort + black)
        python = function(bufnr)
          if require("conform").get_formatter_info("ruff_format", bufnr).available then
            return { "ruff_format" }
          else
            return { "isort", "black" }
          end
        end,

        -- Universal
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
