#!/usr/bin/env zsh
# ========================================================================
# Homebrew Package Management
# ========================================================================
# A comprehensive set of utilities for managing Homebrew packages
# https://brew.sh
#
# USAGE: Source this file in your .zshrc or other zsh configuration
# files to make these Homebrew utilities available to your shell.

# Source common utilities if not already loaded
[[ -f "$ZDOTDIR/utils.zsh" ]] && source "$ZDOTDIR/utils.zsh"

# ========================================================================
# Core Homebrew Environment Variables
# ========================================================================

# Set Homebrew environment variables locally, not exported globally
# typeset -g _BREWFILE="${BREWFILE:-$HOME/.Brewfile}"
# typeset -g _HOMEBREW_CASK_OPTS="${HOMEBREW_CASK_OPTS:---appdir=${HOME}/Applications}"

# ========================================================================
# Helper Functions
# ========================================================================

# Check if Homebrew is available, returning error if not
_brew_check() {
  if ! has_command brew; then
    log_error "Homebrew is not installed or not in PATH"
    return 1
  fi
  return 0
}

# Check if fzf is available, returning error if not
_fzf_check() {
  if ! has_command fzf; then
    log_error "fzf is required for this operation. Install with: brew install fzf"
    return 1
  fi
  return 0
}

# Handle Brewfile path parameter, supporting --global flag
# Usage: local brewfile=$(_brewfile_path "$1")
_brewfile_path() {
  local param="${1:-$_BREWFILE}"
  
  if [[ "$param" == "--global" ]]; then
    echo "--global"
  else
    echo "${param:-$_BREWFILE}"
  fi
}

# Add selected items to Brewfile
# Usage: _add_to_brewfile "brew" "package1 package2"
_add_to_brewfile() {
  local type="$1"  # "brew", "cask", "tap", etc.
  local items="$2"
  local brewfile="${3:-$_BREWFILE}"
  
  if [[ ! -f "$brewfile" ]]; then
    touch "$brewfile"
  fi
  
  log_info "Adding to Brewfile: $items"
  
  local count=0
  for item in ${(f)items}; do
    if ! grep -q "^$type \"$item\"$" "$brewfile"; then
      echo "$type \"$item\"" >> "$brewfile"
      ((count++))
    fi
  done
  
  if [[ $count -gt 0 ]]; then
    log_success "Added $count packages to Brewfile at $brewfile"
  else
    log_info "All packages already in Brewfile"
  fi
}

# ========================================================================
# Basic Brew Commands (b_*)
# ========================================================================

# Update all Homebrew packages
export function b_update() {
  _brew_check || return 1
  
  log_info "Updating Homebrew..."
  brew update && brew upgrade && brew cleanup
  log_success "Homebrew packages updated and cleaned up"
}

# Remove unused Homebrew packages and clean up
export function b_cleanup() {
  _brew_check || return 1
  
  log_info "Cleaning up Homebrew packages..."
  brew cleanup --prune=all
  brew autoremove
  log_success "Removed unused packages and cleaned up"
}

# Install a Homebrew package with error handling
export function b_install() {
  _brew_check || return 1
  
  if [[ -z "$1" ]]; then
    log_error "No package specified. Usage: b_install <package>"
    return 1
  fi
  
  log_info "Installing $1..."
  if brew install "$1"; then
    log_success "Installed $1 successfully"
    return 0
  else
    log_error "Failed to install $1"
    return 1
  fi
}

# Install a Homebrew cask with error handling
export function b_cask() {
  _brew_check || return 1
  
  if [[ -z "$1" ]]; then
    log_error "No cask specified. Usage: b_cask <cask>"
    return 1
  fi
  
  log_info "Installing cask $1..."
  if brew install --cask "$1"; then
    log_success "Installed cask $1 successfully"
    return 0
  else
    log_error "Failed to install cask $1"
    return 1
  fi
}

# Show package information
export function b_info() {
  _brew_check || return 1
  
  if [[ -z "$1" ]]; then
    log_error "No package specified. Usage: b_info <package>"
    return 1
  fi
  
  brew info "$1"
}

# List installed packages
export function b_list() {
  _brew_check || return 1
  
  case "$1" in
    casks)
      log_info "Installed casks:"
      brew list --cask
      ;;
    leaves)
      log_info "Installed leaf packages (not dependencies):"
      brew leaves
      ;;
    *)
      log_info "Installed packages:"
      brew list
      ;;
  esac
}

# Remove a package
export function b_remove() {
  _brew_check || return 1
  
  if [[ -z "$1" ]]; then
    log_error "No package specified. Usage: b_remove <package>"
    return 1
  fi
  
  log_info "Removing $1..."
  if brew uninstall "$1"; then
    log_success "Removed $1 successfully"
    return 0
  else
    log_error "Failed to remove $1"
    return 1
  fi
}

# ========================================================================
# Brewfile Commands (bb_*)
# ========================================================================

# Install packages from Brewfile
export function bb_install() {
  _brew_check || return 1
  
  local brewfile=$(_brewfile_path "$1")
  local is_global=false
  local file_flag=""
  
  if [[ "$brewfile" == "--global" ]]; then
    is_global=true
    log_info "Installing packages from global Brewfile..."
  else
    if [[ ! -f "$brewfile" ]]; then
      log_error "Brewfile not found at $brewfile"
      return 1
    fi
    log_info "Installing packages from $brewfile..."
    file_flag="--file=$brewfile"
  fi
  
  local cmd="brew bundle install --verbose"
  [[ "$is_global" == true ]] && cmd="$cmd --global" || cmd="$cmd $file_flag"
  cmd="$cmd --cleanup"
  
  if eval "$cmd"; then
    log_success "Installed all packages from Brewfile"
    return 0
  else
    log_error "Failed to install packages from Brewfile"
    return 1
  fi
}

# Check if all packages in Brewfile are installed
export function bb_check() {
  _brew_check || return 1
  
  local brewfile=$(_brewfile_path "$1")
  local is_global=false
  local file_flag=""
  
  if [[ "$brewfile" == "--global" ]]; then
    is_global=true
  else
    file_flag="--file=$brewfile"
  fi
  
  log_info "Checking Brewfile status..."
  
  local cmd="brew bundle check --verbose"
  [[ "$is_global" == true ]] && cmd="$cmd --global" || cmd="$cmd $file_flag"
  
  if eval "$cmd"; then
    log_success "All packages in Brewfile are installed"
    return 0
  else
    log_warn "Some packages in Brewfile are not installed"
    return 1
  fi
}

# Create a Brewfile from currently installed packages
export function bb_dump() {
  _brew_check || return 1
  
  local brewfile=$(_brewfile_path "$1")
  local is_global=false
  local file_flag=""
  
  if [[ "$brewfile" == "--global" ]]; then
    is_global=true
    log_info "Dumping to global Brewfile..."
  else
    log_info "Dumping to $brewfile..."
    file_flag="--file=$brewfile"
  fi
  
  local cmd="brew bundle dump --verbose"
  [[ "$is_global" == true ]] && cmd="$cmd --global" || cmd="$cmd $file_flag"
  cmd="$cmd --force"
  
  if eval "$cmd"; then
    log_success "Created Brewfile successfully"
    return 0
  else
    log_error "Failed to create Brewfile"
    return 1
  fi
}

# List packages that would be removed (not in Brewfile)
export function bb_list_cleanup() {
  _brew_check || return 1
  
  local brewfile=$(_brewfile_path "$1")
  local is_global=false
  local file_flag=""
  
  if [[ "$brewfile" == "--global" ]]; then
    is_global=true
  else
    file_flag="--file=$brewfile"
  fi
  
  log_info "Packages that would be removed (not in Brewfile):"
  
  local cmd="brew bundle cleanup --verbose"
  [[ "$is_global" == true ]] && cmd="$cmd --global" || cmd="$cmd $file_flag"
  
  eval "$cmd"
}

# Remove packages not in Brewfile
export function bb_cleanup() {
  _brew_check || return 1
  
  local brewfile=$(_brewfile_path "$1")
  local is_global=false
  local file_flag=""
  
  if [[ "$brewfile" == "--global" ]]; then
    is_global=true
  else
    file_flag="--file=$brewfile"
  fi
  
  log_info "Analyzing packages not in Brewfile..."
  
  # Show what would be removed first
  local cmd="brew bundle cleanup --verbose"
  [[ "$is_global" == true ]] && cmd="$cmd --global" || cmd="$cmd $file_flag"
  
  local to_remove=$(eval "$cmd")
  
  if [[ -z "$to_remove" ]]; then
    log_info "No packages to remove"
    return 0
  fi
  
  log_info "The following packages will be removed:"
  echo "$to_remove"
  
  echo ""
  echo "Proceed with removal? (y/n)"
  read -k 1 confirm
  echo ""
  
  if [[ "$confirm" == "y" ]]; then
    cmd="$cmd --force"
    if eval "$cmd"; then
      log_success "Removed packages not in Brewfile"
      return 0
    else
      log_error "Failed to remove packages"
      return 1
    fi
  else
    log_info "Cleanup canceled"
    return 0
  fi
}

# Edit Brewfile
export function bb_edit() {
  _brew_check || return 1
  
  local brewfile=$(_brewfile_path "$1")
  
  if [[ "$brewfile" == "--global" ]]; then
    brew bundle edit --global
  else
    if [[ ! -f "$brewfile" ]]; then
      log_warn "Brewfile not found at $brewfile, creating new file"
      touch "$brewfile"
    fi
    
    ${EDITOR:-vi} "$brewfile"
  fi
}

# ========================================================================
# Interactive Brew Management (fzf-based)
# ========================================================================

# Interactive package selection and installation
export function bf_install() {
  _brew_check || return 1
  _fzf_check || return 1
  
  log_info "Searching packages..."
  
  local selected
  selected=$(brew search | fzf -m \
    --header="Select packages to install (TAB: multiple, SPACE: preview)" \
    --preview="brew info {}" \
    --preview-window=right:70% \
    --bind=space:toggle-preview)
  
  if [[ -n "$selected" ]]; then
    log_info "Installing: $selected"
    brew install ${(f)selected}
    log_success "Installation complete"
    
    # Prompt to add to Brewfile
    echo "Add to Brewfile? (y/n)"
    read -k 1 add_to_brewfile
    echo ""
    
    if [[ "$add_to_brewfile" == "y" ]]; then
      _add_to_brewfile "brew" "$selected"
    fi
    
    return 0
  else
    log_info "No packages selected"
    return 0
  fi
}

# Interactive cask selection and installation
export function bf_cask() {
  _brew_check || return 1
  _fzf_check || return 1
  
  log_info "Searching casks..."
  
  local selected
  selected=$(brew search --casks | fzf -m \
    --header="Select casks to install (TAB: multiple, SPACE: preview)" \
    --preview="brew info --cask {}" \
    --preview-window=right:70% \
    --bind=space:toggle-preview)
  
  if [[ -n "$selected" ]]; then
    log_info "Installing casks: $selected"
    brew install --cask ${(f)selected}
    log_success "Installation complete"
    
    # Prompt to add to Brewfile
    echo "Add to Brewfile? (y/n)"
    read -k 1 add_to_brewfile
    echo ""
    
    if [[ "$add_to_brewfile" == "y" ]]; then
      _add_to_brewfile "cask" "$selected"
    fi
    
    return 0
  else
    log_info "No casks selected"
    return 0
  fi
}

# Interactive package removal
export function bf_remove() {
  _brew_check || return 1
  _fzf_check || return 1
  
  log_info "Listing installed packages..."
  
  local selected
  selected=$(brew list | fzf -m \
    --header="Select packages to remove (TAB: multiple, SPACE: preview)" \
    --preview="brew info {}" \
    --preview-window=right:70% \
    --bind=space:toggle-preview)
  
  if [[ -n "$selected" ]]; then
    log_info "Removing: $selected"
    brew uninstall ${(f)selected}
    log_success "Removal complete"
    return 0
  else
    log_info "No packages selected"
    return 0
  fi
}

# Interactive tap selection
export function bf_tap() {
  _brew_check || return 1
  _fzf_check || return 1
  
  log_info "Loading available taps..."
  
  # Get top taps from GitHub
  local top_taps=(
    "homebrew/cask"
    "homebrew/cask-fonts"
    "homebrew/cask-versions"
    "homebrew/core"
    "homebrew/services"
    "hashicorp/tap"
    "mongodb/brew"
    "neovim/neovim"
    "heroku/brew"
    "cloudflare/cloudflare"
  )
  
  # Combine with currently tapped
  local current_taps=$(brew tap)
  local all_taps=("${top_taps[@]}" "${(f)current_taps}")
  
  # Remove duplicates
  local unique_taps=($(echo "${all_taps[@]}" | tr ' ' '\n' | sort -u))
  
  local selected
  selected=$(printf "%s\n" "${unique_taps[@]}" | fzf -m \
    --header="Select taps to add (TAB: multiple)" \
    --preview="brew tap-info {}" \
    --preview-window=right:70% \
    --bind=space:toggle-preview)
  
  if [[ -n "$selected" ]]; then
    log_info "Adding taps: $selected"
    for tap in ${(f)selected}; do
      brew tap "$tap"
    done
    log_success "Taps added successfully"
    
    # Prompt to add to Brewfile
    echo "Add to Brewfile? (y/n)"
    read -k 1 add_to_brewfile
    echo ""
    
    if [[ "$add_to_brewfile" == "y" ]]; then
      _add_to_brewfile "tap" "$selected"
    fi
    
    return 0
  else
    log_info "No taps selected"
    return 0
  fi
}

# Interactive command selection and execution
export function brew() {
  if ! has_command fzf || [[ $# -gt 0 ]]; then
    # If fzf not available or args provided, pass through to normal brew
    command brew "$@"
    return $?
  fi
  
  # Define commands and descriptions
  local commands=(
    "update:Update Homebrew and all packages:brew update && brew upgrade && brew cleanup"
    "install:Install a package:brew install"
    "cask:Install a cask:brew install --cask"
    "info:Show package information:brew info"
    "search:Search for a package:brew search"
    "list:List installed packages:brew list"
    "leaves:List leaf packages (not dependencies):brew leaves"
    "deps:Show dependency tree:brew deps --tree --installed"
    "doctor:Run brew diagnostics:brew doctor"
    "tap:Add a tap repository:brew tap"
    "casks:List installed casks:brew list --cask"
    "services:Manage background services:brew services"
    "cleanup:Remove old versions:brew cleanup"
    "autoremove:Remove unused dependencies:brew autoremove"
    "outdated:Show outdated packages:brew outdated"
    "pin:Pin a package to prevent upgrades:brew pin"
    "unpin:Unpin a package:brew unpin"
    "uses:Show formulas that depend on specified formula:brew uses --installed"
  )
  
  # Show interactive menu with fzf
  local selected
  selected=$(printf "%s\n" "${commands[@]}" | 
    awk -F: '{printf "%-15s %s\n", $1, $2}' |
    fzf --header="Select a brew command" \
        --preview="echo; echo Description: {2..}; echo; echo Command: $(echo {3..} | sed 's/^//')" \
        --preview-window=bottom:3:wrap)
  
  if [[ -n "$selected" ]]; then
    local cmd=$(echo "$selected" | awk '{print $1}')
    local idx=0
    local cmd_line=""
    
    # Find the matching command
    for c in "${commands[@]}"; do
      local cmd_name=$(echo "$c" | cut -d: -f1)
      if [[ "$cmd_name" == "$cmd" ]]; then
        cmd_line=$(echo "$c" | cut -d: -f3)
        break
      fi
    done
    
    if [[ -n "$cmd_line" ]]; then
      log_info "Executing: $cmd_line"
      eval "$cmd_line"
    fi
  fi
}

# ========================================================================
# Main Command Selector
# ========================================================================

# Main command selector using fzf if available
export function b() {
  if [[ $# -gt 0 ]]; then
    # Direct execution if args provided
    case "$1" in
      # Basic brew operations
      update|up)     b_update ;;
      cleanup|clean) b_cleanup ;;
      install|in)    shift; b_install "$@" ;;
      cask)          shift; b_cask "$@" ;;
      info)          shift; b_info "$@" ;;
      list|ls)       shift; b_list "$@" ;;
      remove|rm)     shift; b_remove "$@" ;;
      
      # Interactive operations with fzf
      fin)           bf_install ;;
      fcask)         bf_cask ;;
      frm)           bf_remove ;;
      ftap)          bf_tap ;;
      
      # Help and default case
      help|--help|-h) _show_brew_help ;;
      *)
        # Pass through to brew
        command brew "$@"
        ;;
    esac
    return $?
  fi
  
  # Interactive selection with fzf if no args
  if has_command fzf; then
    _select_brew_command
  else
    _show_brew_help
  fi
}

# Brewfile operations command
export function bb() {
  if [[ $# -gt 0 ]]; then
    # Direct execution if args provided
    case "$1" in
      install|in)      shift; bb_install "$@" ;;
      check|c)         shift; bb_check "$@" ;;
      dump|d)          shift; bb_dump "$@" ;;
      list-cleanup|lc) shift; bb_list_cleanup "$@" ;;
      cleanup|c)       shift; bb_cleanup "$@" ;;
      edit|e)          shift; bb_edit "$@" ;;
      
      # Help and default case
      help|--help|-h)  _show_brewfile_help ;;
      *)
        log_error "Unknown Brewfile command: $1"
        _show_brewfile_help
        return 1
        ;;
    esac
    return $?
  fi
  
  # Interactive selection with fzf if no args
  if has_command fzf; then
    _select_brewfile_command
  else
    _show_brewfile_help
  fi
}

# ========================================================================
# Help Functions
# ========================================================================

# Display brew commands help
_show_brew_help() {
  echo "Homebrew management utility"
  echo ""
  echo "Usage: b <command> [arguments]"
  echo ""
  echo "Basic Commands:"
  echo "  update, up       Update Homebrew and upgrade all packages"
  echo "  cleanup, clean   Clean up and remove unused packages"
  echo "  install, in      Install a package"
  echo "  cask             Install a cask"
  echo "  info             Show package information"
  echo "  list, ls         List installed packages"
  echo "  remove, rm       Remove a package"
  echo ""
  echo "Interactive Commands (require fzf):"
  echo "  fin              Interactive package installation"
  echo "  fcask            Interactive cask installation"
  echo "  frm              Interactive package removal"
  echo "  ftap             Interactive tap selection"
  echo ""
  echo "Use 'bb' for Brewfile operations"
}

# Display brewfile commands help
_show_brewfile_help() {
  echo "Brewfile management utility"
  echo ""
  echo "Usage: bb <command> [arguments]"
  echo ""
  echo "Commands:"
  echo "  install, in      Install packages from Brewfile"
  echo "  check, c         Check if all packages in Brewfile are installed"
  echo "  dump, d          Create Brewfile from installed packages"
  echo "  list-cleanup, lc List packages not in Brewfile"
  echo "  cleanup, c       Remove packages not in Brewfile"
  echo "  edit, e          Edit Brewfile"
}

# Interactive command selection for brew
_select_brew_command() {
  _fzf_check || { _show_brew_help; return 1; }
  
  local commands=(
    "update:Update Homebrew and upgrade all packages:b_update"
    "cleanup:Clean up and remove unused packages:b_cleanup"
    "install:Install a package (interactive):bf_install"
    "cask:Install a cask (interactive):bf_cask"
    "remove:Remove packages (interactive):bf_remove"
    "tap:Add a tap repository (interactive):bf_tap"
    "list:List installed packages:b_list"
    "leaves:List leaf packages (not dependencies):b_list leaves"
    "casks:List installed casks:b_list casks"
  )
  
  local selected
  selected=$(printf "%s\n" "${commands[@]}" | 
    awk -F: '{printf "%-15s %s\n", $1, $2}' |
    fzf --header="Select a brew command" \
        --preview="echo; echo Description: {2..}; echo" \
        --preview-window=bottom:3:wrap)
  
  if [[ -n "$selected" ]]; then
    local cmd=$(echo "$selected" | awk '{print $1}')
    local idx=0
    local function_name=""
    
    # Find the matching command
    for c in "${commands[@]}"; do
      local cmd_name=$(echo "$c" | cut -d: -f1)
      if [[ "$cmd_name" == "$cmd" ]]; then
        function_name=$(echo "$c" | cut -d: -f3)
        break
      fi
    done
    
    if [[ -n "$function_name" ]]; then
      log_info "Executing: $function_name"
      $function_name
    fi
  fi
}

# Interactive command selection for brewfile
_select_brewfile_command() {
  _fzf_check || { _show_brewfile_help; return 1; }
  
  local commands=(
    "install:Install packages from Brewfile:bb_install"
    "check:Check if all packages in Brewfile are installed:bb_check"
    "dump:Create Brewfile from installed packages:bb_dump"
    "list-cleanup:List packages not in Brewfile:bb_list_cleanup"
    "cleanup:Remove packages not in Brewfile:bb_cleanup"
    "edit:Edit Brewfile:bb_edit"
  )
  
  local selected
  selected=$(printf "%s\n" "${commands[@]}" | 
    awk -F: '{printf "%-15s %s\n", $1, $2}' |
    fzf --header="Select a Brewfile command" \
        --preview="echo; echo Description: {2..}; echo" \
        --preview-window=bottom:3:wrap)
  
  if [[ -n "$selected" ]]; then
    local cmd=$(echo "$selected" | awk '{print $1}')
    local idx=0
    local function_name=""
    
    # Find the matching command
    for c in "${commands[@]}"; do
      local cmd_name=$(echo "$c" | cut -d: -f1)
      if [[ "$cmd_name" == "$cmd" ]]; then
        function_name=$(echo "$c" | cut -d: -f3)
        break
      fi
    done
    
    if [[ -n "$function_name" ]]; then
      log_info "Executing: $function_name"
      $function_name
    fi
  fi
}

# ========================================================================
# Initialize on Load
# ========================================================================

# Output summary when this file is sourced
log_info "Homebrew utilities loaded"
log_info "Use 'b' for brew commands and 'bb' for brewfile commands"
log_info "Run without arguments for interactive selection (if fzf is installed)"

# Initialize Homebrew
# brew_init

if ! has_command brew; then
  log_error "Homebrew is not installed"
  log_info "Installing Homebrew..."
  
  return 1
fi

# Automatically check setup
if has_command brew; then
  log_success "Homebrew is installed at: $(brew --prefix)"
fi
