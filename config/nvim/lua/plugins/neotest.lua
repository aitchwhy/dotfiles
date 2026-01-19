-- neotest.nvim - Test runner with SOTA patterns (Jan 2026)
-- Configured for Told monorepo (pnpm workspaces, Vitest 4.x with projects)
return {
  {
    "nvim-neotest/neotest",
    dependencies = {
      "marilari88/neotest-vitest",
      "nvim-neotest/neotest-python",
      "stevearc/overseer.nvim", -- CRITICAL: ensures overseer is in rtp before consumer require
    },
    opts = function(_, opts)
      -- Preserve LazyVim's overseer consumer injection
      opts.adapters = opts.adapters or {}

      -- Vitest adapter with monorepo support
      opts.adapters["neotest-vitest"] = {
        -- Filter directories for test discovery (excludes build artifacts)
        filter_dir = function(name, rel_path, root)
          return name ~= "node_modules"
            and name ~= ".git"
            and name ~= "dist"
            and name ~= "build"
            and name ~= ".turbo"
            and name ~= "coverage"
        end,

        -- Custom test file detection for monorepo structure
        is_test_file = function(file_path)
          -- Match patterns from vitest.config.ts
          return file_path:match("%.test%.ts$") ~= nil
            or file_path:match("%.test%.tsx$") ~= nil
            or file_path:match("%.spec%.ts$") ~= nil
            or file_path:match("%.spec%.tsx$") ~= nil
        end,

        -- Use project root vitest.config.ts (handles workspace resolution)
        vitestConfigFile = function(root)
          local config_path = root .. "/vitest.config.ts"
          if vim.fn.filereadable(config_path) == 1 then
            return config_path
          end
          return nil
        end,

        -- Set cwd to project root for monorepo support
        cwd = function(file)
          -- Find the monorepo root by looking for pnpm-workspace.yaml
          local root = vim.fn.getcwd()
          local workspace_file = vim.fn.findfile("pnpm-workspace.yaml", file .. ";")
          if workspace_file ~= "" then
            root = vim.fn.fnamemodify(workspace_file, ":h")
          end
          return root
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

      -- Diagnostic consumer (show errors as diagnostics)
      opts.diagnostic = vim.tbl_extend("force", opts.diagnostic or {}, {
        enabled = true,
        severity = vim.diagnostic.severity.ERROR,
      })

      -- Watch mode configuration
      opts.watch = vim.tbl_extend("force", opts.watch or {}, {
        enabled = true,
        symbol_queries = {
          lua = '(function_declaration name: (identifier) @symbol)',
          typescript = '(function_declaration name: (identifier) @symbol)',
          typescriptreact = '(function_declaration name: (identifier) @symbol)',
        },
      })

      -- FIX: Override LazyVim's broken overseer consumer injection with safe loading
      -- LazyVim's overseer extra does `opts.consumers.overseer = require(...)` during opts
      -- resolution, before overseer.nvim's lua/ is in rtp. This pcall handles that gracefully.
      opts.consumers = opts.consumers or {}
      local ok, overseer_consumer = pcall(require, "neotest.consumers.overseer")
      if ok then
        opts.consumers.overseer = overseer_consumer
      else
        vim.notify("neotest: Failed to load overseer consumer", vim.log.levels.WARN)
      end

      return opts
    end,

    -- Custom keybindings for Told workflow
    -- Remaps LazyVim defaults to match user preference + adds project-specific bindings
    keys = {
      -- Core test running (remap LazyVim defaults)
      {
        "<leader>tt",
        function()
          require("neotest").run.run()
        end,
        desc = "Run Nearest Test",
      },
      {
        "<leader>tf",
        function()
          require("neotest").run.run(vim.fn.expand("%"))
        end,
        desc = "Run Current File",
      },

      -- Debug nearest test with DAP (uses pwa-node adapter)
      {
        "<leader>td",
        function()
          require("neotest").run.run({ strategy = "dap" })
        end,
        desc = "Debug Nearest Test",
      },

      -- Property tests (Told-specific: uses vitest --project=property)
      {
        "<leader>tp",
        function()
          -- Run property tests for current file or all if not a property test file
          local file = vim.fn.expand("%")
          if file:match("%.property%.test%.ts$") then
            require("neotest").run.run({
              vim.fn.expand("%"),
              extra_args = { "--project=property" },
            })
          else
            -- Run all property tests in the project
            require("neotest").run.run({
              vim.fn.getcwd(),
              extra_args = { "--project=property" },
            })
          end
        end,
        desc = "Run Property Tests",
      },

      -- Coverage (run with v8 coverage)
      {
        "<leader>tc",
        function()
          require("neotest").run.run({
            vim.fn.expand("%"),
            extra_args = { "--coverage" },
          })
        end,
        desc = "Run with Coverage",
      },

      -- Watch mode toggle (matches LazyVim default)
      {
        "<leader>tw",
        function()
          require("neotest").watch.toggle(vim.fn.expand("%"))
        end,
        desc = "Toggle Watch Mode",
      },

      -- E2E test runner (Told-specific: Playwright via pnpm)
      {
        "<leader>te",
        function()
          -- E2E tests use Playwright, not vitest
          vim.notify("E2E tests use Playwright. Run: pnpm test:e2e", vim.log.levels.INFO)
        end,
        desc = "E2E Info (Playwright)",
      },

      -- Run all tests in workspace
      {
        "<leader>tT",
        function()
          require("neotest").run.run(vim.fn.getcwd())
        end,
        desc = "Run All Tests",
      },

      -- Output and summary (keep LazyVim defaults accessible)
      {
        "<leader>to",
        function()
          require("neotest").output.open({ enter = true, auto_close = true })
        end,
        desc = "Show Test Output",
      },
      {
        "<leader>tO",
        function()
          require("neotest").output_panel.toggle()
        end,
        desc = "Toggle Output Panel",
      },
      {
        "<leader>ts",
        function()
          require("neotest").summary.toggle()
        end,
        desc = "Toggle Summary",
      },

      -- Stop running tests
      {
        "<leader>tS",
        function()
          require("neotest").run.stop()
        end,
        desc = "Stop Tests",
      },
    },
  },
}
