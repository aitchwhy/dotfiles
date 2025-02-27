#!/usr/bin/env zsh

# ========================================================================
# update.zsh - Update dotfiles and installed packages
# ========================================================================

set -euo pipefail

# ========================================================================
# Environment Configuration
# ========================================================================
export DOTFILES="${DOTFILES:-$HOME/dotfiles}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export ZDOTDIR_TARGET="$DOTFILES/config/zsh"
export BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"

# Check for utils.sh and source it
if [[ ! -f "$DOTFILES/utils.sh" ]]; then
  echo "Error: utils.sh not found in $DOTFILES. Please ensure the dotfiles repository is properly cloned."
  exit 1
fi

source "$DOTFILES/utils.sh"

# ========================================================================
# Repository Verification
# ========================================================================
verify_repo_structure() {
  info "Verifying dotfiles repository structure..."

  # Check if dotfiles directory exists
  if [[ ! -d "$DOTFILES" ]]; then
    error "Dotfiles directory not found at $DOTFILES"
    error "Please clone the repository first: git clone <repo-url> $DOTFILES"
    exit 1
  fi

  # Check if it's a git repository
  if [[ ! -d "$DOTFILES/.git" ]]; then
    error "The dotfiles directory is not a git repository"
    error "Please clone the repository properly: git clone <repo-url> $DOTFILES"
    exit 1
  fi

  # Check for critical directories and files
  local missing_items=()

  [[ ! -d "$DOTFILES/config" ]] && missing_items+=("config directory")
  [[ ! -d "$DOTFILES/config/zsh" ]] && missing_items+=("config/zsh directory")
  [[ ! -f "$DOTFILES/config/zsh/.zshrc" ]] && missing_items+=("config/zsh/.zshrc file")
  [[ ! -f "$DOTFILES/config/zsh/.zprofile" ]] && missing_items+=("config/zsh/.zprofile file")
  [[ ! -f "$DOTFILES/Brewfile" ]] && missing_items+=("Brewfile")

  if ((${#missing_items[@]} > 0)); then
    error "The dotfiles repository is missing critical components:"
    for item in "${missing_items[@]}"; do
      error "  - Missing $item"
    done
    error "Please ensure you've cloned the correct repository."
    exit 1
  fi

  success "Repository structure verified successfully"
}

# ========================================================================
# Fix Broken Symlinks
# ========================================================================
fix_broken_links() {
  info "Scanning for broken symlinks..."
  local broken_count=0
  local fixed_count=0

  # Check in common directories
  for dir in "$HOME" "$XDG_CONFIG_HOME" "$ZDOTDIR_TARGET"; do
    if [[ -d "$dir" ]]; then
      local broken_links=()
      mapfile -t broken_links < <(find -L "$dir" -type l -maxdepth 3 2>/dev/null)

      for broken_link in "${broken_links[@]}"; do
        broken_count=$((broken_count + 1))
        info "Found broken link: $broken_link"

        # Try to determine the original target from our dotfiles
        local link_name=$(basename "$broken_link")
        local possible_targets=()
        mapfile -t possible_targets < <(find "$DOTFILES" -name "$link_name" -type f 2>/dev/null)

        if ((${#possible_targets[@]} == 1)); then
          local target="${possible_targets[0]}"
          backup_file "$broken_link"
          rm -f "$broken_link"
          ln -sf "$target" "$broken_link"
          info "Fixed: $broken_link → $target"
          fixed_count=$((fixed_count + 1))
        elif ((${#possible_targets[@]} > 1)); then
          warn "Multiple possible targets found for $broken_link:"
          for t in "${possible_targets[@]}"; do
            echo "  - $t"
          done
          backup_file "$broken_link"
          rm -f "$broken_link"
        else
          warn "Could not find replacement for $broken_link"
          backup_file "$broken_link"
          rm -f "$broken_link"
        fi
      done
    fi
  done

  if [[ $broken_count -eq 0 ]]; then
    success "No broken symlinks found!"
  else
    info "Found $broken_count broken symlinks, fixed $fixed_count"
  fi
}

# ========================================================================
# Update Dotfiles Repository
# ========================================================================
update_dotfiles_repo() {
  info "Updating dotfiles repository..."

  if [[ -d "$DOTFILES/.git" ]]; then
    # Check for uncommitted changes
    if ! git -C "$DOTFILES" diff --quiet; then
      warn "Uncommitted changes detected in dotfiles repository"
      local answer
      read -q "answer?Continue update and stash changes? [y/N] "
      echo ""

      if [[ ! "$answer" =~ ^[Yy]$ ]]; then
        error "Update aborted. Please commit or stash your changes manually"
        return 1
      fi

      # Stash changes
      git -C "$DOTFILES" stash save "Auto-stashed during dotfiles update"
      success "Changes stashed"
    fi

    # Pull changes
    info "Pulling latest changes from remote repository..."
    git -C "$DOTFILES" pull --rebase

    success "Dotfiles repository updated"
  else
    warn "Not a git repository: $DOTFILES"
    warn "Skipping repository update"
  fi
}

# ========================================================================
# Update Homebrew Packages
# ========================================================================
update_homebrew() {
  if ! command -v brew &>/dev/null; then
    warn "Homebrew not installed, skipping updates"
    return 0
  fi

  info "Updating Homebrew..."
  brew update

  info "Upgrading Homebrew packages..."
  brew upgrade

  # Update from Brewfile
  if [[ -f "$DOTFILES/Brewfile" ]]; then
    local answer
    read -q "answer?Check for Brewfile changes and install missing packages? [y/N] "
    echo ""

    if [[ "$answer" =~ ^[Yy]$ ]]; then
      info "Checking Brewfile..."
      brew bundle check --file="$DOTFILES/Brewfile" || {
        info "Some packages in Brewfile are not installed"
        read -q "answer?Install missing packages? [y/N] "
        echo ""

        if [[ "$answer" =~ ^[Yy]$ ]]; then
          brew bundle install --file="$DOTFILES/Brewfile"
        fi
      }
    fi
  fi

  # Clean up
  info "Cleaning up Homebrew..."
  brew cleanup

  success "Homebrew packages updated"
}

# ========================================================================
# Update Shell Plugins and Development Tools
# ========================================================================
update_shell_plugins() {
  info "Updating shell plugins..."

  # Update Rust toolchain
  if command -v rustup &>/dev/null; then
    info "Updating Rust toolchain..."
    rustup update
  fi

  # Update Python environment
  if command -v pyenv &>/dev/null; then
    info "Updating pyenv..."
    if command -v pyenv-update &>/dev/null; then
      pyenv update
    else
      warn "pyenv-update not found, manual update required"
    fi
  fi

  # Update npm packages
  if command -v npm &>/dev/null; then
    info "Updating global npm packages..."
    npm update -g
  fi

  success "Shell plugins updated"
}

# ========================================================================
# Check and Update ZDOTDIR Configuration
# ========================================================================
check_zdotdir_changes() {
  info "Checking ZDOTDIR configuration..."

  # Check if .zshenv exists and points to the right place
  if [[ -f "$HOME/.zshenv" ]]; then
    local current_zdotdir=$(grep -o 'export ZDOTDIR="[^"]*"' "$HOME/.zshenv" | cut -d'"' -f2)

    if [[ -z "$current_zdotdir" || "$current_zdotdir" != "$ZDOTDIR_TARGET" ]]; then
      warn "ZDOTDIR in .zshenv doesn't match target ($ZDOTDIR_TARGET)"

      # Update .zshenv
      backup_file "$HOME/.zshenv"

      cat >"$HOME/.zshenv" <<EOF
# ZSH configuration bootstrapper
# Auto-generated by dotfiles update script
export ZDOTDIR="$ZDOTDIR_TARGET"
[[ -f "\$ZDOTDIR/.zshenv" ]] && source "\$ZDOTDIR/.zshenv"
EOF

      success "Updated .zshenv to point to $ZDOTDIR_TARGET"
    else
      success "ZDOTDIR is correctly configured"
    fi
  else
    warn "No .zshenv found in home directory"

    # Create .zshenv
    cat >"$HOME/.zshenv" <<EOF
# ZSH configuration bootstrapper
# Auto-generated by dotfiles update script
export ZDOTDIR="$ZDOTDIR_TARGET"
[[ -f "\$ZDOTDIR/.zshenv" ]] && source "\$ZDOTDIR/.zshenv"
EOF

    success "Created .zshenv pointing to $ZDOTDIR_TARGET"
  fi

  # Ensure XDG config directory exists
  ensure_dir "$XDG_CONFIG_HOME"

  # Link ZSH config dir to XDG location for compatibility if needed
  if [[ ! -L "$XDG_CONFIG_HOME/zsh" || "$(readlink "$XDG_CONFIG_HOME/zsh")" != "$ZDOTDIR_TARGET" ]]; then
    if [[ -e "$XDG_CONFIG_HOME/zsh" || -L "$XDG_CONFIG_HOME/zsh" ]]; then
      backup_file "$XDG_CONFIG_HOME/zsh"
      rm -rf "$XDG_CONFIG_HOME/zsh"
    fi

    # Create symlink to the zsh config directory
    ln -sf "$ZDOTDIR_TARGET" "$XDG_CONFIG_HOME/zsh"
    success "Linked ZSH configuration to $XDG_CONFIG_HOME/zsh"
  fi
}

# ========================================================================
# Relink Config Files
# ========================================================================
relink_configs() {
  info "Relinking configuration files..."

  # Import setup_cli_tools function from install.zsh if available
  if [[ -f "$DOTFILES/install.zsh" ]]; then
    # Source the install script in a subshell to avoid environment pollution
    (
      source "$DOTFILES/install.zsh"
      if type setup_cli_tools &>/dev/null; then
        setup_cli_tools
      else
        error "setup_cli_tools function not found in install.zsh"
      fi
    )

    success "Configuration files relinked"
  else
    error "Install script not found at $DOTFILES/install.zsh"
    return 1
  fi
}

# ========================================================================
# Update macOS Apps from App Store
# ========================================================================
update_mac_apps() {
  if command -v mas &>/dev/null; then
    info "Updating App Store applications..."
    mas upgrade
    success "App Store applications updated"
  else
    warn "mas not installed, skipping App Store updates"
  fi
}

# ========================================================================
# Update VSCode Extensions
# ========================================================================
update_vscode_extensions() {
  if command -v code &>/dev/null; then
    info "Updating VSCode extensions..."
    code --update-extensions
    success "VSCode extensions updated"
  fi
}

# ========================================================================
# System Checks
# ========================================================================
system_check() {
  info "Running system checks..."

  # Check disk space
  info "Checking disk space..."
  df -h /

  # Check Homebrew
  if command -v brew &>/dev/null; then
    info "Running brew doctor..."
    brew doctor
  fi

  # Check for macOS updates
  info "Checking for macOS updates..."
  softwareupdate -l

  # Check for broken symlinks
  info "Checking for broken symlinks..."
  local broken_count=0

  for dir in "$HOME" "$XDG_CONFIG_HOME" "$ZDOTDIR_TARGET"; do
    if [[ -d "$dir" ]]; then
      local count=$(find -L "$dir" -type l -maxdepth 3 2>/dev/null | wc -l | tr -d ' ')
      broken_count=$((broken_count + count))
    fi
  done

  if [[ $broken_count -gt 0 ]]; then
    warn "Found $broken_count broken symlinks"
    warn "Run with --fix-links to attempt repair"
  else
    success "No broken symlinks found"
  fi

  success "System checks completed"
}

# ========================================================================
# Parse Command-Line Arguments
# ========================================================================
parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
    --no-brew)
      NO_BREW=true
      shift
      ;;
    --no-apps)
      NO_APPS=true
      shift
      ;;
    --no-repo)
      NO_REPO=true
      shift
      ;;
    --fix-links)
      FIX_LINKS=true
      shift
      ;;
    --quick)
      QUICK=true
      shift
      ;;
    --help)
      echo "Usage: $0 [options]"
      echo "Options:"
      echo "  --no-brew     Skip Homebrew updates"
      echo "  --no-apps     Skip App Store and VSCode updates"
      echo "  --no-repo     Skip dotfiles repository update"
      echo "  --fix-links   Attempt to fix broken symlinks"
      echo "  --quick       Quick update (only dotfiles and relink)"
      echo "  --help        Show this help message"
      exit 0
      ;;
    *)
      warn "Unknown option: $1"
      shift
      ;;
    esac
  done
}

# ========================================================================
# Main Update Function
# ========================================================================
main() {
  local start_time=$(date +%s)

  info "Starting dotfiles update..."

  # Check if running on macOS
  if ! is_macos; then
    error "This script is designed for macOS only."
    exit 1
  fi

  # Verify repository structure first
  verify_repo_structure

  # Show update plan
  info "Update plan:"
  [[ "$NO_REPO" == "false" ]] && echo "  ✓ Update dotfiles repository"
  [[ "$NO_BREW" == "false" ]] && echo "  ✓ Update Homebrew packages"
  [[ "$QUICK" == "false" ]] && echo "  ✓ Update shell plugins"
  echo "  ✓ Check ZDOTDIR configuration"
  echo "  ✓ Relink configuration files"
  [[ "$QUICK" == "false" && "$NO_APPS" == "false" ]] && echo "  ✓ Update App Store applications"
  [[ "$QUICK" == "false" && "$NO_APPS" == "false" ]] && echo "  ✓ Update VSCode extensions"
  [[ "$FIX_LINKS" == "true" ]] && echo "  ✓ Fix broken symlinks"
  [[ "$QUICK" == "false" ]] && echo "  ✓ Run system checks"
  echo ""

  # Ask for confirmation
  local answer
  read -q "answer?Continue with update? [Y/n] "
  echo ""

  if [[ ! "$answer" =~ ^[Yy]$ && ! -z "$answer" ]]; then
    info "Update cancelled by user"
    exit 0
  fi

  # Run only essential updates if quick flag is set
  if [[ "$QUICK" == "true" ]]; then
    info "Running quick update..."
    [[ "$NO_REPO" == "false" ]] && update_dotfiles_repo
    check_zdotdir_changes
    relink_configs
    [[ "$FIX_LINKS" == "true" ]] && fix_broken_links
  else
    # Run all updates
    [[ "$NO_REPO" == "false" ]] && update_dotfiles_repo
    [[ "$NO_BREW" == "false" ]] && update_homebrew
    update_shell_plugins
    check_zdotdir_changes
    relink_configs
    [[ "$NO_APPS" == "false" ]] && update_mac_apps
    [[ "$NO_APPS" == "false" ]] && update_vscode_extensions
    [[ "$FIX_LINKS" == "true" ]] && fix_broken_links
    system_check
  fi

  # Calculate time taken
  local end_time=$(date +%s)
  local time_taken=$((end_time - start_time))
  local minutes=$((time_taken / 60))
  local seconds=$((time_taken % 60))

  success "Dotfiles update complete! 🎉"
  info "Time taken: ${minutes}m ${seconds}s"

  if [[ -d "$BACKUP_DIR" && "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]]; then
    local backup_size=$(du -sh "$BACKUP_DIR" | cut -f1)
    info "Backup created at $BACKUP_DIR ($backup_size)"
  fi

  info "To apply all changes to your current shell, run: exec zsh"
}

# Initialize optional flags
NO_BREW=false
NO_APPS=false
NO_REPO=false
FIX_LINKS=false
QUICK=false

# Parse arguments and run main function
parse_args "$@"
main
