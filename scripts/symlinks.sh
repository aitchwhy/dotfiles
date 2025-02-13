#!/usr/bin/env bash
set -euo pipefail # Enable strict mode (exit on error, unset var errors, pipeline errors)

# Optional: Ensure running on correct OS/arch (macOS + Apple Silicon)
if [[ "$(uname -s)" != "Darwin" || "$(uname -m)" != "arm64" ]]; then
  echo "Error: This script is intended for macOS on Apple Silicon (arm64). Exiting."
  exit 1
fi

# TODO: slink $DOTFILES/.config/zellij/main-layout.kdl $HOME/.config/config.kdl

# Define the config mapping (source:destination pairs)
CONFIG_MAP=(
  "$HOME/dotfiles/config/zsh:$HOME/.config/zsh"
  # "$HOME/dotfiles/config/zsh/.zshenv:$HOME/.config/zsh/.zshenv"
  # "$HOME/dotfiles/config/zsh/.zshrc:$HOME/.config/zsh/.zshrc"
  # "$HOME/dotfiles/config/zsh/.zprofile:$HOME/.config/zsh/.zprofile"
  # "$HOME/dotfiles/config/zsh/.zprofile:$HOME/.config/zsh/.zprofile"
  # "$HOME/dotfiles/config/zsh-abbr/user-abbreviations:$HOME/.config/zsh-abbr/user-abbreviations"

  "$HOME/dotfiles/config/starship.toml:$HOME/.config/starship.toml"

  "$HOME/dotfiles/Brewfile:$HOME/.Brewfile"

  "$HOME/dotfiles/config/bat/config:$HOME/.config/bat/config"

  "$HOME/dotfiles/config/ghostty/config:$HOME/.config/ghostty/config"

  "$HOME/dotfiles/config/karabiner/karabiner.json:$HOME/.config/karabiner/karabiner.json"

  "$HOME/dotfiles/config/atuin/config.toml:$HOME/.config/atuin/config.toml"

  "$HOME/dotfiles/config/zellij/config.kdl:$HOME/.config/zellij/config.kdl"
  "$HOME/dotfiles/config/zellij/layouts:$HOME/.config/zellij/layouts"
  "$HOME/dotfiles/config/zellij/plugins:$HOME/.config/zellij/plugins"

  "$HOME/dotfiles/config/git/.gitconfig:$HOME/.gitconfig"
  "$HOME/dotfiles/config/git/.gitignore:$HOME/.gitignore"

  "$HOME/dotfiles/config/nvim:$HOME/.config/nvim"

  "$HOME/dotfiles/config/espanso:$HOME/.config/espanso"

  "$HOME/dotfiles/config/aide/keybindings.json:$HOME/Library/Application Support/Aide/User/keybindings.json"
  "$HOME/dotfiles/config/aide/settings.json:$HOME/Library/Application Support/Aide/User/settings.json"

  "$HOME/dotfiles/config/cursor/keybindings.json:$HOME/Library/Application Support/Cursor/User/keybindings.json"
  "$HOME/dotfiles/config/cursor/settings.json:$HOME/Library/Application Support/Cursor/User/settings.json"

  "$HOME/dotfiles/config/vscode/keybindings.json:$HOME/Library/Application Support/Code/User/keybindings.json"
  "$HOME/dotfiles/config/vscode/settings.json:$HOME/Library/Application Support/Code/User/settings.json"

  "$HOME/dotfiles/ai/claude/claude_desktop_config.json:$HOME/Library/Application Support/Claude/claude_desktop_config.json"

  "$HOME/dotfiles/config/todoist/config.json:$HOME/.config/todoist/config.json"

  # Add more file or directory mappings as needed:
  # "$HOME/dotfiles/<app>:<target_path>"
)

#######################################

echo "Starting config symlink synchronization..."
for mapping in "${CONFIG_MAP[@]}"; do
  # Split the source and destination by the colon separator
  IFS=':' read -r src dest <<<"$mapping"

  # Ensure source exists
  if [[ ! -e "$src" ]]; then
    echo "Warning: Source '$src' not found. Skipping..."
    continue
  fi

  # Ensure parent directory of destination exists
  dest_dir="$(dirname "$dest")"
  if [[ ! -d "$dest_dir" ]]; then
    mkdir -p "$dest_dir"
    echo "Created directory $dest_dir"
  fi

  if [[ -L "$dest" ]]; then
    # Destination is a symlink
    current_target="$(readlink "$dest")"
    if [[ "$current_target" == "$src" ]]; then
      echo "✔️  Symlink already correct: $dest -> $src"
      continue # correct symlink, move to next
    else
      echo "🔄 Updating symlink: $dest (was -> $current_target)"
      rm -f "$dest" # remove the wrong symlink
    fi
  elif [[ -e "$dest" ]]; then
    # Destination exists but is not a symlink (could be file or directory)
    echo "🔄 Removing existing $([[ -d \"$dest\" ]] && echo 'directory' || echo 'file'): $dest"
    rm -rf "$dest"
  fi

  # At this point, $dest either didn't exist or was removed, safe to create link
  ln -s "$src" "$dest"
  echo "✅ Linked $dest -> $src"
done

echo "All config files synchronized."
