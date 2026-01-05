-- overseer.nvim - Task runner with SOTA patterns (Jan 2026)
-- NOTE: LazyVim's overseer extra provides default keybindings (<leader>o*)
-- This file extends with custom component aliases and template hooks
return {
  {
    "stevearc/overseer.nvim",
    opts = {
      -- DAP integration for preLaunchTask/postDebugTask
      dap = true,

      -- Task list positioning (edgy handles actual placement)
      task_list = {
        direction = "right",
        bindings = {
          ["<C-h>"] = false,
          ["<C-j>"] = false,
          ["<C-k>"] = false,
          ["<C-l>"] = false,
        },
      },

      -- Form UI (no transparency for readability)
      form = {
        win_opts = { winblend = 0 },
      },
      confirm = {
        win_opts = { winblend = 0 },
      },
      task_win = {
        win_opts = { winblend = 0 },
      },

      -- Component aliases for Told project patterns
      component_aliases = {
        default = {
          "on_exit_set_status",
          "on_complete_notify",
          { "on_complete_dispose", require_view = { "SUCCESS", "FAILURE" } },
        },
        -- pnpm tasks with quickfix integration
        default_pnpm = {
          "on_exit_set_status",
          { "on_output_quickfix", open_on_match = true, tail = true },
          { "on_complete_notify", statuses = { "FAILURE" } },
          "on_complete_dispose",
        },
        -- TypeScript tasks with diagnostics
        default_typescript = {
          "on_exit_set_status",
          { "on_output_parse", problem_matcher = "$tsc" },
          "on_result_diagnostics",
          { "on_complete_notify", statuses = { "FAILURE" } },
          "on_complete_dispose",
        },
        -- Long-running dev servers
        default_server = {
          "on_exit_set_status",
          { "open_output", direction = "dock", on_start = "always" },
        },
      },
    },

    config = function(_, opts)
      local overseer = require("overseer")
      overseer.setup(opts)

      -- Template hook: Add quickfix to pnpm tasks in Told project
      overseer.add_template_hook({ module = "^npm$" }, function(task_defn, util)
        if task_defn.cwd and task_defn.cwd:match("told") then
          util.add_component(task_defn, { "on_output_quickfix", open_on_match = true })
        end
      end)

      -- Enable DAP integration (for lazy-loaded dap)
      overseer.enable_dap()

      -- Custom command: Restart last completed task (from overseer recipes)
      vim.api.nvim_create_user_command("OverseerRestartLast", function()
        local tasks = overseer.list_tasks({
          recent_first = true,
          status = {
            overseer.STATUS.SUCCESS,
            overseer.STATUS.FAILURE,
            overseer.STATUS.CANCELED,
          },
        })
        if vim.tbl_isempty(tasks) then
          vim.notify("No tasks found", vim.log.levels.WARN)
        else
          tasks[1]:restart()
        end
      end, {})
    end,

    -- Additional keybindings beyond LazyVim defaults
    keys = {
      { "<leader>or", "<cmd>OverseerRestartLast<cr>", desc = "Restart last task" },
    },
  },
}
