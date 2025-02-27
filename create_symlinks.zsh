#!/usr/bin/env zsh

# Set environment variables if not already set
DOTFILES="$HOME/dotfiles"
XDG_CONFIG_HOME="$HOME/.config"

echo "Creating symlinks from dotfiles to local config directories..."
echo "Dotfiles directory: $DOTFILES"
echo "Config directory: $XDG_CONFIG_HOME"

# Create backup directory
BACKUP_DIR="$HOME/.config_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
echo "Backup directory created at: $BACKUP_DIR"

# Function to create a symlink
create_symlink() {
  local source="$1"
  local target="$2"
  
  # Check if source exists
  if [[ ! -e "$source" ]]; then
    echo "⚠️ Source does not exist: $source - Skipping"
    return 1
  fi
  
  # Get target directory
  local target_dir=$(dirname "$target")
  
  # Create target directory if it doesn't exist
  if [[ ! -d "$target_dir" ]]; then
    echo "Creating directory: $target_dir"
    mkdir -p "$target_dir"
  fi
  
  # Backup existing target if it exists and is not already a symlink to our source
  if [[ -e "$target" ]]; then
    if [[ -L "$target" && "$(readlink "$target")" = "$source" ]]; then
      echo "✓ Symlink already exists and points to correct location: $target → $source"
      return 0
    else
      local backup_path="$BACKUP_DIR/$(basename "$target")"
      echo "Backing up existing file/directory: $target → $backup_path"
      mv "$target" "$backup_path"
    fi
  fi
  
  # Create symlink
  echo "Creating symlink: $target → $source"
  ln -s "$source" "$target"
  
  if [[ $? -eq 0 ]]; then
    echo "✅ Successfully created symlink: $target → $source"
  else
    echo "❌ Failed to create symlink: $target → $source"
  fi
}

# Declare associative array for the symlink mappings
typeset -A DOTFILES_TO_SYMLINK_MAP
DOTFILES_TO_SYMLINK_MAP=(
  ["$DOTFILES/config/git/gitconfig"]="$HOME/.gitconfig"
  ["$DOTFILES/config/git/gitignore"]="$HOME/.gitignore"
  ["$DOTFILES/config/starship.toml"]="$XDG_CONFIG_HOME/starship.toml"
  ["$DOTFILES/config/karabiner/karabiner.json"]="$XDG_CONFIG_HOME/karabiner/karabiner.json"
  ["$DOTFILES/config/nvim"]="$XDG_CONFIG_HOME/nvim"
  ["$DOTFILES/config/ghostty"]="$XDG_CONFIG_HOME/ghostty"
  ["$DOTFILES/config/atuin"]="$XDG_CONFIG_HOME/atuin"
  ["$DOTFILES/config/bat"]="$XDG_CONFIG_HOME/bat"
  ["$DOTFILES/config/zellij"]="$XDG_CONFIG_HOME/zellij"
  ["$DOTFILES/config/espanso"]="$XDG_CONFIG_HOME/espanso"
  ["$DOTFILES/config/vscode/settings.json"]="$HOME/Library/Application Support/Code/User/settings.json"
  ["$DOTFILES/config/vscode/keybindings.json"]="$HOME/Library/Application Support/Code/User/keybindings.json"
  ["$DOTFILES/config/cursor/settings.json"]="$HOME/Library/Application Support/Cursor/User/settings.json"
  ["$DOTFILES/config/cursor/keybindings.json"]="$HOME/Library/Application Support/Cursor/User/keybindings.json"
  ["$DOTFILES/config/hammerspoon"]="$HOME/.hammerspoon"
  ["$DOTFILES/config/ai/claude/claude_desktop_config.json"]="$HOME/Library/Application Support/Claude/claude_desktop_config.json"
)

# Create the symlinks using the associative array
for source target in ${(kv)DOTFILES_TO_SYMLINK_MAP}; do
  create_symlink "$source" "$target"
done

# Create a symlink for this script itself
create_symlink "$DOTFILES/create_symlinks.zsh" "$XDG_CONFIG_HOME/create_symlinks.sh"

echo "Symlink creation process completed."
echo "Backup directory (if files were backed up): $BACKUP_DIR"