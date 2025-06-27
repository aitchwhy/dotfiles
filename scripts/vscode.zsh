#!/usr/bin/env bash

# VS Code extensions list
extensions=(
    "dbaeumer.vscode-eslint"             # ESLint for JavaScript/TypeScript
    "esbenp.prettier-vscode"             # Code formatting
    "ms-python.python"                   # Python support
    "ms-python.vscode-pylance"           # Python language server
    "ms-dotnettools.csharp"              # C# support
    "christian-kohler.path-intellisense" # Path autocomplete
    "ms-azuretools.vscode-docker"        # Docker integration
    "eamodio.gitlens"                    # Enhanced Git capabilities
    "mikestead.dotenv"                   # .env file support
    "editorconfig.editorconfig"          # EditorConfig support
    "usernamehw.errorlens"               # Improved error visibility
    "gruntfuggly.todo-tree"              # Track TODOs in workspace
)

function install_vscode_extensions() {
    # Install each extension
    for ext in "${extensions[@]}"; do
        echo "Installing $ext..."
        code --install-extension "$ext"
    done
    echo "VS Code extensions installation complete!"
}

# Get all functions defined in this script
function list_functions() {
    declare -F | awk '{print $3}' | grep -v "^_" | sort
}

# Fuzzy select a function to run
function select_and_run_function() {
    if ! command -v fzf &>/dev/null; then
        echo "fzf is not installed. Please install it first."
        return 1
    fi

    local selected_function=$(list_functions | fzf --height 40% --border --prompt="Select function to run: ")

    if [[ -n "$selected_function" ]]; then
        echo "Running function: $selected_function"
        $selected_function
    else
        echo "No function selected."
    fi
}

# Run the fuzzy selector
select_and_run_function
