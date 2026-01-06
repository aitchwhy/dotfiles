-- Kulala HTTP client with environment variable support
-- Supports http-client.env.json for environment switching (dev/staging/prod)
return {
  {
    "mistweaverco/kulala.nvim",
    ft = { "http", "rest" },
    keys = {
      { "<leader>Rs", function() require("kulala").run() end, desc = "Send request", ft = { "http", "rest" } },
      { "<leader>Ra", function() require("kulala").run_all() end, desc = "Send all requests", ft = { "http", "rest" } },
      { "<leader>Rb", function() require("kulala").scratchpad() end, desc = "Open scratchpad" },
      { "<leader>Re", function() require("kulala").set_selected_env() end, desc = "Set environment", ft = { "http", "rest" } },
      { "<leader>Ri", function() require("kulala").inspect() end, desc = "Inspect request", ft = { "http", "rest" } },
      { "<leader>Rr", function() require("kulala").replay() end, desc = "Replay last request" },
      { "<leader>Rt", function() require("kulala").toggle_view() end, desc = "Toggle headers/body", ft = { "http", "rest" } },
      { "<leader>Rc", function() require("kulala").copy() end, desc = "Copy as cURL", ft = { "http", "rest" } },
    },
    opts = {
      -- Disable global keymaps (we define them above)
      global_keymaps = false,
      global_keymaps_prefix = "<leader>R",
      kulala_keymaps_prefix = "",

      -- Default environment (matches http-client.env.json)
      default_env = "dev",

      -- Display options
      display_mode = "float",
      winbar = true,

      -- Formatters for response body
      formatters = {
        json = { "jq" },
        xml = { "xmllint", "--format", "-" },
        html = { "prettier", "--parser", "html" },
      },
    },
  },
}
