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

