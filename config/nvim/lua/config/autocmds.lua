-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-----------------------------------------------------------------------------------
-- CUSTOM AUTOCOMMANDS - MODERN LAZYVIM (2025)
-----------------------------------------------------------------------------------

local function augroup(name)
  return vim.api.nvim_create_augroup("custom_" .. name, { clear = true })
end

-- Auto-format on save (if formatter available)
vim.api.nvim_create_autocmd("BufWritePre", {
  group = augroup("auto_format"),
  callback = function()
    -- Format with conform.nvim if available
    if package.loaded["conform"] then
      require("conform").format({ timeout_ms = 500, lsp_fallback = true })
    end
  end,
  desc = "Auto-format on save",
})

-- Highlight text on yank
vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup("highlight_yank"),
  callback = function()
    vim.highlight.on_yank({ higroup = "IncSearch", timeout = 300 })
  end,
  desc = "Highlight yanked text",
})

-- Auto-resize splits when window is resized
vim.api.nvim_create_autocmd("VimResized", {
  group = augroup("resize_splits"),
  callback = function()
    vim.cmd("tabdo wincmd =")
  end,
  desc = "Auto-resize splits on window resize",
})

-- Auto-create parent directories when saving a new file
vim.api.nvim_create_autocmd("BufWritePre", {
  group = augroup("auto_create_dir"),
  callback = function(event)
    if event.match:match("^%w%w+://") then
      return
    end
    local file = vim.loop.fs_realpath(event.match) or event.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
  end,
  desc = "Auto-create directories when saving",
})

-- Set specific indentation for certain file types
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("language_indentation"),
  pattern = {
    "python",
    "rust",
    "go",
  },
  callback = function()
    local indent_map = {
      python = 4,
      rust = 4,
      go = 4,
    }

    local ft = vim.bo.filetype
    if indent_map[ft] then
      vim.bo.tabstop = indent_map[ft]
      vim.bo.shiftwidth = indent_map[ft]
      vim.bo.softtabstop = indent_map[ft]
    end
  end,
  desc = "Set language-specific indentation",
})

-- Wrap and check spelling in text filetypes
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("wrap_spell"),
  pattern = { "gitcommit", "markdown", "text" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.spell = true
  end,
  desc = "Enable word wrap and spellcheck for text file types",
})
