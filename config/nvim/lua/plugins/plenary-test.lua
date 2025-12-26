-- Plenary.nvim test runner for Neovim config tests
-- Run tests with: nvim --headless -c "PlenaryBustedDirectory tests/"
return {
  {
    "nvim-lua/plenary.nvim",
    cmd = { "PlenaryBustedFile", "PlenaryBustedDirectory" },
    keys = {
      {
        "<leader>tl",
        function()
          require("plenary.test_harness").test_directory("tests/", { minimal_init = "tests/minimal_init.lua" })
        end,
        desc = "Run Lua Tests",
      },
    },
  },
}
