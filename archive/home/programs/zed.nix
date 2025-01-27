{ config, lib, pkgs, ... }:

{
  # Link Zed configuration files
  xdg.configFile = {
    # Settings
    "zed/settings.json" = {
      source = ../../modules/zed/settings.json;
    };

    # Keymap
    "zed/keymap.json" = {
      source = ../../modules/zed/keymap.json;
    };

    # Themes directory (if you have custom themes)
    "zed/themes" = {
      source = ../../modules/zed/themes;
      recursive = true;
    };
  };

  # Environment variables
  home.sessionVariables = {
    # Set default editor for certain file types
    EDITOR_MD = "zed"; # For markdown files
    EDITOR_CODE = "zed"; # For code files
  };

  # Shell aliases
  programs.zsh.shellAliases = {
    # Quick edit commands
    zed = "zed ."; # Open current directory
    zedf = "zed --force-device integrated"; # Force integrated GPU
    zedd = "zed --force-device discrete"; # Force discrete GPU
  };

  # Additional packages that might be needed
  home.packages = with pkgs; [
    # Language servers that Zed might use
    rust-analyzer
    gopls
    nodePackages.typescript-language-server
    nodePackages.vscode-langservers-extracted
    lua-language-server
    nil # Nix language server
    python311Packages.python-lsp-server

    # Formatters
    nixfmt
    stylua
    prettier
    black
    rustfmt
    gofmt

    # Additional tools
    ripgrep # For search
    fd # For file finding
  ];

  # Shell integration
  programs.zsh.initExtra = ''
    # Zed shell integration
    if command -v zed >/dev/null; then
      # Add Zed to path if installed via homebrew
      if [ -d "/Applications/Zed.app" ]; then
        export PATH="/Applications/Zed.app/Contents/MacOS:$PATH"
      fi

      # Function to open files in Zed
      function zed-open() {
        if [ $# -eq 0 ]; then
          zed .
        else
          zed "$@"
        fi
      }

      # Function to wait for Zed
      function zed-wait() {
        zed --wait "$@"
      }
    fi
  '';

  # Additional configuration
  home.file = {
    # Custom snippets
    ".config/zed/snippets" = {
      source = ../../modules/zed/snippets;
      recursive = true;
    };

    # Custom extensions
    ".config/zed/extensions" = {
      source = ../../modules/zed/extensions;
      recursive = true;
    };
  };
}
