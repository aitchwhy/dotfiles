return {
  -- Why this works:
  -- •	opts = {} is all that is required—the plugin will call require("mason").setup() for you; no manual wiring.   ￼
  -- •	The same goes for mason-lspconfig; opts = {} auto-runs the bridge’s setup.   ￼
  -- •	Listing servers under ensure_installed ensures Mason grabs them the next time you open Neovim or run :Lazy sync.   ￼
  --
  --#region
  --
  -- ✓ actionlint (keywords: yaml)
  -- ✓ ast-grep ast_grep (keywords: c, c++, rust, go, java, python, c#, javascript, jsx, typescript, html, css, kotlin, dart, lua)
  -- ✓ astro-language-server astro (keywords: astro)
  -- ✓ awk-language-server awk_ls (keywords: awk)
  -- ✓ bash-debug-adapter (keywords: bash)
  -- ✓ bash-language-server bashls (keywords: bash, csh, ksh, sh, zsh)
  -- ✓ black (keywords: python)
  -- ✓ chrome-debug-adapter (keywords: javascript, typescript)
  -- ✓ clangd (keywords: c, c++)
  -- ✓ codelldb (keywords: c, c++, rust, zig)
  -- ✓ codeql codeqlls (keywords: codeql)
  -- ✓ contextive (keywords: f#)
  -- ✓ copilot-language-server (keywords: )
  -- ✓ cql-language-server (keywords: cql)
  -- ✓ css-lsp cssls (keywords: css, scss, less)
  -- ✓ cssmodules-language-server cssmodules_ls (keywords: css)
  -- ✓ debugpy (keywords: python)
  -- ✓ delve (keywords: go)
  -- ✓ docker-compose-language-service docker_compose_language_service (keywords: docker)
  -- ✓ dockerfile-language-server dockerls (keywords: docker)
  -- ✓ dotenv-linter (keywords: dotenv)
  -- ✓ editorconfig-checker (keywords: )
  -- ✓ emmet-ls emmet_ls (keywords: emmet)
  -- ✓ erb-formatter (keywords: html, ruby)
  -- ✓ erb-lint (keywords: html, ruby)
  -- ✓ eslint-lsp eslint (keywords: javascript, typescript)
  -- ✓ eslint_d (keywords: typescript, javascript)
  -- ✓ flake8 (keywords: python)
  -- ✓ gitui (keywords: )
  -- ✓ gofumpt (keywords: go)
  -- ✓ goimports (keywords: go)
  -- ✓ golangci-lint-langserver golangci_lint_ls (keywords: go)
  -- ✓ gomodifytags (keywords: go)
  -- ✓ gopls (keywords: go)
  -- ✓ graphql-language-service-cli graphql (keywords: graphql)
  -- ✓ hadolint (keywords: docker)
  -- ✓ haskell-language-server hls (keywords: haskell)
  -- ✓ helm-ls helm_ls (keywords: helm)
  -- ✓ html-lsp html (keywords: html)
  -- ✓ htmlbeautifier (keywords: html, ruby)
  -- ✓ htmlhint (keywords: html)
  -- ✓ htmx-lsp htmx (keywords: htmx)
  -- ✓ impl (keywords: go)
  -- ✓ isort (keywords: python)
  -- ✓ jinja-lsp jinja_lsp (keywords: django, jinja, nunjucks)
  -- ✓ jq (keywords: json)
  -- ✓ jq-lsp jqls (keywords: jq)
  -- ✓ js-debug-adapter (keywords: javascript, typescript)
  -- ✓ json-lsp jsonls (keywords: json)
  -- ✓ jsonlint (keywords: json)
  -- ✓ jsonnet-language-server jsonnet_ls (keywords: jsonnet)
  -- ✓ jsonnetfmt (keywords: jsonnet)
  -- ✓ just-lsp (keywords: just)
  -- ✓ kube-linter (keywords: helm, yaml)
  -- ✓ kulala-fmt (keywords: http)
  -- ✓ llm-ls (keywords: )
  -- ✓ lua-language-server lua_ls (keywords: lua)
  -- ✓ luacheck (keywords: lua)
  -- ✓ markdown-oxide markdown_oxide (keywords: markdown)
  -- ✓ markdown-toc (keywords: markdown)
  -- ✓ markdownlint (keywords: markdown)
  -- ✓ markdownlint-cli2 (keywords: markdown)
  -- ✓ marksman (keywords: markdown)
  -- ✓ markuplint (keywords: html)
  -- ✓ nginx-language-server nginx_language_server (keywords: nginx)
  -- ✓ nil nil_ls (keywords: nix)
  -- ✓ nixpkgs-fmt (keywords: nix)
  -- ✓ nxls (keywords: json)
  -- ✓ oxlint (keywords: javascript, typescript)
  -- ✓ php-cs-fixer (keywords: php)
  -- ✓ phpactor (keywords: php)
  -- ✓ phpcs (keywords: php)
  -- ✓ postgrestools (keywords: postgres, sql)
  -- ✓ prettier (keywords: angular, css, flow, graphql, html, json, jsx, javascript, less, markdown, scss, typescript, vue, yaml)
  -- ✓ prettierd (keywords: angular, css, flow, graphql, html, json, jsx, javascript, less, markdown, scss, typescript, vue, yaml)
  -- ✓ prisma-language-server prismals (keywords: prisma)
  -- ✓ pydocstyle (keywords: python)
  -- ✓ pyflakes (keywords: python)
  -- ✓ pylint (keywords: python)
  -- ✓ pyproject-flake8 (keywords: python)
  -- ✓ pyproject-fmt (keywords: python, toml)
  -- ✓ pyright (keywords: python)
  -- ✓ python-lsp-server pylsp (keywords: python)
  -- ✓ rnix-lsp rnix (keywords: nix)
  -- ✓ rubocop (keywords: ruby)
  -- ✓ ruby-lsp ruby_lsp (keywords: ruby)
  -- ✓ ruff (keywords: python)
  -- ✓ ruff-lsp (keywords: python)
  -- ✓ rust-analyzer rust_analyzer (keywords: rust)
  -- ✓ rustfmt (keywords: rust)
  -- ✓ selene (keywords: lua, luau)
  -- ✓ semgrep (keywords: c#, go, json, java, javascript, php, python, ruby, scala, typescript)
  -- ✓ shellcheck (keywords: bash)
  -- ✓ shfmt (keywords: bash, mksh, shell)
  -- ✓ sonarlint-language-server (keywords: azureresourcemanager, c, c++, c#, cloudformation, css, docker, go, html, ipython, java, javascript, kubernetes, typescript, python, php, terraform, text, xml, yaml)
  -- ✓ spectral-language-server spectral (keywords: json, yaml)
  -- ✓ sqlfluff (keywords: sql)
  -- ✓ sqls (keywords: sql)
  -- ✓ staticcheck (keywords: go)
  -- ✓ stylelint (keywords: css, sass, scss, less)
  -- ✓ stylelint-lsp stylelint_lsp (keywords: stylelint)
  -- ✓ stylua (keywords: lua, luau)
  -- ✓ superhtml (keywords: html, superhtml)
  -- ✓ svelte-language-server svelte (keywords: svelte)
  -- ✓ tailwindcss-language-server tailwindcss (keywords: css)
  -- ✓ taplo (keywords: toml)
  -- ✓ terraform-ls terraformls (keywords: terraform)
  -- ✓ tflint (keywords: terraform)
  -- ✓ trufflehog (keywords: )
  -- ✓ ts-standard (keywords: typescript)
  -- ✓ ts_query_ls (keywords: query)
  -- ✓ typescript-language-server ts_ls (keywords: typescript, javascript)
  -- ✓ vacuum (keywords: openapi)
  -- ✓ vale (keywords: text, markdown, latex)
  -- ✓ vim-language-server vimls (keywords: vimscript)
  -- ✓ vtsls (keywords: javascript, typescript)
  -- ✓ yaml-language-server yamlls (keywords: yaml)
  -- ✓ yamlfmt (keywords: yaml)
  -- ✓ yamllint (keywords: yaml)
  -- ✓ yapf (keywords: python)
  --
  --
  --
  -- Custom LSP keymaps or server-specific settings live in the LazyVim LSP plugin spec (see plugins/lsp.lua)—keep Mason concerns separate from LSP behaviour.  ￼
  {
    -- Bridge Mason ↔ lspconfig, dap & formatters
    "williamboman/mason-lspconfig.nvim",
    version = "2.*",
    opts = {
      ui = {
        icons = {
          package_installed = "✓",
          package_pending = "➜",
          package_uninstalled = "✗",
        },
      },
      automatic_enable = true,
      ensure_installed = {
        "lua_ls", -- Lua
        "gopls", -- Go
        -- "tsserver", -- TypeScript/JS
        "rust_analyzer",

        -- "markdownlint-cli2",
        -- "markdown-toc",
        -- -- LSP (Language Servers)
        -- -----------------------------
        -- -- Web Development
        -- "typescript-language-server", -- TypeScript/JavaScript
        -- "eslint-lsp", -- ESLint with LSP capabilities
        -- "tailwindcss-language-server", -- Tailwind CSS
        -- "css-lsp", -- CSS
        -- "html-lsp", -- HTML
        -- "json-lsp", -- JSON
        -- "emmet-ls", -- Emmet
        -- "hadolint", -- Dockerfile
        --
        -- -- Backend/Systems Programming
        -- "pyright", -- Python type checking
        -- "ruff-lsp", -- Fast Python linting
        -- "gopls", -- Go
        -- "rust-analyzer", -- Rust
        -- "lua-language-server", -- Lua
        -- "clangd", -- C/C++
        -- "tflint",
        --
        -- -- DevOps/Configuration
        -- "yaml-language-server", -- YAML
        -- "dockerfile-language-server", -- Dockerfile
        -- "terraform-ls", -- Terraform
        -- "marksman", -- Markdown
        -- "taplo", -- TOML
        --
        -- -- Formatters
        -- -----------------------------
        -- "prettier", -- Web technologies
        -- "black", -- Python
        -- "stylua", -- Lua
        -- "shfmt", -- Shell
        -- "gofumpt", -- Go
        -- "rustfmt", -- Rust
        -- "markdownlint-cli2", -- Markdown
        -- "markdown-toc", -- Markdown
        --
        -- -- Linters
        -- -----------------------------
        -- "eslint_d", -- JavaScript/TypeScript (fast daemon)
        -- "ruff", -- Python (ultra-fast)
        -- "selene", -- Lua
        -- "hadolint", -- Dockerfile
        -- "actionlint", -- GitHub Actions
        -- "shellcheck", -- Shell
        -- "flake8", -- Python (traditional)
        -- "vale", -- Prose/documentation linter
        --
        -- -- DAP (Debug Adapters)
        -- "debugpy", -- Python
        -- "js-debug-adapter", -- JavaScript/TypeScript
        -- "delve", -- Go
        -- "codelldb", -- Rust/C/C++
        --
        -- Tools
        -----------------------------
        -- "ast-grep", -- Universal AST tool for code search
      },
    },
    dependencies = {
      { "neovim/nvim-lspconfig" },
      "neovim/nvim-lspconfig",
    },
  },
}
