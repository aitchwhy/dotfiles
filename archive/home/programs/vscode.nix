{ config, pkgs, ... }:

{
  programs.vscode = {
    enable = true;
    enableUpdateCheck = false;
    mutableExtensionsDir = false;

    # Extensions
    extensions = with pkgs.vscode-extensions; [
      # Theme & UI
      arcticicestudio.nord-visual-studio-code
      catppuccin.catppuccin-vsc
      emmanuelbeziat.vscode-great-icons
      file-icons.file-icons
      pkief.material-product-icons
      antfu.icons-carbon

      # Language Support
      bbenoist.nix
      jnoortheen.nix-ide
      ms-python.python
      ms-python.vscode-pylance
      rust-lang.rust-analyzer
      golang.go
      graphql.vscode-graphql-syntax
      hashicorp.terraform
      tamasfe.even-better-toml
      redhat.vscode-yaml

      # Git
      eamodio.gitlens
      github.copilot
      github.copilot-chat
      github.remotehub

      # Development Tools
      ms-vscode-remote.remote-containers
      ms-azuretools.vscode-docker
      ms-kubernetes-tools.vscode-kubernetes-tools
      christian-kohler.path-intellisense
      dbaeumer.vscode-eslint
      esbenp.prettier-vscode
      formulahendry.auto-close-tag
      formulahendry.auto-rename-tag
      usernamehw.errorlens
      gruntfuggly.todo-tree

      # AI & Documentation
      sourcery.sourcery
      mintlify.document

      # Database
      mtxr.sqltools
      mtxr.sqltools-driver-pg

      # Testing & Debugging
      ms-vscode.cpptools
      ms-toolsai.jupyter
    ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
      # Additional extensions not available in nixpkgs
      {
        name = "vscode-just";
        publisher = "skellock";
        version = "2.1.0";
        sha256 = "sha256-CF3SXYW2Yj2u+xuWnwMaGxfKEcvS6gHA5qGfoMeEhJw=";
      }
      {
        name = "better-comments";
        publisher = "aaron-bond";
        version = "3.0.2";
        sha256 = "sha256-hQmA8PWjf2Nd60v5EAuqqD8LIEu7slrNs8luc3ePgZc=";
      }
    ];

    # User settings
    userSettings = {
      # Editor
      "editor.fontFamily" = "JetBrainsMono Nerd Font";
      "editor.fontSize" = 14;
      "editor.lineHeight" = 1.5;
      "editor.renderWhitespace" = "all";
      "editor.rulers" = [ 80 100 120 ];
      "editor.tabSize" = 2;
      "editor.formatOnSave" = true;
      "editor.defaultFormatter" = "esbenp.prettier-vscode";
      "editor.bracketPairColorization.enabled" = true;
      "editor.guides.bracketPairs" = true;
      "editor.minimap.enabled" = false;
      "editor.smoothScrolling" = true;
      "editor.cursorSmoothCaretAnimation" = "on";
      "editor.cursorBlinking" = "phase";
      "editor.mouseWheelZoom" = true;

      # Workbench
      "workbench.colorTheme" = "Catppuccin Mocha";
      "workbench.iconTheme" = "material-icon-theme";
      "workbench.productIconTheme" = "material-product-icons";
      "workbench.editor.enablePreview" = false;
      "workbench.startupEditor" = "none";
      "workbench.tree.indent" = 16;
      "workbench.list.smoothScrolling" = true;

      # Files
      "files.autoSave" = "onFocusChange";
      "files.trimTrailingWhitespace" = true;
      "files.insertFinalNewline" = true;
      "files.trimFinalNewlines" = true;
      "files.exclude" = {
        "**/.git" = true;
        "**/.DS_Store" = true;
        "**/node_modules" = true;
        "**/__pycache__" = true;
      };

      # Terminal
      "terminal.integrated.fontFamily" = "JetBrainsMono Nerd Font";
      "terminal.integrated.fontSize" = 14;
      "terminal.integrated.cursorBlinking" = true;
      "terminal.integrated.cursorStyle" = "line";
      "terminal.integrated.defaultProfile.osx" = "zsh";

      # Git
      "git.autofetch" = true;
      "git.enableSmartCommit" = true;
      "git.confirmSync" = false;
      "gitlens.hovers.currentLine.over" = "line";
      "github.copilot.enable" = {
        "*" = true;
        "plaintext" = false;
        "markdown" = true;
        "scminput" = false;
      };

      # Language specific
      "[nix]" = {
        "editor.defaultFormatter" = "jnoortheen.nix-ide";
      };
      "[python]" = {
        "editor.defaultFormatter" = "ms-python.python";
        "editor.formatOnType" = true;
      };
      "[javascript]" = {
        "editor.defaultFormatter" = "esbenp.prettier-vscode";
      };
      "[typescript]" = {
        "editor.defaultFormatter" = "esbenp.prettier-vscode";
      };
      "[json]" = {
        "editor.defaultFormatter" = "esbenp.prettier-vscode";
      };
      "[jsonc]" = {
        "editor.defaultFormatter" = "esbenp.prettier-vscode";
      };
      "[html]" = {
        "editor.defaultFormatter" = "esbenp.prettier-vscode";
      };
      "[css]" = {
        "editor.defaultFormatter" = "esbenp.prettier-vscode";
      };
      "[markdown]" = {
        "editor.defaultFormatter" = "esbenp.prettier-vscode";
      };

      # Extension specific
      "prettier.singleQuote" = true;
      "prettier.trailingComma" = "es5";
      "todo-tree.general.tags" = [
        "BUG"
        "HACK"
        "FIXME"
        "TODO"
        "XXX"
        "[ ]"
        "[x]"
      ];
    };

    # Keybindings
    keybindings = [
      {
        key = "cmd+shift+f";
        command = "editor.action.formatDocument";
        when = "editorHasDocumentFormattingProvider && editorTextFocus && !editorReadonly && !inCompositeEditor";
      }
      {
        key = "cmd+k cmd+f";
        command = "editor.action.formatSelection";
        when = "editorHasDocumentSelectionFormattingProvider && editorTextFocus && !editorReadonly";
      }
      {
        key = "cmd+k cmd+x";
        command = "editor.action.trimTrailingWhitespace";
        when = "editorTextFocus && !editorReadonly";
      }
    ];
  };
}
