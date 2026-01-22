-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set -> (https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua)
-- Add any additional keymaps here -> https://www.lazyvim.org/configuration/general#keymaps

local map = vim.keymap.set

-- Oil file manager (keep as directory editor, snacks.explorer for tree view)
map("n", "<leader>-", "<cmd>Oil<cr>", { desc = "Oil file manager" })

-- Quick command mode access
map("n", "q:", ":", { noremap = true, silent = true })
map("n", "q/", "/", { noremap = true, silent = true })
map("n", "q?", "?", { noremap = true, silent = true })

-- Window navigation (standard)
map("n", "<C-h>", "<C-w>h", { desc = "Go to Left Window", remap = true })
map("n", "<C-j>", "<C-w>j", { desc = "Go to Lower Window", remap = true })
map("n", "<C-k>", "<C-w>k", { desc = "Go to Upper Window", remap = true })
map("n", "<C-l>", "<C-w>l", { desc = "Go to Right Window", remap = true })

-- Terminal mappings
map("t", "<C-/>", "<cmd>close<cr>", { desc = "Hide Terminal" })
map("t", "<C-_>", "<cmd>close<cr>", { desc = "which_key_ignore" })

-- Paste from system clipboard in terminal mode (for Wispr Flow dictation, etc.)
map("t", "<D-v>", function()
  local clipboard = vim.fn.getreg("+")
  if clipboard and clipboard ~= "" then
    local term_chan = vim.b.terminal_job_id
    if term_chan then
      vim.api.nvim_chan_send(term_chan, clipboard)
    end
  end
end, { desc = "Paste clipboard in terminal" })
