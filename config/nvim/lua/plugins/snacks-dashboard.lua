-----------------------------------------------------------------------------------
-- SNACKS DASHBOARD CONFIGURATION
-----------------------------------------------------------------------------------

return {
  {
    "snacks.nvim",
    opts = {
      -- Enable the dashboard
      dashboard = {
        enabled = true,
        actions = {
          recent_files = {
            enabled = true,
            key = "r",
            label = "Recent Files",
            key_label = "r",
          },
          find_files = {
            enabled = true,
            key = "f",
            label = "Find Files",
            key_label = "f",
          },
          grep_string = {
            enabled = true,
            key = "g",
            label = "Grep in Files",
            key_label = "g",
          },
          open_dot_config = {
            enabled = true,
            key = "c",
            label = "Config Files",
            key_label = "c",
          },
          open_term = {
            enabled = true,
            key = "t",
            label = "Terminal",
            key_label = "t",
          },
          quit = {
            enabled = true,
            key = "q",
            label = "Quit",
            key_label = "q",
          },
        },
        sections = {
          {
            type = "text",
            opts = {
              position = "center",
              hl = "Type",
              content = {
                "███╗   ██╗ ███████╗ ██████╗  ██╗   ██╗ ██╗ ███╗   ███╗",
                "████╗  ██║ ██╔════╝██╔═══██╗ ██║   ██║ ██║ ████╗ ████║",
                "██╔██╗ ██║ █████╗  ██║   ██║ ██║   ██║ ██║ ██╔████╔██║",
                "██║╚██╗██║ ██╔══╝  ██║   ██║ ╚██╗ ██╔╝ ██║ ██║╚██╔╝██║",
                "██║ ╚████║ ███████╗╚██████╔╝  ╚████╔╝  ██║ ██║ ╚═╝ ██║",
                "╚═╝  ╚═══╝ ╚══════╝ ╚═════╝    ╚═══╝   ╚═╝ ╚═╝     ╚═╝",
                "",
                "Welcome to Neovim - " .. os.date("%Y-%m-%d"),
              },
            },
          },
          {
            type = "actions",
            position = "center",
          },
          {
            type = "text",
            opts = {
              position = "center",
              hl = "NonText",
              content = function()
                local stats = require("lazy").stats()
                local ms = (math.floor(stats.startuptime * 100 + 0.5) / 100)
                return {
                  "Loaded " .. stats.loaded .. "/" .. stats.count .. " plugins in " .. ms .. "ms",
                }
              end,
            },
          },
        },
      },
    },
  },
}