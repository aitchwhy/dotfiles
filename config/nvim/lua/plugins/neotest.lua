-- Neotest configuration for LazyVim
return {
  {
    "nvim-neotest/neotest",
    opts = {
      adapters = {
        ["neotest-vitest"] = {},
        ["neotest-python"] = {},
        ["neotest-go"] = {},
      },
      status = { virtual_text = true },
      output = { open_on_run = true },
      quickfix = {
        open = function()
          vim.cmd("copen")
        end,
      },
    },
  },
}
