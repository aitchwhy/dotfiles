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
          if LazyVim.has("trouble.nvim") then
            require("trouble").open({ mode = "quickfix", focus = false })
          else
            vim.cmd("copen")
          end
        end,
      },
    },
  },
}
