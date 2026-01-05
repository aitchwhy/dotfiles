-- neotest.nvim - Test runner with SOTA patterns (Jan 2026)
return {
  {
    "nvim-neotest/neotest",
    dependencies = {
      "marilari88/neotest-vitest",
      "nvim-neotest/neotest-python",
    },
    opts = function(_, opts)
      -- Preserve LazyVim's overseer consumer injection
      opts.adapters = opts.adapters or {}

      -- Vitest adapter with monorepo support
      opts.adapters["neotest-vitest"] = {
        filter_dir = function(name, rel_path, root)
          -- Include only directories with vitest configs or test files
          return name ~= "node_modules"
            and name ~= ".git"
            and name ~= "dist"
            and name ~= "build"
        end,
      }

      -- Python adapter for LiveKit agent
      opts.adapters["neotest-python"] = {
        dap = { justMyCode = false },
        runner = "pytest",
        args = { "-v", "--tb=short" },
      }

      -- Status virtual text (show pass/fail inline)
      opts.status = vim.tbl_extend("force", opts.status or {}, {
        virtual_text = true,
        signs = true,
      })

      -- Output configuration
      opts.output = vim.tbl_extend("force", opts.output or {}, {
        open_on_run = true,
      })

      -- Output panel
      opts.output_panel = vim.tbl_extend("force", opts.output_panel or {}, {
        enabled = true,
        open = "botright split | resize 15",
      })

      -- Quickfix integration with Trouble
      opts.quickfix = opts.quickfix or {
        open = function()
          if pcall(require, "trouble") then
            require("trouble").open({ mode = "quickfix", focus = false })
          else
            vim.cmd("copen")
          end
        end,
      }

      -- Diagnostic consumer
      opts.diagnostic = vim.tbl_extend("force", opts.diagnostic or {}, {
        enabled = true,
        severity = vim.diagnostic.severity.ERROR,
      })

      -- Watch mode configuration
      opts.watch = vim.tbl_extend("force", opts.watch or {}, {
        enabled = true,
        symbol_queries = {
          lua = '(function_declaration name: (identifier) @symbol)',
        },
      })

      -- NOTE: LazyVim's overseer extra automatically adds:
      -- opts.consumers.overseer = require("neotest.consumers.overseer")

      return opts
    end,

    -- NOTE: LazyVim provides all standard keybindings (<leader>tt, tr, ts, etc.)
    -- Only add Told-specific extensions here
    keys = {
      -- E2E test runner (Told-specific: uses vitest --project=e2e)
      { "<leader>te", function()
        require("neotest").run.run({ suite = false, extra_args = { "--project=e2e" } })
      end, desc = "Run E2E Test (Told)" },
    },
  },
}
