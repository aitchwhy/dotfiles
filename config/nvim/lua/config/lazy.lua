local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out,                            "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- -- vscode-neovim
-- if vim.g.vscode then
--   -- VSCode extension
--   print("[vim.g.vscode = TRUE] VSCODE")
-- else
--   -- ordinary Neovim
--   print("[vim.g.vscode = FALSE] NEOVIM")
-- end

require("lazy").setup({
  -- Store lockfile in writable location (config dir is managed by Nix)
  lockfile = vim.fn.stdpath("data") .. "/lazy-lock.json",
  spec = {
    -- add LazyVim and import its plugins
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },

    -- Dev essentials extras
    { import = "lazyvim.plugins.extras.coding.blink" },
    -- FZF replaced by Snacks.picker
    -- { import = "lazyvim.plugins.extras.editor.fzf" },
    { import = "lazyvim.plugins.extras.ai.copilot" },

    -- Language support
    { import = "lazyvim.plugins.extras.lang.typescript" },
    { import = "lazyvim.plugins.extras.lang.python" },
    { import = "lazyvim.plugins.extras.lang.go" },
    { import = "lazyvim.plugins.extras.lang.rust" },
    { import = "lazyvim.plugins.extras.lang.nix" },

    -- import/override with your plugins
    { import = "plugins" },
  },
  defaults = {
    -- Enabling lazy-loading for custom plugins to improve startup performance
    lazy = true,
    -- It's recommended to leave version=false for now, since a lot the plugin that support versioning,
    -- have outdated releases, which may break your Neovim install.
    version = false, -- always use the latest git commit
    -- version = "*", -- try installing the latest stable version for plugins that support semver
  },
  install = { colorscheme = { "tokyo-night", "habamax" } },
  checker = {
    enabled = true, -- check for plugin updates periodically
    notify = false, -- notify on update
  },                -- automatically check for plugin updates
  performance = {
    rtp = {
      -- disable some rtp plugins
      disabled_plugins = {
        "gzip",
        -- "matchit",
        -- "matchparen",
        -- "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
