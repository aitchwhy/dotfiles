-----------------------------------------------------------------------------------
-- HARPOON 2 - QUICK NAVIGATION BETWEEN FREQUENTLY USED FILES
-----------------------------------------------------------------------------------
return {
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2", -- Use the harpoon2 branch as shown in lazy-lock.json
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      menu = {
        width = 60,
        height = 10,
      },
    },
    keys = {
      {
        "<leader>a",
        function()
          local harpoon = require("harpoon")
          harpoon:list():append()
        end,
        desc = "Harpoon Add File",
      },
      {
        "<leader>h",
        function()
          local harpoon = require("harpoon")
          harpoon.ui:toggle_quick_menu(harpoon:list())
        end,
        desc = "Harpoon Menu",
      },
      {
        "<leader>1",
        function()
          local harpoon = require("harpoon")
          harpoon:list():select(1)
        end,
        desc = "Harpoon File 1",
      },
      {
        "<leader>2",
        function()
          local harpoon = require("harpoon")
          harpoon:list():select(2)
        end,
        desc = "Harpoon File 2",
      },
      {
        "<leader>3",
        function()
          local harpoon = require("harpoon")
          harpoon:list():select(3)
        end,
        desc = "Harpoon File 3",
      },
      {
        "<leader>4",
        function()
          local harpoon = require("harpoon")
          harpoon:list():select(4)
        end,
        desc = "Harpoon File 4",
      },
      {
        "<leader>j",
        function()
          local harpoon = require("harpoon")
          harpoon:list():prev()
        end,
        desc = "Harpoon Prev File",
      },
      {
        "<leader>k",
        function()
          local harpoon = require("harpoon")
          harpoon:list():next()
        end,
        desc = "Harpoon Next File",
      },
    },
  },
}