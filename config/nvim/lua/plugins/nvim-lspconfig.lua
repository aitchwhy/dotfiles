return {
  -- add pyright to lspconfig
  {
    "neovim/nvim-lspconfig",
    dependencies = { 'saghen/blink.cmp' },
    ---@class PluginLspOpts
    opts = {
      ---@type lspconfig.options
      ---@  -- make sure mason installs the server

      servers = {
        -- pyright will be automatically installed with mason and loaded with lspconfig
        pyright = {},
        lua_ls = {},
        --- @deprecated -- tsserver renamed to ts_ls but not yet released, so keep this for now
        --- the proper approach is to check the nvim-lspconfig release version when it's released to determine the server name dynamically
        tsserver = {
          enabled = false,
        },
        ts_ls = {
          enabled = false,
        },
        vtsls = {},
        tailwindcss = {},
        html = {},
        cssls = {},
        jsonls = {},
        clangd = {},
        gopls = {},
        pylyzer = {},
        ruff_lsp = {},
        ruff_d = {},
        -- Add other servers here
        eslint = {
          settings = {
            -- helps eslint find the eslintrc when it's placed in a subfolder instead of the cwd root
            workingDirectories = { mode = "auto" },
            format = auto_format,
          },
        },
      },
    },
  },
  setup = {
    eslint = function()
      if not auto_format then
        return
      end

      local function get_client(buf)
        return LazyVim.lsp.get_clients({ name = "eslint", bufnr = buf })[1]
      end

      local formatter = LazyVim.lsp.formatter({
        name = "eslint: lsp",
        primary = false,
        priority = 200,
        filter = "eslint",
      })

      -- Use EslintFixAll on Neovim < 0.10.0
      if not pcall(require, "vim.lsp._dynamic") then
        formatter.name = "eslint: EslintFixAll"
        formatter.sources = function(buf)
          local client = get_client(buf)
          return client and { "eslint" } or {}
        end
        formatter.format = function(buf)
          local client = get_client(buf)
          if client then
            local diag = vim.diagnostic.get(buf, { namespace = vim.lsp.diagnostic.get_namespace(client.id) })
            if #diag > 0 then
              vim.cmd("EslintFixAll")
            end
          end
        end
      end

      -- register the formatter with LazyVim
      LazyVim.format.register(formatter)
    end,
  },
}
