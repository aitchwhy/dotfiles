-- FZF-LUA CONFIGURATION FOR LAZYVIM 8.X
-- Configures fzf-lua as the default fuzzy finder for LazyVim
return {
  {
    "ibhagwan/fzf-lua",
    cmd = "FzfLua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
      { "<leader><space>", "<cmd>FzfLua files<cr>", desc = "Find Files (fzf)" },
      { "<leader>/", "<cmd>FzfLua live_grep<cr>", desc = "Live Grep (fzf)" },
      { "<leader>:", "<cmd>FzfLua command_history<cr>", desc = "Command History (fzf)" },
      { "<leader>fb", "<cmd>FzfLua buffers<cr>", desc = "Buffers (fzf)" },
      { "<leader>ff", "<cmd>FzfLua files<cr>", desc = "Find Files (fzf)" },
      { "<leader>fg", "<cmd>FzfLua git_files<cr>", desc = "Git Files (fzf)" },
      { "<leader>sg", "<cmd>FzfLua live_grep<cr>", desc = "Live Grep (fzf)" },
      { "<leader>sh", "<cmd>FzfLua help_tags<cr>", desc = "Help Tags (fzf)" },
      { "<leader>sk", "<cmd>FzfLua keymaps<cr>", desc = "Keymaps (fzf)" },
      { "<leader>sr", "<cmd>FzfLua resume<cr>", desc = "Resume Last Search (fzf)" },
    },
    opts = {
      winopts = {
        height = 0.85,
        width = 0.80,
        row = 0.35,
        preview = {
          hidden = "nohidden",
          vertical = "down:45%",
          horizontal = "right:60%",
        },
      },
      keymap = {
        builtin = {
          ["<C-j>"] = "next",
          ["<C-k>"] = "prev",
          ["<C-f>"] = "preview-page-down",
          ["<C-b>"] = "preview-page-up",
        },
      },
      fzf_opts = {
        ["--layout"] = "reverse",
      },
      files = {
        prompt = "Files❯ ",
        git_icons = true,
        file_icons = true,
      },
      git = {
        files = {
          prompt = "GitFiles❯ ",
          git_icons = true,
          file_icons = true,
        },
        status = {
          prompt = "GitStatus❯ ",
          file_icons = true,
          git_icons = true,
        },
      },
      grep = {
        prompt = "Grep❯ ",
        file_icons = true,
        git_icons = true,
      },
    },
  },
}
