return {
  {
    "monaqa/dial.nvim",
    keys = {
      {
        "<C-a>",
        function()
          require("dial.map").manip("increment")
        end,
        mode = { "n", "v" },
        desc = "Dial ++",
      },
      {
        "<C-x>",
        function()
          require("dial.map").manip("decrement")
        end,
        mode = { "n", "v" },
        desc = "Dial --",
      },
    },
  },
}
