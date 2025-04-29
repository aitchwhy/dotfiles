#!/bin/bash

# Array of commands prefixed with "ant-"
ant_commands=(
  "ant-all-services"
  "ant-system-prune"
  "ant-check-1password"
  "ant-build-docker"
  "ant-build-host"
  "ant-lint"
  "ant-sync-cache"
  "ant-admin"
)

# Use fzf to select a command and store it in a variable
selected_command=$(printf "%s\n" "${ant_commands[@]}" | fzf --height 40% --reverse --border --prompt="Select a command: ")

# If a command was selected (fzf wasn't cancelled), run it
if [[ -n "$selected_command" ]]; then
  echo "Running: $selected_command"
  eval "$selected_command"
else
  echo "No command selected."
fi

# Commands to Run in Your Normal ZSH Shell
#
# Nix Environment Management:
#
# nix run .#ant -- ant-setup-nix-cache (Set up cache credentials)
# darwin-rebuild switch --flake .#anterior-base (Configure macOS environment)
# nix develop .#npm (Enter the NPM development shell)
# nix run .#ant -- ant-build-docker (Build Docker images)
# nix run .#ant -- ant-all-services (Run all services)
# nix flake check (Run tests)
#
#
# One-off Tool Execution:
#
# nix run .#ruff -- check (Run ruff linter)
# nix run .#admin -- <command> (Run the admin tool)
# nix shell .#nodejs (Get a shell with just Node.js)
#
#
# Development Environment Entry:
#
# nix develop (Enter default dev shell)
# nix develop .#npm (Enter NPM-specific dev shell)
#
#
#
# Commands to Run Inside Nix Develop Shell
# Once you're inside the Nix develop shell (after running nix develop .#npm), you would run:
#
# NPM Commands:
#
# npm ci --ignore-scripts (Install dependencies)
# npm run --workspace your/dir build (Build a specific project)
# npm run --workspace your/dir start (Start a specific project)
#
#
# Helper Tools (available within the shell):
#
# ant-npm-build-deptree YOUR_TS_PROJECT_NAME (Build dependencies for a TS project)
#
#
# Dev Shell Commands (available in the default dev shell):
#
# ant-check-1password (Verify 1Password integration)
# ant-lint (Lint code in current directory)
# system-prune (Clean up Nix/Docker resources)
# ant-admin (Run Anterior admin tool)

