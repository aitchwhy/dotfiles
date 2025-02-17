#!/usr/bin/env bash

set -euo pipefail

######################
# Source the git util script (get project root)
. "./git.sh"

# Call the function to get the repo root of this script's location
PROJECT_ROOT=$(get_repo_root "$0")
######################

source "${PROJECT_ROOT}/utils.sh"

main() {
  info "Updating dotfiles..."

  # Pull latest changes
  cd "$DOTFILES_DIR"
  git pull origin main

  # Update Homebrew packages
  if has_command brew; then
    info "Updating Homebrew packages..."
    brew update
    brew upgrade
    brew cleanup
  fi

  # Relink configuration files
  setup_zsh

  success "Dotfiles update complete!"
}

main "$@"

#!/usr/bin/env bash
# # Update script for dotfiles and tools
#
# source "$(dirname "${BASH_SOURCE[0]}")/utils/helpers.sh"
#
# # Update Homebrew and packages
# update_homebrew() {
#   header "Updating Homebrew packages"
#
#   brew update
#   brew upgrade
#   brew cleanup --prune=all
#   brew bundle --global
#
#   success "Homebrew packages updated"
# }
#
# # Update dotfiles repository
# update_dotfiles() {
#   header "Updating dotfiles repository"
#
#   cd "$DOTFILES" || exit 1
#
#   # Stash any changes
#   git stash
#
#   # Pull updates
#   git pull origin main
#
#   # Reapply changes
#   git stash pop
#
#   success "Dotfiles repository updated"
# }
#
# # Update tool configurations
# update_configs() {
#   header "Updating tool configurations"
#
#   # Re-run symlink setup
#   "$DOTFILES/scripts/setup.sh"
#
#   success "Configurations updated"
# }
#
# # Main execution
# main() {
#   update_dotfiles
#   update_homebrew
#   update_configs
#
#   success "System update complete!"
# }
#
# main "$@"

# Dotfiles update script
# Usage: ./update.sh [--dry-run]

set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/dotfiles}"
DRY_RUN=false

# Import common functions
source "$DOTFILES/scripts/utils/helpers.sh"

# Process arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
  --dry-run) DRY_RUN=true ;;
  --help)
    echo "Usage: $0 [--dry-run]"
    echo "  --dry-run    Show what would be done without making changes"
    exit 0
    ;;
  *)
    error "Unknown option: $1"
    exit 1
    ;;
  esac
  shift
done

update_dotfiles() {
  header "Updating dotfiles repository"

  if [[ "$DRY_RUN" == true ]]; then
    log "Would update dotfiles repository"
    return 0
  fi

  cd "$DOTFILES"

  # # Check for uncommitted changes
  # if [[ -n "$(git status --porcelain)" ]]; then
  #   warn "Uncommitted changes detected"
  #   git status --short
  #   read -p "Continue? [y/N] " -n 1 -r
  #   echo
  #   if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  #     error "Update aborted"
  #     exit 1
  #   fi
  #   # Stash changes
  #   git stash
  # fi

  # Update repository
  git pull origin main

  # Reapply changes if stashed
  if [[ -n "$(git stash list)" ]]; then
    git stash pop
  fi

  success "Dotfiles repository updated"
}

update_packages() {
  header "Updating packages"

  if [[ "$DRY_RUN" == true ]]; then
    log "Would update packages"
    return 0
  fi

  if command -v brew >/dev/null 2>&1; then
    log "Updating Homebrew packages"
    brew update
    brew upgrade
    brew cleanup --prune=all
    # brew bundle --global
    success "Homebrew packages updated"
  fi

  # if command -v nvim >/dev/null 2>&1; then
  #   log "Updating Neovim plugins"
  #   nvim --headless -c 'autocmd User PackerComplete quitall' -c 'PackerSync'
  #   success "Neovim plugins updated"
  # fi
}

update_configurations() {
  header "Updating configurations"

  if [[ "$DRY_RUN" == true ]]; then
    log "Would update configurations"
    return 0
  fi

  # Re-run symlink setup
  "$DOTFILES/scripts/setup.sh" --no-brew --no-macos

  success "Configurations updated"
}

clean_system() {
  header "Cleaning system"

  if [[ "$DRY_RUN" == true ]]; then
    log "Would clean system"
    return 0
  fi

  # Clean caches
  find "$XDG_CACHE_HOME" -type f -atime +30 -delete 2>/dev/null || true

  # Clean old backups older than 30 days
  find "$HOME/.dotfiles_backup" -maxdepth 1 -type d -mtime +30 -exec rm -rf {} + 2>/dev/null || true

  success "System cleaned"
}

main() {
  header "Starting system update"

  # update_dotfiles
  # update_packages
  update_configurations
  clean_system

  if [[ "$DRY_RUN" == true ]]; then
    success "Dry run completed"
  else
    success "Update completed"
  fi
}

main "$@"

############### END

# ########
# # sync.sh
# ########
#
#
# #!/usr/bin/env bash
# set -euo pipefail
#
# DOTFILES="$HOME/dotfiles"
#
# # Function to sync external changes
# sync_external() {
#   local src="$1"
#   local dest="$2"
#   local name="$3"
#
#   if [[ ! -e "$src" ]]; then
#     echo "⚠️  Source doesn't exist: $src"
#     return 1
#   fi
#
#   if [[ -n "$(diff "$src" "$dest" 2>/dev/null)" ]]; then
#     echo "🔄 Changes detected in $name"
#
#     # Create backup
#     cp "$dest" "$dest.backup-$(date +%Y%m%d-%H%M%S)"
#
#     # Sync changes
#     cp "$src" "$dest"
#
#     # Add to git
#     (cd "$DOTFILES" && git add "$dest" &&
#       git commit -m "feat(config): update $name configuration")
#
#     echo "✅ Synced changes for $name"
#   fi
# }
#
# # VSCode
# sync_external \
#   "$HOME/Library/Application Support/Code/User/settings.json" \
#   "$DOTFILES/config/vscode/settings.json" \
#   "VSCode settings"
#
# # Karabiner
# sync_external \
#   "$HOME/.config/karabiner/karabiner.json" \
#   "$DOTFILES/config/karabiner/karabiner.json" \
#   "Karabiner"
#
# # Add more tools as needed
#
#

# ########
# # symlinks.sh
# ########
# #!/usr/bin/env bash
# # Dotfiles Setup Script
# # Creates symlinks from dotfiles repository to appropriate locations
# # Usage: ./setup.sh [--force] [--dry-run]
# set -euo pipefail # Enable strict mode (exit on error, unset var errors, pipeline errors)
#
# # Optional: Ensure running on correct OS/arch (macOS + Apple Silicon)
# if [[ "$(uname -s)" != "Darwin" || "$(uname -m)" != "arm64" ]]; then
#   echo "Error: This script is intended for macOS on Apple Silicon (arm64). Exiting."
#   exit 1
# fi
#
# # Core paths
# DOTFILES="${DOTFILES:-$HOME/dotfiles}"
# XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
# XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
# XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
# XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
# # ZDOTDIR=${ZDOTDIR:-"$XDG_CONFIG_HOME/zsh"}
#
# # macOS-specific paths
# LIBRARY_DIR="$HOME/Library"
# APP_SUPPORT_DIR="$LIBRARY_DIR/Application Support"
#
# # Options
# FORCE=false
# DRY_RUN=false
#
# # Process arguments
# while [[ $# -gt 0 ]]; do
#   case "$1" in
#   --force) FORCE=true ;;
#   --dry-run) DRY_RUN=true ;;
#   *)
#     echo "Unknown option: $1"
#     exit 1
#     ;;
#   esac
#   shift
# done
#
# # Color output
# RED='\033[0;31m'
# GREEN='\033[0;32m'
# YELLOW='\033[0;33m'
# BLUE='\033[0;34m'
# NC='\033[0m'
#
# # Logging functions
# log() { echo -e "${BLUE}==>${NC} $*"; }
# success() { echo -e "${GREEN}✓${NC} $*"; }
# warn() { echo -e "${YELLOW}!${NC} $*"; }
# error() { echo -e "${RED}✗${NC} $*" >&2; }
#
# VSCODE_DIR="$HOME/Library/Application Support/Code/User"
# CURSOR_DIR="$HOME/Library/Application Support/Cursor/User"
#
# # Mapping of source files to their symlink destinations
# declare -A SYMLINKS=(
#   # Zsh shell
#   ["config/zsh/.zshenv"]="$HOME/.zshenv"
#   ["config/zsh"]="$XDG_CONFIG_HOME/zsh"
#
#   # Core tools
#   ["Brewfile"]="$HOME/.Brewfile"
#   ["config/git"]="$XDG_CONFIG_HOME/git"
#   ["config/nvim"]="$XDG_CONFIG_HOME/nvim"
#   ["config/starship/starship.toml"]="$XDG_CONFIG_HOME/starship.toml"
#   ["config/bat"]="$XDG_CONFIG_HOME/bat"
#   ["config/atuin"]="$XDG_CONFIG_HOME/atuin"
#   ["config/lazygit"]="$XDG_CONFIG_HOME/lazygit"
#   ["config/yazi"]="$XDG_CONFIG_HOME/yazi"
#   ["config/zellij"]="$XDG_CONFIG_HOME/zellij"
#   ["config/ghostty"]="$XDG_CONFIG_HOME/ghostty"
#
#   # Text editors
#   ["config/vscode/settings.json"]="$VSCODE_DIR/settings.json"
#   ["config/vscode/keybindings.json"]="$VSCODE_DIR/keybindings.json"
#   ["config/vscode/snippets"]="$VSCODE_DIR/snippets"
#   ["config/cursor/settings.json"]="$CURSOR_DIR/settings.json"
#   ["config/cursor/keybindings.json"]="$CURSOR_DIR/keybindings.json"
#   ["config/cursor/snippets"]="$CURSOR_DIR/snippets"
#
#   # macOS tools
#   ["config/karabiner"]="$XDG_CONFIG_HOME/karabiner"
#   ["config/hammerspoon"]="$HOME/.hammerspoon"
#   ["config/espanso"]="$XDG_CONFIG_HOME/espanso"
#
#   # AI tools
#   ["config/ai"]="$XDG_CONFIG_HOME/ai"
#   ["config/claude/claude_desktop_config.json"]="$APP_SUPPORT_DIR/Claude/claude_desktop_config.json"
#   # "$DOTFILES/ai/claude/claude_desktop_config.json:$HOME/Library/Application Support/Claude/claude_desktop_config.json"
#   # "$DOTFILES/ai/config:$XDG_CONFIG_HOME/ai/config"
#   # "$DOTFILES/ai/prompts:$XDG_CONFIG_HOME/ai/prompts"
#
#   # Development tools
#   ["config/node"]="$XDG_CONFIG_HOME/node"
#   ["config/npm"]="$XDG_CONFIG_HOME/npm"
#
#   # Additional tools
#   ["config/todoist"]="$XDG_CONFIG_HOME/todoist"
#   ["config/zsh-abbr/user-abbreviations"]="$XDG_CONFIG_HOME/zsh-abbr/user-abbreviations"
#
#   # # Add more file or directory mappings as needed:
#   # # "$DOTFILES/<app>:<target_path>"
#   # "$DOTFILES/Brewfile:$HOME/.Brewfile"
#   # "$DOTFILES/config/zsh:$XDG_CONFIG_HOME/zsh"
#   # # "$DOTFILES/config/zsh/.zshrc:$XDG_CONFIG_HOME/zsh/.zshrc"
#   # # "$DOTFILES/config/zsh/.zprofile:$XDG_CONFIG_HOME/zsh/.zprofile"
#   # # "$DOTFILES/config/zsh/functions.zsh:$XDG_CONFIG_HOME/zsh/functions.zsh"
#   # # "$DOTFILES/config/zsh/aliases.zsh:$XDG_CONFIG_HOME/zsh/aliases.zsh"
#   # # "$DOTFILES/config/zsh/fzf.zsh:$XDG_CONFIG_HOME/zsh/fzf.zsh"
#   # # "$DOTFILES/config/zsh/fzf.zsh:$XDG_CONFIG_HOME/zsh/fzf.zsh"
#   #
#   # "$DOTFILES/config/git/config:$XDG_CONFIG_HOME/git/config"
#   # "$DOTFILES/config/git/ignore:$XDG_CONFIG_HOME/git/ignore"
#   #
#   # "$DOTFILES/config/atuin/config.toml:$XDG_CONFIG_HOME/atuin/config.toml"
#   # "$DOTFILES/config/karabiner/karabiner.json:$XDG_CONFIG_HOME/karabiner/karabiner.json"
#   # "$DOTFILES/config/ghostty/config:$XDG_CONFIG_HOME/ghostty/config"
#   # "$DOTFILES/config/bat/config:$XDG_CONFIG_HOME/bat/config"
#   # "$DOTFILES/config/starship/starship.toml:$XDG_CONFIG_HOME/starship/starship.toml"
#   # "$DOTFILES/config/nvim:$XDG_CONFIG_HOME/nvim"
#   #
#   # "$DOTFILES/config/hammerspoon:$XDG_CONFIG_HOME/hammerspoon"
#   #
#   # "$DOTFILES/config/yazi:$XDG_CONFIG_HOME/yazi"
#   # "$DOTFILES/config/zed:$XDG_CONFIG_HOME/zed"
#   # "$DOTFILES/config/snippety:$XDG_CONFIG_HOME/snippety"
#   #
#   # "$DOTFILES/config/zsh-abbr/user-abbreviations:$XDG_CONFIG_HOME/zsh-abbr/user-abbreviations"
#   #
#   # "$DOTFILES/config/zellij/config.kdl:$XDG_CONFIG_HOME/zellij/config.kdl"
#   # "$DOTFILES/config/zellij/layouts:$XDG_CONFIG_HOME/zellij/layouts"
#   # "$DOTFILES/config/zellij/plugins:$XDG_CONFIG_HOME/zellij/plugins"
#   #
#   # "$DOTFILES/config/todoist/config.json:$XDG_CONFIG_HOME/todoist/config.json"
#   #
#   #
#   # "$DOTFILES/config/aide/keybindings.json:$HOME/Library/Application Support/Aide/User/keybindings.json"
#   # "$DOTFILES/config/aide/settings.json:$HOME/Library/Application Support/Aide/User/settings.json"
#   # "$DOTFILES/config/cursor/keybindings.json:$HOME/Library/Application Support/Cursor/User/keybindings.json"
#   # "$DOTFILES/config/cursor/settings.json:$HOME/Library/Application Support/Cursor/User/settings.json"
#   # "$DOTFILES/config/vscode/keybindings.json:$HOME/Library/Application Support/Code/User/keybindings.json"
#   # "$DOTFILES/config/vscode/settings.json:$HOME/Library/Application Support/Code/User/settings.json"
#   #
#
# )
#
# # Create symlink with proper error handling and backup
# create_symlink() {
#   local src="$DOTFILES/$1"
#   local dest="$2"
#   local dest_dir="$(dirname "$dest")"
#
#   # Skip if source doesn't exist
#   if [[ ! -e "$src" ]]; then
#     warn "Source missing: $src"
#     return 1
#   fi
#
#   # Create parent directory if needed
#   if [[ ! -d "$dest_dir" ]]; then
#     if [[ "$DRY_RUN" == true ]]; then
#       log "Would create directory: $dest_dir"
#     else
#       mkdir -p "$dest_dir"
#       success "Created directory: $dest_dir"
#     fi
#   fi
#
#   # Handle existing destination
#   if [[ -e "$dest" || -L "$dest" ]]; then
#     if [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]]; then
#       success "Already linked: $dest -> $src"
#       return 0
#     fi
#
#     if [[ "$FORCE" != true ]]; then
#       warn "Exists: $dest"
#       return 1
#     fi
#
#     # Backup existing file/directory
#     if [[ "$DRY_RUN" == false ]]; then
#       local backup="$dest.backup-$(date +%Y%m%d-%H%M%S)"
#       mv "$dest" "$backup"
#       success "Backed up: $dest -> $backup"
#     fi
#   fi
#
#   # Create symlink
#   if [[ "$DRY_RUN" == true ]]; then
#     log "Would link: $dest -> $src"
#   else
#     ln -sf "$src" "$dest"
#     success "Linked: $dest -> $src"
#   fi
# }
#
# # Clean broken symlinks in common config directories
# clean_broken_links() {
#   local dirs=(
#     "$HOME"
#     "$XDG_CONFIG_HOME"
#     "$XDG_DATA_HOME"
#     "$APP_SUPPORT_DIR"
#   )
#
#   for dir in "${dirs[@]}"; do
#     if [[ -d "$dir" ]]; then
#       if [[ "$DRY_RUN" == true ]]; then
#         log "Would clean broken links in: $dir"
#       else
#         find "$dir" -type l ! -exec test -e {} \; -delete
#         success "Cleaned broken links in: $dir"
#       fi
#     fi
#   done
# }
#
# # Create required XDG directories
# setup_xdg_dirs() {
#   local dirs=(
#     "$XDG_CONFIG_HOME"
#     "$XDG_DATA_HOME"
#     "$XDG_CACHE_HOME"
#     "$XDG_STATE_HOME"
#   )
#
#   for dir in "${dirs[@]}"; do
#     if [[ ! -d "$dir" ]]; then
#       if [[ "$DRY_RUN" == true ]]; then
#         log "Would create XDG directory: $dir"
#       else
#         mkdir -p "$dir"
#         success "Created XDG directory: $dir"
#       fi
#     fi
#   done
# }
#
# # Main execution
# main() {
#   log "Starting dotfiles setup..."
#
#   # Create XDG directories
#   setup_xdg_dirs
#
#   # Create symlinks
#   for src in "${!SYMLINKS[@]}"; do
#     create_symlink "$src" "${SYMLINKS[$src]}"
#   done
#
#   # Clean broken symlinks
#   clean_broken_links
#
#   success "Dotfiles setup complete!"
# }
#
# main "$@"
#
# ##################### END
#
# #######################################
#
# # ###########################
# # # Helper function to link #
# # ###########################
# # symlink_file() {
# #   local src="$1"
# #   local dest="$2"
# #
# #   # Skip if source doesn't exist
# #   if [[ ! -e "$src" ]]; then
# #     echo "Warning: Source '$src' does not exist. Skipping..."
# #     return
# #   fi
# #
# #   # Ensure destination directory exists
# #   local dest_dir
# #   dest_dir="$(dirname "$dest")"
# #   if [[ ! -d "$dest_dir" ]]; then
# #     mkdir -p "$dest_dir"
# #     echo "Created directory: $dest_dir"
# #   fi
# #
# #   # If destination is already a symlink, verify correctness
# #   if [[ -L "$dest" ]]; then
# #     local current_target
# #     current_target="$(readlink "$dest")"
# #     if [[ "$current_target" == "$src" ]]; then
# #       echo "✔️  Already linked: $dest -> $src"
# #       return
# #     else
# #       echo "🔄 Updating symlink: $dest (old -> $current_target)"
# #       rm -f "$dest"
# #     fi
# #   # If a regular file or directory exists, remove it
# #   elif [[ -e "$dest" ]]; then
# #     echo "🔄 Removing existing $([[ -d "$dest" ]] && echo 'directory' || echo 'file'): $dest"
# #     rm -rf "$dest"
# #   fi
# #
# #   # Create new symlink
# #   ln -s "$src" "$dest"
# #   echo "✅ Linked: $dest -> $src"
# # }
# #
# # echo "Starting config symlink synchronization..."
# # for mapping in "${CONFIG_MAP[@]}"; do
# #   IFS=':' read -r src dest <<<"$mapping"
# #   symlink_file "$src" "$dest"
# # done
# #
# # echo "All config files are now symlinked."
#
# #######################################
# # echo "Starting config symlink synchronization..."
# # for mapping in "${CONFIG_MAP[@]}"; do
# #   # Split the source and destination by the colon separator
# #   IFS=':' read -r src dest <<<"$mapping"
# #
# #   # Ensure source exists
# #   if [[ ! -e "$src" ]]; then
# #     echo "Warning: Source '$src' not found. Skipping..."
# #     continue
# #   fi
# #
# #   # Ensure parent directory of destination exists
# #   dest_dir="$(dirname "$dest")"
# #   if [[ ! -d "$dest_dir" ]]; then
# #     mkdir -p "$dest_dir"
# #     echo "Created directory $dest_dir"
# #   fi
# #
# #   if [[ -L "$dest" ]]; then
# #     # Destination is a symlink
# #     current_target="$(readlink "$dest")"
# #     if [[ "$current_target" == "$src" ]]; then
# #       echo "✔️  Symlink already correct: $dest -> $src"
# #       continue # correct symlink, move to next
# #     else
# #       echo "🔄 Updating symlink: $dest (was -> $current_target)"
# #       rm -f "$dest" # remove the wrong symlink
# #     fi
# #   elif [[ -e "$dest" ]]; then
# #     # Destination exists but is not a symlink (could be file or directory)
# #     echo "🔄 Removing existing $([[ -d \"$dest\" ]] && echo 'directory' || echo 'file'): $dest"
# #     rm -rf "$dest"
# #   fi
# #
# #   # At this point, $dest either didn't exist or was removed, safe to create link
# #   ln -sf "$src" "$dest"
# #   echo "✅ Linked $dest -> $src"
# # done
# #
# # echo "All config files synchronized."
