#!/usr/bin/env bash
set -euo pipefail # Enable strict mode (exit on error, unset var errors, pipeline errors)

DOTFILES=${DOTFILES:-"$HOME/dotfiles"}
XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-"$HOME/.config"}
ZDOTDIR=${ZDOTDIR:-"$XDG_CONFIG_HOME/zsh"}

# Optional: Ensure running on correct OS/arch (macOS + Apple Silicon)
if [[ "$(uname -s)" != "Darwin" || "$(uname -m)" != "arm64" ]]; then
  echo "Error: This script is intended for macOS on Apple Silicon (arm64). Exiting."
  exit 1
fi

# TODO: slink $DOTFILES/.config/zellij/main-layout.kdl $HOME/.config/config.kdl

# Define the config mapping (source:destination pairs)
CONFIG_MAP=(

  "$DOTFILES/Brewfile:$HOME/.Brewfile"

  "$DOTFILES/config/zsh/.zshrc:$XDG_CONFIG_HOME/zsh/.zshrc"
  "$DOTFILES/config/zsh/.zprofile:$XDG_CONFIG_HOME/zsh/.zprofile"

  "$DOTFILES/config/git/config:$XDG_CONFIG_HOME/git/config"
  "$DOTFILES/config/git/ignore:$XDG_CONFIG_HOME/git/ignore"

  "$DOTFILES/config/atuin/config.toml:$XDG_CONFIG_HOME/a  tuin/config.toml"
  "$DOTFILES/config/karabiner/karabiner.json:$XDG_CONFIG_HOME/karabiner/karabiner.json"
  "$DOTFILES/config/ghostty/config:$XDG_CONFIG_HOME/ghostty/config"
  "$DOTFILES/config/bat/config:$XDG_CONFIG_HOME/bat/config"
  "$DOTFILES/config/starship.toml:$XDG_CONFIG_HOME/starship.toml"
  "$DOTFILES/config/nvim:$XDG_CONFIG_HOME/nvim"

  "$DOTFILES/config/hammerspoon:$XDG_CONFIG_HOME/hammerspoon"
  "$DOTFILES/config/karabiner:$XDG_CONFIG_HOME/karabiner"

  "$DOTFILES/config/yazi:$XDG_CONFIG_HOME/yazi"
  "$DOTFILES/config/zed:$XDG_CONFIG_HOME/zed"
  "$DOTFILES/config/snippety:$XDG_CONFIG_HOME/snippety"
  "$DOTFILES/config/:$XDG_CONFIG_HOME/snippety"

  "$DOTFILES/config/zsh-abbr/user-abbreviations:$XDG_CONFIG_HOME/zsh-abbr/user-abbreviations"

  "$DOTFILES/config/zellij/config.kdl:$XDG_CONFIG_HOME/zellij/config.kdl"
  "$DOTFILES/config/zellij/layouts:$XDG_CONFIG_HOME/zellij/layouts"
  "$DOTFILES/config/zellij/plugins:$XDG_CONFIG_HOME/zellij/plugins"

  "$DOTFILES/config/todoist/config.json:$XDG_CONFIG_HOME/todoist/config.json"

  "$DOTFILES/config/espanso:$XDG_CONFIG_HOME/espanso"

  "$DOTFILES/config/aide/keybindings.json:$HOME/Library/Application Support/Aide/User/keybindings.json"
  "$DOTFILES/config/aide/settings.json:$HOME/Library/Application Support/Aide/User/settings.json"
  "$DOTFILES/config/cursor/keybindings.json:$HOME/Library/Application Support/Cursor/User/keybindings.json"
  "$DOTFILES/config/cursor/settings.json:$HOME/Library/Application Support/Cursor/User/settings.json"
  "$DOTFILES/config/vscode/keybindings.json:$HOME/Library/Application Support/Code/User/keybindings.json"
  "$DOTFILES/config/vscode/settings.json:$HOME/Library/Application Support/Code/User/settings.json"

  "$DOTFILES/ai/claude/claude_desktop_config.json:$HOME/Library/Application Support/Claude/claude_desktop_config.json"
  "$DOTFILES/ai/config:$XDG_CONFIG_HOME/ai/config"
  "$DOTFILES/ai/prompts:$XDG_CONFIG_HOME/ai/prompts"

  # Add more file or directory mappings as needed:
  # "$DOTFILES/<app>:<target_path>"
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
  ln -sf "$src" "$dest"
  echo "✅ Linked $dest -> $src"
done

echo "All config files synchronized."
