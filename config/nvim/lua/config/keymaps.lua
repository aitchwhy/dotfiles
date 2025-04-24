-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set:
-- https://www.lazyvim.org/configuration/general#keymaps
-- https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-----------------------------------------------------------------------------------
-- CUSTOM KEYMAPS - MODERN LAZYVIM KEYBINDINGS (2025)
-----------------------------------------------------------------------------------

local function map(mode, lhs, rhs, opts)
  opts = opts or {}
  opts.silent = opts.silent ~= false
  vim.keymap.set(mode, lhs, rhs, opts)
end

----- BASIC USABILITY --------------------------

-- Easier escape
map("i", "jk", "<ESC>", { desc = "Escape insert mode" })
map("i", "kj", "<ESC>", { desc = "Escape insert mode" })

-- Better window navigation - high priority to override any conflicting mappings
map("n", "<C-h>", "<C-w>h", { desc = "Go to left window", noremap = true, silent = true })
map("n", "<C-j>", "<C-w>j", { desc = "Go to lower window", noremap = true, silent = true })
map("n", "<C-k>", "<C-w>k", { desc = "Go to upper window", noremap = true, silent = true })
map("n", "<C-l>", "<C-w>l", { desc = "Go to right window", noremap = true, silent = true })

-- Resize windows
map("n", "<C-Up>", "<cmd>resize +2<CR>", { desc = "Increase window height" })
map("n", "<C-Down>", "<cmd>resize -2<CR>", { desc = "Decrease window height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<CR>", { desc = "Decrease window width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<CR>", { desc = "Increase window width" })

-- Stay in indent mode after indenting
map("v", "<", "<gv", { desc = "Indent left and stay in visual mode" })
map("v", ">", ">gv", { desc = "Indent right and stay in visual mode" })

-- Easy saving with Ctrl+s
map({ "i", "v", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save file" })

----- SEARCH & REPLACE --------------------------

-- Clear search highlight on Escape
map("n", "<Esc>", "<cmd>noh<CR>", { desc = "Clear search highlight" })

-- Center search results when navigating
map("n", "n", "nzzzv", { desc = "Next search result (centered)" })
map("n", "N", "Nzzzv", { desc = "Previous search result (centered)" })

-- Search for selected text in visual mode
map("v", "//", "y/\\V<C-R>=escape(@\",'/\\')<CR><CR>", { desc = "Search for selected text" })

-- Quick search and replace
map("n", "<leader>r", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = "Replace word under cursor" })

----- CONVENIENCE --------------------------

-- Keep cursor centered when scrolling
map("n", "<C-d>", "<C-d>zz", { desc = "Scroll down (centered)" })
map("n", "<C-u>", "<C-u>zz", { desc = "Scroll up (centered)" })

-- Quickly edit configuration files
map("n", "<leader>ec", "<cmd>edit ~/.config/nvim/<CR>", { desc = "Edit Neovim config" })

-- Terminal escape
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Fix terminal window navigation to properly escape before switching windows
map("t", "<C-h>", "<C-\\><C-n><C-w>h", { desc = "Go to left window", noremap = true, silent = true })
map("t", "<C-j>", "<C-\\><C-n><C-w>j", { desc = "Go to lower window", noremap = true, silent = true })
map("t", "<C-k>", "<C-\\><C-n><C-w>k", { desc = "Go to upper window", noremap = true, silent = true })
map("t", "<C-l>", "<C-\\><C-n><C-w>l", { desc = "Go to right window", noremap = true, silent = true })

-- Paste without overwriting register
map("v", "p", '"_dP', { desc = "Paste without overwriting register" })

-- Select all
map("n", "<C-a>", "gg<S-v>G", { desc = "Select all" })

----- CODE ACTIONS & NAVIGATION --------------------------

-- Go to definition in a new vertical split
map("n", "<leader>gv", "<cmd>vsplit | lua vim.lsp.buf.definition()<CR>", { desc = "Go to definition in vertical split" })
