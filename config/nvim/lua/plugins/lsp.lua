return {
    {
      "neovim/nvim-lspconfig",
      opts = {
        servers = {
          pyright = {},        -- Python LSP
          tsserver = {},       -- TypeScript/JavaScript LSP
          rust_analyzer = {},  -- Rust LSP
          -- add others as needed, e.g. gopls for Go, clangd for C/C++, etc.
        }
      }
    }
  }