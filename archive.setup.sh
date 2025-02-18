#!/usr/bin/env bash
# Dotfiles setup script
# Usage: ./setup.sh [--force] [--dry-run] [--no-brew] [--no-macos]

set -euo pipefail

# Core paths
DOTFILES="${DOTFILES:-$HOME/dotfiles}"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
ZDOTDIR="${ZDOTDIR:-$XDG_CONFIG_HOME/zsh}"
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"

# Options
FORCE=false
DRY_RUN=false
INSTALL_BREW=true
CONFIGURE_MACOS=true

# Colors and formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# Logging functions
log() { echo -e "${BLUE}==>${NC} $*"; }
success() { echo -e "${GREEN}✓${NC} $*"; }
warn() { echo -e "${YELLOW}!${NC} $*"; }
error() { echo -e "${RED}✗${NC} $*" >&2; }
header() { echo -e "\n${BOLD}$*${NC}"; }

# Process arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
  --force) FORCE=true ;;
  --dry-run) DRY_RUN=true ;;
  --no-brew) INSTALL_BREW=false ;;
  --no-macos) CONFIGURE_MACOS=false ;;
  --help)
    echo "Usage: $0 [--force] [--dry-run] [--no-brew] [--no-macos]"
    echo "  --force      Override existing files without prompting"
    echo "  --dry-run    Show what would be done without making changes"
    echo "  --no-brew    Skip Homebrew installation and packages"
    echo "  --no-macos   Skip macOS configuration"
    exit 0
    ;;
  *)
    error "Unknown option: $1"
    exit 1
    ;;
  esac
  shift
done

# Utility functions
is_macos() { [[ "$(uname)" == "Darwin" ]]; }
is_arm64() { [[ "$(uname -m)" == "arm64" ]]; }
is_apple_silicon() { is_macos && is_arm64; }

check_dependencies() {
  local deps=("git" "curl")
  for dep in "${deps[@]}"; do
    if ! command -v "$dep" >/dev/null 2>&1; then
      error "Required dependency not found: $dep"
      exit 1
    fi
  done
}

ensure_dir() {
  local dir="$1"
  if [[ ! -d "$dir" ]]; then
    if [[ "$DRY_RUN" == true ]]; then
      log "Would create directory: $dir"
    else
      mkdir -p "$dir"
      success "Created directory: $dir"
    fi
  fi
}

backup_file() {
  local file="$1"
  if [[ -e "$file" && ! -L "$file" ]]; then
    if [[ "$DRY_RUN" == true ]]; then
      log "Would backup: $file → $BACKUP_DIR/$(basename "$file")"
    else
      mkdir -p "$BACKUP_DIR"
      mv "$file" "$BACKUP_DIR/$(basename "$file")"
      success "Backed up: $file"
    fi
  fi
}

create_symlink() {
  local src="$1"
  local dest="$2"
  local dest_dir="$(dirname "$dest")"

  if [[ ! -e "$src" ]]; then
    error "Source doesn't exist: $src"
    return 1
  fi

  ensure_dir "$dest_dir"

  if [[ -L "$dest" ]]; then
    if [[ "$(readlink "$dest")" == "$src" ]]; then
      success "Already linked: $dest → $src"
      return 0
    fi
  fi

  if [[ -e "$dest" ]]; then
    if [[ "$FORCE" != true ]]; then
      warn "File exists: $dest"
      read -p "Replace? [y/N] " -n 1 -r
      echo
      if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        warn "Skipping: $dest"
        return 0
      fi
    fi
    backup_file "$dest"
  fi

  if [[ "$DRY_RUN" == true ]]; then
    log "Would link: $dest → $src"
  else
    ln -sf "$src" "$dest"
    success "Linked: $dest → $src"
  fi
}

# Add this to the utility functions section
create_zshenv() {

  # # Minimal stub for Zsh to load configs from /Users/hank/.config/zsh
  # export ZDOTDIR="/Users/hank/.config/zsh"
  # [[ -f "/Users/hank/.config/zsh/.zshenv" ]] && source "/Users/hank/.config/zsh/.zshenv"

  local zshenv="$HOME/.zshenv"

  # Backup existing .zshenv if it exists
  if [[ -f "$zshenv" ]]; then
    if [[ "$DRY_RUN" == true ]]; then
      log "Would backup existing .zshenv"
    else
      backup_file "$zshenv"
    fi
  fi

  if [[ "$DRY_RUN" == true ]]; then
    log "Would create $zshenv"
  else
    cat >"$zshenv" <<'EOL'
# Minimal stub for Zsh to load configs from ~/.config/zsh
export ZDOTDIR="$HOME/.config/zsh"
[[ -f "$ZDOTDIR/.zshenv" ]] && source "$ZDOTDIR/.zshenv"
EOL
    success "Created $zshenv"
  fi
}

setup_xdg_dirs() {
  header "Setting up XDG directories"

  local xdg_dirs=(
    "$XDG_CONFIG_HOME"
    "$XDG_CACHE_HOME"
    "$XDG_DATA_HOME"
    "$XDG_STATE_HOME"
    "$ZDOTDIR"
  )

  for dir in "${xdg_dirs[@]}"; do
    ensure_dir "$dir"
  done
}

setup_homebrew() {
  if [[ "$INSTALL_BREW" != true ]]; then
    return 0
  fi

  header "Setting up Homebrew"

  if ! command -v /opt/homebrew/bin/brew >/dev/null 2>&1; then
    if [[ "$DRY_RUN" == true ]]; then
      log "Would install Homebrew"
    else
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      if is_apple_silicon; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
      fi
    fi
  fi

  # if [[ "$DRY_RUN" == false ]]; then
  #   /opt/homebrew/bin/brew bundle --file="$DOTFILES/Brewfile"
  # fi
}

setup_symlinks() {
  header "Setting up config files (e.g. creating symlinks)"

  # Create ~/.zshenv directly (not symlinked)
  create_zshenv
  # source $HOME/.zshenv

  # Shell

  # create_symlink "$DOTFILES/config/zsh/.zshenv" "$HOME/.zshenv"
  create_symlink "$DOTFILES/config/zsh" "$XDG_CONFIG_HOME/zsh"

  # Development tools
  create_symlink "$DOTFILES/config/nvim" "$XDG_CONFIG_HOME/nvim"
  create_symlink "$DOTFILES/config/git" "$XDG_CONFIG_HOME/git"
  create_symlink "$DOTFILES/Brewfile" "$HOME/.Brewfile"

  # Terminal tools
  create_symlink "$DOTFILES/config/starship/starship.toml" "$XDG_CONFIG_HOME/starship.toml"
  create_symlink "$DOTFILES/config/atuin" "$XDG_CONFIG_HOME/atuin"
  create_symlink "$DOTFILES/config/bat" "$XDG_CONFIG_HOME/bat"
  create_symlink "$DOTFILES/config/zellij" "$XDG_CONFIG_HOME/zellij"

  # macOS apps
  if is_macos; then
    create_symlink "$DOTFILES/config/karabiner" "$XDG_CONFIG_HOME/karabiner"
    create_symlink "$DOTFILES/config/hammerspoon" "$HOME/.hammerspoon"

    # Handle paths with spaces
    create_symlink "$DOTFILES/config/vscode/settings.json" "$HOME/Library/Application Support/Code/User/settings.json"
    create_symlink "$DOTFILES/config/vscode/keybindings.json" "$HOME/Library/Application Support/Code/User/keybindings.json"
  fi
}

configure_macos() {
  if [[ "$CONFIGURE_MACOS" != true ]]; then
    return 0
  fi

  if ! is_macos; then
    warn "Skipping macOS configuration on non-macOS system"
    return 0
  fi

  header "Configuring macOS"

  if [[ "$DRY_RUN" == true ]]; then
    log "Would configure macOS settings"
    return 0
  fi

  # Import macOS configuration
  source "$DOTFILES/scripts/install/macos.sh"
}

initialize_tools() {
  header "Initializing tools"

  if [[ "$DRY_RUN" == true ]]; then
    log "Would initialize tools"
    return 0
  fi

  # # Initialize zsh plugins
  # if command -v zsh >/dev/null 2>&1; then
  #   zsh -c 'source "$XDG_CONFIG_HOME/zsh/.zshrc"'
  # fi
  # if command -v zsh >/dev/null 2>&1; then
  # zsh -c 'source "$XDG_CONFIG_HOME/zsh/.zprofile"'
  # zsh -c 'source "$XDG_CONFIG_HOME/zsh/.zprofile"'
  # zsh -c 'source "$XDG_CONFIG_HOME/zsh/.zshrc"'
  # fi

  # # Initialize neovim plugins if installed
  # if command -v nvim >/dev/null 2>&1; then
  #   nvim --headless -c 'autocmd User PackerComplete quitall' -c 'PackerSync'
  # fi
}

main() {
  header "Starting dotfiles setup"

  check_dependencies
  setup_xdg_dirs
  setup_homebrew
  setup_symlinks
  configure_macos
  initialize_tools

  if [[ "$DRY_RUN" == true ]]; then
    success "Dry run completed"
  else
    success "Setup completed"
  fi

  if [[ -d "$BACKUP_DIR" ]]; then
    log "Backups stored in: $BACKUP_DIR"
  fi

  log "Sourcing updated zprofile+zshrc for new changes"
  source "$ZDOTDIR/.zprofile"
  source "$ZDOTDIR/.zshrc"
}

main "$@"
