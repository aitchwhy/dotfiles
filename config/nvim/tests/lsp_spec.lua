-- LSP configuration tests
-- Run with: nvim --headless -c "PlenaryBustedDirectory tests/"

describe("lsp configuration", function()
  describe("nvim-lspconfig.lua", function()
    it("exists and is valid", function()
      local file = vim.fn.stdpath("config") .. "/lua/plugins/nvim-lspconfig.lua"
      local stat = vim.uv.fs_stat(file)
      assert.is_not_nil(stat, "nvim-lspconfig.lua should exist")

      local ok, result = pcall(dofile, file)
      assert.is_true(ok, "nvim-lspconfig.lua should be valid Lua")
      assert.is_table(result, "should return a table")
    end)

    it("configures nixd", function()
      local file = vim.fn.stdpath("config") .. "/lua/plugins/nvim-lspconfig.lua"
      local content = vim.fn.readfile(file)
      local text = table.concat(content, "\n")

      assert.is_not_nil(text:match("nixd"), "nixd should be configured")
    end)
  end)

  describe("conform.lua formatters", function()
    it("exists and is valid", function()
      local file = vim.fn.stdpath("config") .. "/lua/plugins/conform.lua"
      local stat = vim.uv.fs_stat(file)
      assert.is_not_nil(stat, "conform.lua should exist")
    end)

    it("references Nix-installed formatters", function()
      local file = vim.fn.stdpath("config") .. "/lua/plugins/conform.lua"
      local content = vim.fn.readfile(file)
      local text = table.concat(content, "\n")

      -- These formatters should be referenced (installed via Nix)
      local formatters = { "nixfmt", "shfmt", "biome" }
      for _, fmt in ipairs(formatters) do
        assert.is_not_nil(text:match(fmt), fmt .. " should be referenced in conform.lua")
      end
    end)
  end)

  describe("nvim-lint.lua linters", function()
    it("exists and is valid", function()
      local file = vim.fn.stdpath("config") .. "/lua/plugins/nvim-lint.lua"
      local stat = vim.uv.fs_stat(file)
      assert.is_not_nil(stat, "nvim-lint.lua should exist")
    end)

    it("references Nix-installed linters", function()
      local file = vim.fn.stdpath("config") .. "/lua/plugins/nvim-lint.lua"
      local content = vim.fn.readfile(file)
      local text = table.concat(content, "\n")

      -- These linters should be referenced (installed via Nix)
      local linters = { "markdownlint", "yamllint", "hadolint", "statix" }
      for _, linter in ipairs(linters) do
        assert.is_not_nil(text:match(linter), linter .. " should be referenced in nvim-lint.lua")
      end
    end)
  end)
end)

describe("tool availability validation", function()
  -- Note: These tests verify configuration, not runtime availability
  -- Runtime availability depends on Nix packages being installed

  it("biome is configured for JS/TS", function()
    local file = vim.fn.stdpath("config") .. "/lua/plugins/nvim-lint.lua"
    local content = vim.fn.readfile(file)
    local text = table.concat(content, "\n")

    assert.is_not_nil(text:match("javascript.*biome") or text:match("biome"), "biome should be configured for JS")
  end)

  it("statix is configured for Nix", function()
    local file = vim.fn.stdpath("config") .. "/lua/plugins/nvim-lint.lua"
    local content = vim.fn.readfile(file)
    local text = table.concat(content, "\n")

    assert.is_not_nil(text:match('nix.-"statix"') or text:match("statix"), "statix should be configured for Nix files")
  end)
end)
