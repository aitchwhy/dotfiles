{ config, pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    # Install needed packages
    extraPackages = with pkgs; [
      # Language servers
      lua-language-server
      nil # Nix
      nodePackages.typescript-language-server
      nodePackages.vscode-langservers-extracted # html, css, json, eslint
      nodePackages.prettier
      python311Packages.python-lsp-server
      rust-analyzer
      gopls

      # Tools
      ripgrep # Required by telescope.nvim
      fd # Required by telescope.nvim
      tree-sitter # Required by nvim-treesitter

      # Formatters & Linters
      stylua # Lua
      nixfmt # Nix
      shfmt # Shell
      shellcheck # Shell
      black # Python
      ruff # Python
      prettierd # Web
    ];

    # Configure plugins
    plugins = with pkgs.vimPlugins; [
      # Package manager
      lazy-nvim

      # LSP
      nvim-lspconfig
      mason-nvim
      mason-lspconfig-nvim
      none-ls-nvim

      # Completion
      nvim-cmp
      cmp-nvim-lsp
      cmp-buffer
      cmp-path
      cmp-cmdline
      luasnip
      cmp_luasnip

      # Treesitter
      nvim-treesitter.withAllGrammars
      playground # Treesitter playground
      nvim-treesitter-textobjects

      # Telescope
      telescope-nvim
      telescope-fzf-native-nvim

      # Git
      gitsigns-nvim
      vim-fugitive

      # UI
      lualine-nvim
      nvim-web-devicons
      tokyonight-nvim
      which-key-nvim

      # Editor
      nvim-autopairs
      comment-nvim
      vim-sleuth
      nvim-surround
    ];
  };

  # Link your existing Neovim configuration
  xdg.configFile = {
    # Main config directory
    "nvim" = {
      source = ../../modules/nvim;
      recursive = true;
    };

    # Ensure LazyVim config directory exists
    "LazyVim" = {
      source = pkgs.fetchFromGitHub {
        owner = "LazyVim";
        repo = "LazyVim";
        rev = "v10.8.2"; # Use the latest stable version
        sha256 = "sha256-UvPNqeVZaZvGj7mZMcRzqSqGj8rQZr3HhQhI8Vz4Erg=";
      };
      recursive = true;
    };
  };

  # Environment variables
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    # Disable netrw in favor of nvim-tree
    NETRW_DISABLED = 1;
  };

  # Additional dependencies
  home.packages = with pkgs; [
    # Git (required for lazy.nvim)
    git

    # Clipboard support
    xclip

    # Terminal integration
    terminal-notifier # For notifications

    # Optional but recommended
    lazygit # For better git integration
    delta # For better git diffs
  ];
}
