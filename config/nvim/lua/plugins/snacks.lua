return {
  {"snacks.nvim",
    -- Configuration is moved to separate files for better organization
  --   indent = { enabled = true },
  input = { enabled = true },
  notifier = { enabled = true },
  scope = { enabled = true },
  scroll = { enabled = true },
  statuscolumn = { enabled = false }, -- we set this in options.lua
  toggle = { map = LazyVim.safe_keymap_set },
  words = { enabled = true },
}
}


