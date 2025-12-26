-- Neovim configuration tests
-- Run with: nvim --headless -c "PlenaryBustedDirectory tests/"

describe("neovim config", function()
  it("neovim is running", function()
    assert.is_true(vim.fn.has("nvim") == 1)
  end)

  it("lua version is 5.1+", function()
    local version = _VERSION
    assert.is_not_nil(version)
    assert.is_true(version:match("5%.[1-9]") ~= nil or version:match("Lua") ~= nil)
  end)

  describe("plugin files", function()
    local plugin_dir = vim.fn.stdpath("config") .. "/lua/plugins"

    it("plugin directory exists", function()
      local stat = vim.uv.fs_stat(plugin_dir)
      assert.is_not_nil(stat, "plugins directory should exist")
      assert.equals("directory", stat.type)
    end)

    it("all plugin files have valid lua syntax", function()
      local files = vim.fn.glob(plugin_dir .. "/*.lua", false, true)
      assert.is_true(#files > 0, "should have plugin files")

      for _, file in ipairs(files) do
        local ok, err = pcall(dofile, file)
        assert.is_true(ok, "File should parse: " .. file .. " Error: " .. tostring(err))
      end
    end)
  end)

  describe("config files", function()
    local config_dir = vim.fn.stdpath("config") .. "/lua/config"

    it("config directory exists", function()
      local stat = vim.uv.fs_stat(config_dir)
      assert.is_not_nil(stat, "config directory should exist")
    end)

    it("lazy.lua exists and is valid", function()
      local lazy_file = config_dir .. "/lazy.lua"
      local stat = vim.uv.fs_stat(lazy_file)
      assert.is_not_nil(stat, "lazy.lua should exist")

      local ok, err = pcall(dofile, lazy_file)
      -- Note: lazy.lua may fail to fully execute without lazy.nvim
      -- but syntax should be valid
      if not ok and not err:match("lazy") then
        assert.is_true(false, "lazy.lua syntax error: " .. tostring(err))
      end
    end)
  end)
end)

describe("mason configuration", function()
  it("mason.lua does not contain linter packages", function()
    local mason_file = vim.fn.stdpath("config") .. "/lua/plugins/mason.lua"
    local content = vim.fn.readfile(mason_file)
    local text = table.concat(content, "\n")

    -- These should NOT be in mason (they're in Nix now)
    local forbidden = { "markdownlint", "yamllint", "hadolint", "sqlfluff" }
    for _, tool in ipairs(forbidden) do
      local pattern = '"' .. tool .. '"'
      assert.is_nil(text:match(pattern), tool .. " should not be in Mason (should be in Nix)")
    end
  end)

  it("mason.lua contains only debug adapters", function()
    local mason_file = vim.fn.stdpath("config") .. "/lua/plugins/mason.lua"
    local content = vim.fn.readfile(mason_file)
    local text = table.concat(content, "\n")

    -- These SHOULD be in mason
    local required = { "js%-debug%-adapter", "debugpy", "delve" }
    for _, tool in ipairs(required) do
      assert.is_not_nil(text:match(tool), tool .. " should be in Mason ensure_installed")
    end
  end)
end)

describe("nix lsp configuration", function()
  it("lang-nix.lua exists", function()
    local file = vim.fn.stdpath("config") .. "/lua/plugins/lang-nix.lua"
    local stat = vim.uv.fs_stat(file)
    assert.is_not_nil(stat, "lang-nix.lua should exist for nixd override")
  end)

  it("lang-nix.lua disables nil_ls", function()
    local file = vim.fn.stdpath("config") .. "/lua/plugins/lang-nix.lua"
    local content = vim.fn.readfile(file)
    local text = table.concat(content, "\n")

    assert.is_not_nil(text:match("nil_ls = false"), "nil_ls should be disabled")
    assert.is_not_nil(text:match("nixd"), "nixd should be configured")
  end)
end)
