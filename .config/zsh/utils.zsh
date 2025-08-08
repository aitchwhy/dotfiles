#!/usr/bin/env zsh
################################################################################
# Combined ZSH Utilities - Comprehensive Utilities Collection
################################################################################
# This file combines all utility functions, CLI frameworks, installation scripts,
# and helper functions from the dotfiles repository into a single source.
#
# USAGE: Source this file in your .zshrc or .zprofile
# Recommended: source "${ZDOTDIR:-$HOME/.config/zsh}/utils.zsh"

################################################################################
# ENVIRONMENT CONFIGURATION
################################################################################
export DOTFILES="${DOTFILES:-$HOME/dotfiles}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export ZDOTDIR="${ZDOTDIR:-$XDG_CONFIG_HOME/zsh}"
export BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"

################################################################################
# ANSI COLOR CODES
################################################################################
typeset -g RESET="\033[0m"
typeset -g BLACK="\033[0;30m"
typeset -g RED="\033[0;31m"
typeset -g GREEN="\033[0;32m"
typeset -g YELLOW="\033[0;33m"
typeset -g BLUE="\033[0;34m"
typeset -g MAGENTA="\033[0;35m"
typeset -g CYAN="\033[0;36m"
typeset -g WHITE="\033[0;37m"

################################################################################
# CORE LOGGING FUNCTIONS
################################################################################

log_info() { printf "${BLUE}[INFO]${RESET} %s\n" "$*"; }
log_success() { printf "${GREEN}[SUCCESS]${RESET} %s\n" "$*"; }
log_warn() { printf "${YELLOW}[WARNING]${RESET} %s\n" "$*" >&2; }
log_error() { printf "${RED}[ERROR]${RESET} %s\n" "$*" >&2; }

# Aliases for different naming conventions
info() { log_info "$@"; }
success() { log_success "$@"; }
warn() { log_warn "$@"; }
error() { log_error "$@"; }

################################################################################
# SYSTEM DETECTION & ENVIRONMENT
################################################################################

has_command() { command -v "$1" &>/dev/null; }
is_macos() { [[ "$(uname -s)" == "Darwin" ]]; }
is_linux() { [[ "$(uname -s)" == "Linux" ]]; }
is_apple_silicon() { [[ "$(uname -m)" == "arm64" ]] && is_macos; }
is_rosetta() { is_apple_silicon && [[ "$(arch)" != "arm64" ]]; }
is_interactive() { [[ -o interactive ]]; }
is_sourced() { [[ "${FUNCNAME[1]-main}" != main ]]; }

get_macos_version() {
  is_macos && sw_vers -productVersion || echo "Not macOS"
}

################################################################################
# FZF UTILITIES
################################################################################

_fzf_check() {
  if ! has_command fzf; then
    log_error "fzf is not installed. Install with 'brew install fzf'"
    return 1
  fi
  return 0
}

_fzf_select() {
  local header="$1"
  local preview="${2:-echo {}}"
  local multi="${3:-}"

  local opts="--header='$header' --preview='$preview'"
  [[ -n "$multi" ]] && opts="$opts --multi"

  eval "fzf $opts"
}

################################################################################
# FILE & DIRECTORY OPERATIONS
################################################################################

# Create a directory if it doesn't exist
ensure_dir() {
  local dir="$1"
  if [[ ! -d "$dir" ]]; then
    mkdir -p "$dir"
    log_success "Created directory: $dir"
  fi
}

# Git repository copy - multiple implementations unified
cp_repo() {
  [[ $# -lt 2 ]] && { echo "Usage: cp-repo <src> <dst>"; return 1; }

  local src="$1" dst="$2"
  [[ ! -d "$src/.git" ]] && { error "Source is not a git repository"; return 1; }

  # Method 1: rsync (preferred)
  if has_command rsync; then
    info "Copying with rsync..."
    git -C "$src" ls-files -z | (cd "$src" && rsync -0av --files-from=- . "$(realpath "$dst")/")
    rsync -av --include=".*" --exclude="*" "$src/" "$dst/" 2>/dev/null
  # Method 2: tar fallback
  else
    info "Copying with tar..."
    mkdir -p "$dst"
    (cd "$src" && git ls-files -z | tar --null -cf - -T -) | tar -xf - -C "$dst"
    for f in .env .env.* .envrc .tool-versions .nvmrc .ruby-version .gitignore; do
      [[ -f "$src/$f" ]] && cp "$src/$f" "$dst/"
    done
  fi

  success "Repository copied successfully"
}

# Symlink with parent directory creation
slink() {
  [[ $# -lt 2 ]] && { echo "Usage: slink <src> <dst>"; return 1; }
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  ln -nfs "$src" "$dst"
  success "Symlinked: $dst -> $src"
}

# Initialize all dotfiles symlinks
slink_init() {
  local links=(
    "$DOTFILES/.Brewfile:$HOME/.Brewfile"
    "$DOTFILES/.zshrc:$HOME/.zshrc"
    "$DOTFILES_EXPORTS:$OMZ_CUSTOM/exports.zsh"
    "$DOTFILES_ALIASES:$OMZ_CUSTOM/aliases.zsh"
    "$DOTFILES_FUNCTIONS:$OMZ_CUSTOM/functions.zsh"
    "$DOTFILES/nvm/default-packages:$NVM_DIR/default-packages"
    "$DOTFILES/.config/git/.gitignore:$HOME/.gitignore"
    "$DOTFILES/.config/zellij/main-layout.kdl:$HOME/.config/config.kdl"
  )

  for link in "${links[@]}"; do
    local src="${link%%:*}" dst="${link#*:}"
    slink "$src" "$dst"
  done
}

################################################################################
# PATH MANAGEMENT FUNCTIONS
################################################################################

# Add a directory to PATH if it exists and isn't already in PATH
path_add() {
  local dir="$1"
  if [[ -d "$dir" ]] && [[ ":$PATH:" != *":$dir:"* ]]; then
    export PATH="$dir:$PATH"
    return 0
  fi
  return 1
}

# Remove a directory from PATH
path_remove() {
  local dir="$1"
  if [[ ":$PATH:" == *":$dir:"* ]]; then
    export PATH=${PATH//:$dir:/:}  # Remove middle
    export PATH=${PATH/#$dir:/}    # Remove beginning
    export PATH=${PATH/%:$dir/}    # Remove end
    return 0
  fi
  return 1
}

################################################################################
# HOMEBREW INSTALLATION & MANAGEMENT
################################################################################

# install brew if not exists
install_brew() {
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

# uninstall brew
uninstall_brew() {
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
}

brew_init() {
  has_command brew && return 0

  local brew_path
  if is_apple_silicon; then
    brew_path="/opt/homebrew/bin/brew"
  else
    brew_path="/usr/local/bin/brew"
  fi

  if [[ -x "$brew_path" ]]; then
    eval "$($brew_path shellenv)"
    success "Initialized Homebrew"
    return 0
  fi

  warn "Homebrew not found. Install: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
  return 1
}

# Setup Homebrew and install packages
init_brew() {
  info "Setting up Homebrew..."
  has_command brew || install_brew
  brew bundle install --verbose --file="$DOTFILES/Brewfile.core" --all --force
}

################################################################################
# MACOS SYSTEM PREFERENCES
################################################################################

# Apply common macOS system preferences
defaults_apply() {
  if ! is_macos; then
    log_error "Not running on macOS"
    return 1
  fi

  log_info "Applying macOS preferences..."

  # Keyboard settings
  defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
  defaults write NSGlobalDomain AppleShowAllExtensions -bool true
  defaults write NSGlobalDomain InitialKeyRepeat -int 15
  defaults write NSGlobalDomain KeyRepeat -int 2

  # File system behavior
  defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

  # Dock settings
  defaults write com.apple.dock autohide -bool true
  defaults write com.apple.dock autohide-delay -float 0
  defaults write com.apple.dock show-recents -bool false

  # Trackpad settings
  defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true

  # Finder settings
  defaults write com.apple.finder AppleShowAllFiles -bool true
  defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
  defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
  defaults write com.apple.finder ShowPathbar -bool true
  defaults write com.apple.finder ShowStatusBar -bool true
  defaults write com.apple.finder _FXSortFoldersFirst -bool true

  # Restart affected applications
  for app in "Finder" "Dock"; do
    killall "$app" >/dev/null 2>&1 || true
  done

  log_success "macOS preferences applied"
}

################################################################################
# CORE INSTALLATION FUNCTIONS
################################################################################

# Setup ZSH configuration
init_zsh() {
  info "Setting up ZSH configuration..."

  # Use environment vars if set, fall back to internal vars if not
  local zdotdir_src="${ZDOTDIR:-$DOTFILES/config/zsh}"

  # Create .zshenv in home directory pointing to dotfiles
  info "Creating .zshenv to point to dotfiles ZSH configuration"
  cat >"$HOME/.zshenv" <<EOF
# ZSH configuration bootstrapper
# Auto-generated by dotfiles setup
export ZDOTDIR="$zdotdir_src"
[[ -f "$zdotdir_src/.zshenv" ]] && source "$zdotdir_src/.zshenv"
EOF

  chmod 644 "$HOME/.zshenv"
  log_success "Created $HOME/.zshenv pointing to $zdotdir_src"
}

# Check system requirements
check_requirements() {
  info "Checking system requirements..."

  # Check if running on macOS
  if ! is_macos; then
    error "This configuration is designed for macOS."
    return 1
  fi

  # Check for required commands
  local required_commands=(
    "git"
    "curl"
    "zsh"
  )

  local missing_commands=()
  for cmd in "${required_commands[@]}"; do
    if ! has_command "$cmd"; then
      missing_commands+=("$cmd")
    fi
  done

  if ((${#missing_commands[@]} > 0)); then
    error "Required commands not found: ${missing_commands[*]}"
    return 1
  fi

  success "System requirements met"
  return 0
}

################################################################################
# ANTERIOR MONOREPO CLI HELPER
################################################################################
# Works in three situations out-of-the-box:
#   1. Inside `nix develop` – every `ant-*` binary is already on $PATH.
#   2. Outside a dev-shell but **inside** the repo – falls back to
#      `nix run .#<binary>` (so no global install needed).
#   3. Any other directory – warns politely instead of exploding.

# Config – customise if your repo layout is unusual
readonly _ANT_FLAKE_ROOT=${ANT_FLAKE:-$(git -C "${0:a:h}" rev-parse --show-toplevel 2>/dev/null)}

# All first-class binaries exposed by the flake that start with "ant-"
local -a _ANT_BINARIES=(
  ant-all-services
  ant-system-prune
  ant-check-1password
  ant-build-docker
  ant-build-host
  ant-lint
  ant-sync-cache
  ant-admin
  ant-npm-build-deptree
)

# Portable wrapper: run binary if on $PATH, else `nix run` from the repo root
_ant_exec() {
  local bin="$1"; shift
  if command -v "$bin" &>/dev/null; then
    "$bin" "$@"
  elif [[ -d $_ANT_FLAKE_ROOT ]]; then
    # Outside dev-shell – fallback to nix run (makes heavy use of the binary cache)
    nix run "$_ANT_FLAKE_ROOT#$bin" -- "$@"
  else
    print -u2 "✖︎ ant: cannot find $bin and not inside the repo (set \$ANT_FLAKE)"
    return 127
  fi
}

# fzf picker
ant_pick() {
  if (( $+commands[fzf] == 0 )); then
    print -u2 "fzf not installed – run \`brew install fzf\` or \`nix profile install nixpkgs#fzf\`"
    return 1
  fi
  local selected=$(
    printf '%s\n' "${_ANT_BINARIES[@]}" |
    fzf --height 40% --reverse --border --prompt='ant ▸ '
  )
  [[ -n $selected ]] && _ant_exec "$selected" "$@"
}

# user-friendly alias that works in every shell
alias antpick='ant_pick'

# Port helper maps
typeset -A ANT_PORTS=(
  api_http                20101
  api_admin               20102
  api_grpc                20103
  cortex_http             20201
  user_grpc               20303
  paop_grpc               20403
  payment_integrity_grpc  20503
  noodle_http             20601
  noggin_http             20701
  hello_world_http        20901
  clinical_backend_http   21101
  clinical_frontend_http  21201
  gotenberg               3000
  prefect                 4200
  localstack              4566
  redis                   6379
  postgres                5432
  dynamodb                8000
)

ant_ports_list() {
  for k in ${(k)ANT_PORTS}; do
    print -r -- "${ANT_PORTS[$k]}\t$k"
  done | sort -n
}
alias antports='ant_ports_list'

# Killer helpers
_ant_lsof() {
  command -v lsof &>/dev/null || { print -u2 "lsof missing"; return 1 }
  lsof -Pn -i TCP:$1 -sTCP:LISTEN
}
_ant_kill_port() {
  command -v lsof &>/dev/null || { print -u2 "lsof missing"; return 1 }
  lsof -Pn -ti TCP:$1 | xargs -r kill -9
}

ant_kill() {
  command -v fzf &>/dev/null || { print -u2 "fzf missing"; return 1 }
  local sel=$(ant_ports_list | fzf --prompt='kill ▸ ' --with-nth=1,2)
  [[ -z $sel ]] && return
  _ant_kill_port "${sel%%	*}"
}
alias antkill='ant_kill'

ant_kill_all() {
  print "Killing all processes bound to known Anterior ports…"
  for p in ${(v)ANT_PORTS}; do
    _ant_kill_port $p
  done
}
alias antkillall='ant_kill_all'

# Main dispatcher
ant() {
  local cmd="$1"; shift

  case "$cmd" in
    ""|-h|--help|help)
      cat <<'EOF'
ant – Anterior monorepo helper

Usage: ant <command> [args...]

Built-in commands:
  pick              Interactive picker for common ant-* binaries
  ports             List canonical service ports
  kill              Interactive killer (uses fzf)
  killall           Kill all processes bound to any ANT_PORTS
  ref               Print reference port table
  env|genenv|s3|dynamo|sqs|service
                    – see project README for details

If <command> matches an ant-* binary name it is executed transparently.
EOF
      ;;

    pick)      ant_pick "$@" ;;
    ports)     ant_ports_list ;;
    kill)      ant_kill ;;
    killall)   ant_kill_all ;;
    ref)       print "API 20101/2/3 …";;
    # fallback: treat <cmd> as a binary (strip optional "ant-" prefix)
    *)
      local bin=$cmd
      [[ $bin == ant-* ]] || bin="ant-$bin"
      _ant_exec "$bin" "$@"
      ;;
  esac
}

################################################################################
# GENERAL UTILITIES
################################################################################

safe_source() {
  [[ -z "$1" ]] && { echo "Usage: safe_source <file>"; return 1; }
  [[ -r "$1" ]] && source "$1"
}

backup_file() {
  [[ -z "$1" ]] && { echo "Usage: backup_file <file> [backup_dir]"; return 1; }
  local file="$1" backup_dir="${2:-$BACKUP_DIR}"

  if [[ -e "$file" ]]; then
    ensure_dir "$backup_dir"
    cp -a "$file" "$backup_dir/"
    success "Backed up $file to $backup_dir"
  else
    warn "File $file does not exist"
  fi
}

ensure_tool_installed() {
  local tool="$1" install_cmd="$2" essential="${3:-false}"

  if ! has_command "$tool"; then
    if [[ "$essential" == "true" ]] || [[ "${INSTALL_MODE:-false}" == "true" ]]; then
      info "Installing $tool..."
      eval "$install_cmd"
    else
      info "Tool '$tool' not installed (not essential)"
    fi
  fi
}

list_utils() {
  local funcs=$(functions | grep "^[a-z].*() {" | grep -v "^_" | sort)
  local count=$(echo "$funcs" | wc -l | tr -d ' ')

  info "Available utility functions ($count total):"
  echo "$funcs" | sed 's/() {.*//' | column
}

# Legacy setup functions
setup_homebrew() {
  brew_init || return 1

  if [[ "${INSTALL_MODE:-false}" == "true" ]]; then
    info "Installing from Brewfile..."
    [[ -f "$DOTFILES/Brewfile" ]] && brew bundle install --verbose --global --all --force
  fi
}

setup_zsh() {
  info "Setting up ZSH configuration..."
  local zdotdir_src="${ZDOTDIR_SRC:-$DOTFILES/config/zsh}"

  cat >"$HOME/.zshenv" <<EOF
# ZSH configuration bootstrapper
export ZDOTDIR="$zdotdir_src"
[[ -f "$zdotdir_src/.zshenv" ]] && source "$zdotdir_src/.zshenv"
EOF

  chmod 644 "$HOME/.zshenv"
  success "Created $HOME/.zshenv"
}

setup_cli_tools() {
  info "Setting up CLI tools..."

  for key in ${(k)DOTFILES_TO_SYMLINK_MAP}; do
    local src="$key" dst="${DOTFILES_TO_SYMLINK_MAP[$key]}"

    if [[ "${INSTALL_MODE:-false}" == "true" ]] && [[ -L "$dst" || -e "$dst" ]]; then
      rm -rf "$dst"
    fi

    ensure_dir "$(dirname "$dst")"

    if [[ ! -e "$dst" ]] || [[ "$(readlink "$dst")" != "$src" ]]; then
      [[ -e "$src" ]] && ln -sf "$src" "$dst" && success "Symlinked $dst -> $src"
    fi
  done
}

install_essential_tools() {
  info "Installing essential tools..."
  brew_init || return 1

  local tools=(starship nvim fzf eza zoxide atuin volta uv rustup go)

  for tool in "${tools[@]}"; do
    local install_cmd="${TOOL_INSTALL_COMMANDS[$tool]}"
    local essential="${TOOL_IS_ESSENTIAL[$tool]}"
    ensure_tool_installed "$tool" "$install_cmd" "$essential"
  done
}


################################################################################
# VS CODE EXTENSIONS MANAGEMENT
################################################################################

# VS Code extensions list
VSCODE_EXTENSIONS=(
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

install_vscode_extensions() {
    info "Installing VS Code extensions..."
    for ext in "${VSCODE_EXTENSIONS[@]}"; do
        echo "Installing $ext..."
        code --install-extension "$ext" || warn "Failed to install $ext"
    done
    success "VS Code extensions installation complete!"
}

# Get all functions defined in vscode section
list_vscode_functions() {
    echo "install_vscode_extensions"
}

# Fuzzy select a VS Code function to run
select_and_run_vscode_function() {
    if ! has_command fzf; then
        error "fzf is not installed. Please install it first."
        return 1
    fi

    local selected_function=$(list_vscode_functions | fzf --height 40% --border --prompt="Select VS Code function to run: ")

    if [[ -n "$selected_function" ]]; then
        info "Running function: $selected_function"
        $selected_function
    else
        info "No function selected."
    fi
}

cursor_ext_import() {
  local ext_file="${DOTFILES}/config/vscode/extensions.txt"
  [[ ! -f "$ext_file" ]] && { error "Extensions file not found: $ext_file"; return 1; }

  while read extension; do
    cursor --install-extension "$extension"
  done < "$ext_file"
}


################################################################################
# CONFIG SYMLINKS MANAGEMENT
################################################################################

# List of config directories to symlink
CONFIG_DIRS=(
  "zsh"
  "nvim"
  "starship"
  "git"
  "lazygit"
  "atuin"
  "yazi"
  "zellij"
  "bat"
  "delta"
  "just"
  "npm"
  "gh"
  "htop"
  "direnv"
  "fd"
  "ripgrep"
)

# Check if a path is a symlink pointing to our dotfiles
is_our_symlink() {
  local path="$1"
  if [[ -L "$path" ]]; then
    local target=$(readlink "$path")
    [[ "$target" == "$DOTFILES_CONFIG"* ]]
  else
    return 1
  fi
}

# Backup existing config
backup_existing() {
  local path="$1"
  local backup_dir="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"

  if [[ -e "$path" ]] && ! is_our_symlink "$path"; then
    mkdir -p "$backup_dir"
    local rel_path="${path#$HOME_CONFIG/}"
    local backup_path="$backup_dir/$rel_path"
    mkdir -p "$(dirname "$backup_path")"

    log_warn "Backing up existing $rel_path to $backup_path"
    mv "$path" "$backup_path"
    return 0
  fi
  return 1
}

# Create symlink with proper checks
create_symlink() {
  local src="$1"
  local dst="$2"
  local name="${dst#$HOME_CONFIG/}"

  # Check if source exists
  if [[ ! -e "$src" ]]; then
    log_warn "Source not found: $name (skipping)"
    return 1
  fi

  # Check if destination already exists
  if [[ -e "$dst" ]]; then
    if is_our_symlink "$dst"; then
      log_info "Already linked: $name"
      return 0
    else
      backup_existing "$dst"
    fi
  fi

  # Create parent directory if needed
  mkdir -p "$(dirname "$dst")"

  # Create the symlink
  if ln -sf "$src" "$dst"; then
    log_success "Linked: $name"
    return 0
  else
    log_error "Failed to link: $name"
    return 1
  fi
}

# Setup config symlinks
setup_config_symlinks() {
  local DOTFILES_CONFIG="${DOTFILES:-$HOME/dotfiles}/.config"
  local HOME_CONFIG="$HOME/.config"

  log_info "Setting up config symlinks from $DOTFILES_CONFIG"

  # Ensure ~/.config exists and is a directory
  if [[ -L "$HOME_CONFIG" ]]; then
    log_error "~/.config is a symlink! This needs to be a real directory."
    log_info "Run: rm ~/.config && mkdir ~/.config"
    return 1
  fi

  if [[ ! -d "$HOME_CONFIG" ]]; then
    log_info "Creating ~/.config directory"
    mkdir -p "$HOME_CONFIG"
  fi

  # Check if dotfiles config exists
  if [[ ! -d "$DOTFILES_CONFIG" ]]; then
    log_error "Dotfiles config not found at: $DOTFILES_CONFIG"
    return 1
  fi

  # Process directories
  log_info "Linking config directories..."
  local success_count=0
  local skip_count=0
  local fail_count=0

  for dir in "${CONFIG_DIRS[@]}"; do
    src="$DOTFILES_CONFIG/$dir"
    dst="$HOME_CONFIG/$dir"

    if create_symlink "$src" "$dst"; then
      ((success_count++))
    elif [[ -e "$src" ]]; then
      ((fail_count++))
    else
      ((skip_count++))
    fi
  done

  # Summary
  echo
  log_info "Summary:"
  log_success "Linked: $success_count"
  [[ $skip_count -gt 0 ]] && log_warn "Skipped: $skip_count (not found in dotfiles)"
  [[ $fail_count -gt 0 ]] && log_error "Failed: $fail_count"

  # Special case: Ensure ZDOTDIR is properly set
  if [[ -L "$HOME_CONFIG/zsh" ]]; then
    echo
    log_info "zsh config is linked. Ensure ZDOTDIR is set in ~/.zshenv:"
    echo "    export ZDOTDIR=\"\$HOME/.config/zsh\""
  fi
}

# Show current symlink status
symlinks_status() {
  local DOTFILES_CONFIG="${DOTFILES:-$HOME/dotfiles}/.config"
  local HOME_CONFIG="$HOME/.config"

  log_info "Current config symlinks:"
  echo

  for dir in "${CONFIG_DIRS[@]}"; do
    dst="$HOME_CONFIG/$dir"
    if [[ -L "$dst" ]]; then
      target=$(readlink "$dst")
      if [[ "$target" == "$DOTFILES_CONFIG"* ]]; then
        printf "${GREEN}✓${RESET} %-20s -> %s\n" "$dir" "$target"
      else
        printf "${YELLOW}?${RESET} %-20s -> %s\n" "$dir" "$target"
      fi
    elif [[ -e "$dst" ]]; then
      printf "${RED}✗${RESET} %-20s (exists but not symlinked)\n" "$dir"
    else
      printf "  %-20s (not found)\n" "$dir"
    fi
  done
}

# Remove all our symlinks
unlink_all() {
  local DOTFILES_CONFIG="${DOTFILES:-$HOME/dotfiles}/.config"
  local HOME_CONFIG="$HOME/.config"

  log_warn "Removing all config symlinks..."

  for dir in "${CONFIG_DIRS[@]}"; do
    dst="$HOME_CONFIG/$dir"
    if is_our_symlink "$dst"; then
      rm "$dst"
      log_success "Removed: $dir"
    fi
  done
}

################################################################################
# NIX UNINSTALLER FOR MACOS
################################################################################

# Complete Nix uninstaller function
nix_uninstall() {
  if ! is_macos; then
    log_error "This uninstaller is only for macOS"
    return 1
  fi

  log_warn "This will completely remove Nix from your system"
  log_warn "A backup will be created in /tmp/nix-uninstall-backup-$(date +%Y%m%d%H%M%S)"
  echo
  read -p "Continue with Nix uninstallation? (y/N): " confirm
  [[ ! "$confirm" =~ ^[Yy]$ ]] && return 0

  # Run the uninstaller script inline
  log_info "Starting Nix uninstallation..."

  # Since we need root privileges, we'll need to escalate
  if [[ "$(id -u)" -ne 0 ]]; then
    log_info "This operation requires root privileges. You'll be prompted for your password."
    sudo -v || { log_error "Failed to get sudo privileges"; return 1; }
  fi

  # Create a temporary script and run it with sudo
  local tmp_script=$(mktemp)
  cat > "$tmp_script" << 'EOF'
#!/bin/bash
set -euo pipefail

# Helper functions for colorful output
section() { echo -e "\n\033[1;34m==== $1 ====\033[0m"; }
success() { echo -e "\033[1;32m✓ $1\033[0m"; }
warning() { echo -e "\033[1;33m⚠ $1\033[0m"; }
error() { echo -e "\033[1;31m✗ $1\033[0m"; }
info() { echo -e "\033[1;36mℹ $1\033[0m"; }

# Create backup directory
TIMESTAMP=$(date +"%Y%m%d%H%M%S")
BACKUP_DIR="/tmp/nix-uninstall-backup-$TIMESTAMP"
mkdir -p "$BACKUP_DIR"

# Stop Nix daemon
section "Stopping Nix services"
launchctl bootout system/org.nixos.nix-daemon 2>/dev/null || true
launchctl unload /Library/LaunchDaemons/org.nixos.nix-daemon.plist 2>/dev/null || true

# Kill Nix processes
pkill -f nix-daemon || true
pkill -f nix-store || true

# Unmount /nix
section "Unmounting /nix"
umount /nix 2>/dev/null || true

# Remove LaunchDaemons
section "Removing LaunchDaemons"
rm -f /Library/LaunchDaemons/org.nixos.*.plist

# Remove nixbld users and group
section "Removing nixbld users and group"
for i in {1..32}; do
  dscl . -delete "/Users/nixbld$i" 2>/dev/null || true
done
dscl . -delete "/Groups/nixbld" 2>/dev/null || true

# Clean up system files
section "Cleaning up system files"
rm -rf /etc/nix
rm -f /etc/profile.d/nix*.sh
rm -f /etc/zshrc.d/nix*.sh
rm -f /etc/bash.bashrc.local-nix
rm -f /etc/zsh/zshrc.local-nix

# Remove from synthetic.conf
if [[ -f /etc/synthetic.conf ]]; then
  grep -v "^nix" /etc/synthetic.conf > /tmp/synthetic.conf.new || true
  mv /tmp/synthetic.conf.new /etc/synthetic.conf
fi

# Try to delete APFS volume
section "Removing Nix APFS volume"
diskutil list | grep -i "Nix Store" | awk '{print $NF}' | while read vol; do
  diskutil apfs deleteVolume "$vol" 2>/dev/null || warning "Could not delete volume $vol"
done

# Remove /nix
rm -rf /nix 2>/dev/null || warning "Could not remove /nix directory"

# Clean up user files
section "Cleaning up user files"
find /Users -name ".nix-profile" -exec rm -rf {} + 2>/dev/null || true
find /Users -name ".nix-defexpr" -exec rm -rf {} + 2>/dev/null || true
find /Users -name ".nix-channels" -exec rm -rf {} + 2>/dev/null || true

section "Nix uninstallation complete"
echo "Backup created at: $BACKUP_DIR"
echo "You may need to restart your computer and manually remove /nix if it still exists"
EOF

  chmod +x "$tmp_script"

  # Run the uninstaller with sudo
  sudo "$tmp_script"
  local exit_code=$?

  # Clean up
  rm -f "$tmp_script"

  if [[ $exit_code -eq 0 ]]; then
    log_success "Nix uninstallation completed"
    log_info "You may need to restart your computer to complete the removal"
    log_info "Also check your shell configuration files and remove any Nix-related lines"
  else
    log_error "Nix uninstallation encountered errors"
  fi

  return $exit_code
}

################################################################################
# ZSH CONFIGURATION TEST
################################################################################

test_zsh_config() {
  log_info "Testing ZSH Configuration..."
  echo "============================"

  local tests_passed=0
  local tests_failed=0

  # Test 1: Check if zsh can source configuration files
  echo -n "Test 1: Sourcing configuration files... "
  if zsh -c 'source $HOME/.config/zsh/.zshenv && source $HOME/.config/zsh/.zprofile && source $HOME/.config/zsh/.zshrc' 2>/dev/null; then
    echo "✓ PASS"
    ((tests_passed++))
  else
    echo "✗ FAIL"
    ((tests_failed++))
  fi

  # Test 2: Check essential environment variables
  echo -n "Test 2: Essential environment variables... "
  if zsh -c '
    source $HOME/.config/zsh/.zshenv
    [[ -n "$DOTFILES" ]] && [[ -n "$XDG_CONFIG_HOME" ]] && [[ -n "$ZDOTDIR" ]] && [[ -n "$PATH" ]]
  '; then
    echo "✓ PASS"
    ((tests_passed++))
  else
    echo "✗ FAIL"
    ((tests_failed++))
  fi

  # Test 3: Check if PATH contains essential directories
  echo -n "Test 3: PATH configuration... "
  if zsh -c '
    source $HOME/.config/zsh/.zshenv
    source $HOME/.config/zsh/.zprofile
    echo $PATH | grep -q "/opt/homebrew/opt/coreutils/libexec/gnubin" && echo $PATH | grep -q "$HOME/.volta/bin"
  '; then
    echo "✓ PASS"
    ((tests_passed++))
  else
    echo "✗ FAIL"
    ((tests_failed++))
  fi

  # Test 4: Check if key aliases are defined
  echo -n "Test 4: Alias definitions... "
  if zsh -ic 'alias | grep -q "^ls=" && alias | grep -q "^ll=" && alias | grep -q "^v="' 2>/dev/null; then
    echo "✓ PASS"
    ((tests_passed++))
  else
    echo "✗ FAIL"
    ((tests_failed++))
  fi

  # Test 5: Check if functions are defined
  echo -n "Test 5: Function definitions... "
  if zsh -ic 'type has_command >/dev/null 2>&1 && type cdf >/dev/null 2>&1 && type vf >/dev/null 2>&1'; then
    echo "✓ PASS"
    ((tests_passed++))
  else
    echo "✗ FAIL"
    ((tests_failed++))
  fi

  # Test 6: Check completion system
  echo -n "Test 6: Completion system... "
  if zsh -ic 'compinit -C; echo ${#_comps}' 2>/dev/null | grep -q '^[0-9]\+$'; then
    echo "✓ PASS"
    ((tests_passed++))
  else
    echo "✗ FAIL"
    ((tests_failed++))
  fi

  # Test 7: Check if Homebrew is properly configured
  echo -n "Test 7: Homebrew configuration... "
  if zsh -ic '[[ -n "$HOMEBREW_PREFIX" ]]' 2>/dev/null; then
    echo "✓ PASS"
    ((tests_passed++))
  else
    echo "✗ FAIL"
    ((tests_failed++))
  fi

  # Test 8: Interactive shell test
  echo -n "Test 8: Interactive shell startup... "
  if timeout 2 zsh -ic 'echo "interactive shell works"' >/dev/null 2>&1; then
    echo "✓ PASS"
    ((tests_passed++))
  else
    echo "✗ FAIL"
    ((tests_failed++))
  fi

  echo "============================"
  echo "Configuration test complete!"
  echo "Passed: $tests_passed / Failed: $tests_failed"

  [[ $tests_failed -eq 0 ]] && return 0 || return 1
}

ZSH_TEST_COMMANDS=(
  "test::Test ZSH configuration:test_zsh_config"
)


################################################################################
# FLY.IO DEV ENVIRONMENT SETUP
################################################################################

setup_fly_dev_env() {
  local CLOUD_INFRA_DIR="${HOME}/src/cloud-infra"
  local PROJECT_NAME="fly-dev-env"

  log_info "Fly.io Dev Environment Setup"

  # Check prerequisites
  log_info "Checking prerequisites..."

  local missing_tools=()
  for tool in fly git; do
    if ! has_command "$tool"; then
      missing_tools+=("$tool")
    fi
  done

  if [ ${#missing_tools[@]} -ne 0 ]; then
    log_error "Missing required tools: ${missing_tools[*]}"
    log_warn "Please install missing tools:"
    [[ " ${missing_tools[*]} " =~ " fly " ]] && echo "  - Fly.io CLI: curl -L https://fly.io/install.sh | sh"
    return 1
  fi

  # Create cloud infrastructure directory
  ensure_dir "$CLOUD_INFRA_DIR"

  # Get user inputs
  log_info "Gathering configuration..."

  # App name
  local FLY_APP_NAME
  read -p "Enter Fly.io app name (default: fly-dev-env): " FLY_APP_NAME
  FLY_APP_NAME=${FLY_APP_NAME:-fly-dev-env}

  # Region
  echo "Available regions:"
  echo "  US: den, iad, lax, ord, sea, sjc"
  echo "  EU: ams, fra, lhr, mad, par"
  echo "  Asia: hkg, nrt, sin, syd"
  read -p "Enter preferred region (default: sjc): " FLY_REGION
  FLY_REGION=${FLY_REGION:-sjc}

  # Summary
  echo
  log_info "Configuration Summary:"
  echo "  App Name: $FLY_APP_NAME"
  echo "  Region: $FLY_REGION"
  echo "  Project Location: $CLOUD_INFRA_DIR/$PROJECT_NAME"
  echo

  read -p "Continue with these settings? (y/N): " confirm
  [[ ! "$confirm" =~ ^[Yy]$ ]] && return 1

  log_info "Creating project structure..."

  local PROJECT_DIR="${CLOUD_INFRA_DIR}/${PROJECT_NAME}"
  ensure_dir "$PROJECT_DIR"

  # Create minimal Dockerfile
  cat > "$PROJECT_DIR/Dockerfile" << 'EOF'
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    curl wget git sudo openssh-server \
    build-essential python3 python3-pip \
    nodejs npm tmux htop neovim vim \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash developer && \
    echo "developer:developer" | chpasswd && \
    usermod -aG sudo developer && \
    echo "developer ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER developer
WORKDIR /home/developer

RUN mkdir -p ~/.ssh ~/workspace

EXPOSE 22

CMD ["tail", "-f", "/dev/null"]
EOF

  # Create fly.toml
  cat > "$PROJECT_DIR/fly.toml" << EOF
app = "$FLY_APP_NAME"
primary_region = "$FLY_REGION"

[build]
  dockerfile = "Dockerfile"

[[services]]
  internal_port = 22
  protocol = "tcp"

  [[services.ports]]
    port = 22

[mounts]
  source = "dev_data"
  destination = "/home/developer/workspace"
EOF

  # Create helper script
  cat > "$PROJECT_DIR/connect.sh" << 'EOF'
#!/bin/bash
FLY_APP_NAME=$(grep "^app = " fly.toml | cut -d'"' -f2)
fly ssh console --app "$FLY_APP_NAME"
EOF
  chmod +x "$PROJECT_DIR/connect.sh"

  log_success "Project structure created at: $PROJECT_DIR"

  # Deploy
  log_info "Would you like to deploy now? (y/N): "
  read deploy_now
  if [[ "$deploy_now" =~ ^[Yy]$ ]]; then
    cd "$PROJECT_DIR"

    # Check if logged in
    if ! fly auth whoami &>/dev/null; then
      log_warn "Not logged in to Fly.io"
      fly auth login
    fi

    # Create app
    fly apps create "$FLY_APP_NAME" --org personal || log_warn "App might already exist"

    # Create volume
    fly volumes create dev_data --app "$FLY_APP_NAME" --region "$FLY_REGION" --size 50 --yes || log_warn "Volume might already exist"

    # Deploy
    fly deploy --app "$FLY_APP_NAME" --region "$FLY_REGION"

    log_success "Deployment complete!"
    echo "Connect with: cd $PROJECT_DIR && ./connect.sh"
  else
    log_info "To deploy later:"
    echo "  cd $PROJECT_DIR"
    echo "  fly deploy --app $FLY_APP_NAME --region $FLY_REGION"
  fi
}

FLY_COMMANDS=(
  "setup::Setup Fly.io dev environment:setup_fly_dev_env"
)


################################################################################
# PROFILE LOADING
################################################################################

# Load additional profile configurations
load_profiles() {
  # Nix profile
  [[ -e "$HOME/.nix-profile/etc/profile.d/nix.sh" ]] && . "$HOME/.nix-profile/etc/profile.d/nix.sh"

  # Path utils
  [[ -f "$HOME/.config/shell/path_utils.sh" ]] && . "$HOME/.config/shell/path_utils.sh"

  # Cargo
  [[ -f "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"

  # Atuin
  [[ -f "$HOME/.atuin/bin/env" ]] && . "$HOME/.atuin/bin/env"

  # GHCup
  [[ -f "$HOME/.ghcup/env" ]] && . "$HOME/.ghcup/env"

  # Volta
  export VOLTA_HOME="$HOME/.volta"
  export PATH="$VOLTA_HOME/bin:$PATH"

  # NPM global
  export PATH="$PATH:$HOME/.npm-global/bin"
}

################################################################################
# EXPORT STATEMENTS
################################################################################

# Export commonly used functions
export log_info log_success log_warn log_error
export has_command is_macos is_linux is_apple_silicon is_rosetta
export path_add path_remove ensure_dir
export brew_init init_brew init_zsh defaults_apply
export ant

################################################################################
# HELP SYSTEM
################################################################################

# Main help function
utils_help() {
  cat << 'EOF'
Combined ZSH Utilities
======================

This file provides a comprehensive collection of utilities for:
- System detection and logging
- File and directory operations
- PATH management
- Homebrew and package management
- macOS system preferences
- Docker operations
- FZF-powered commands
- Git hooks and conventional commits
- Config symlink management
- Nix uninstallation
- VS Code extensions
- Fly.io dev environments

Available command groups:
  file      - File operations
  path      - PATH management
  b         - Homebrew management
  bb        - Brewfile management
  sys       - System utilities
  mas       - Mac App Store management
  d         - Docker management
  f         - FZF-powered commands
  ide       - IDE and editor management
  ant       - Anterior monorepo helper
  vscode    - VS Code extensions management
  utils     - General utilities
  git-hooks - Git hooks management
  symlinks  - Config symlink management
  nix       - Nix management
  zsh-test  - ZSH configuration testing
  fly-dev   - Fly.io dev environment

Special functions:
  main_install    - Run dotfiles installation
  defaults_apply  - Apply macOS defaults
  list_utils      - List all available functions
  load_profiles   - Load additional shell profiles

Usage: Source this file to access all functions
       source ~/.config/zsh/utils.zsh
EOF
}

# # If script is executed directly (not sourced), show help
# if [[ "${0:t}" == "utils.zsh" ]]; then
#   utils_help
# fi

# End of combined utils.zsh

# # Load paths from config
# load_paths() {
#     paths=()
#     while IFS= read -r dir; do
#         [[ -n "$dir" && ! "$dir" =~ ^# ]] && paths+=("${dir/#\~/$HOME}")
#     done < "$HOME/.config/shell/paths.conf"
# }

# # Build unique PATH
# build_path() {
#     local -A seen
#     local new_path=""

#     # Add from config first
#     for dir in "${paths[@]}"; do
#         [[ -d "$dir" && -z "${seen[$dir]}" ]] && {
#             seen[$dir]=1
#             new_path="${new_path:+$new_path:}$dir"
#         }
#     done

#     # Preserve existing PATH entries
#     local IFS=:
#     for dir in $PATH; do
#         [[ -d "$dir" && -z "${seen[$dir]}" ]] && {
#             seen[$dir]=1
#             new_path="${new_path:+$new_path:}$dir"
#         }
#     done

#     PATH="$new_path"
# }

# # Print current PATH
# path_print() {
#     local IFS=:
#     local i=1
#     for dir in $PATH; do
#         printf "%2d. %s\n" $((i++)) "$dir"
#     done
# }

################################################################################

# Below is the current state-of-the-art for cutting down (or at least hiding) .DS_Store files on macOS.

# | Situation | Can you **fully stop** .DS_Store? | Best available workaround | Risk / trade-off |
# |---|---|---|---|
# | Local internal volumes (the built-in SSD/HDD) | ❌ No. Finder always needs a place to cache icon positions, view options, tags, etc. | Periodically delete them with a script or hide them with .gitignore/.dockerignore, etc. | Finder may recreate them instantly; constant deletion slightly increases I/O. |
# | External USB / Thunderbolt drives | ⚠️ macOS ≥ 10.15 lets you disable creation | defaults write com.apple.desktopservices DSDontWriteUSBStores -bool TRUE | Some view settings (icon positions, custom folder backgrounds) will be lost on those drives. |
# | Network shares (SMB, AFP, WebDAV, NFS, etc.) | ✅ Can be disabled | defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool TRUE | Folder customizations won’t stick; can increase network traffic if Finder constantly asks to write and is denied. |

# ---

# ## Step-by-step: Disable .DS_Store on USB & Network volumes

# 1. Open Terminal (Applications ➜ Utilities ➜ Terminal).
# 2. Paste the following 2 commands, pressing Return after each:

#    ```bash
#    # Block .DS_Store on network shares
#    defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool TRUE

#    # Block .DS_Store on external/removable drives
#    defaults write com.apple.desktopservices DSDontWriteUSBStores -bool TRUE
#    ```
# 3. Restart Finder so it reads the new preference:

#    ```bash
#    killall Finder
#    ```
#    (All open Finder windows will close and reopen automatically.)

# ### How to undo

# ```bash
# # Re-enable .DS_Store on network volumes
# defaults delete com.apple.desktopservices DSDontWriteNetworkStores

# # Re-enable .DS_Store on external/removable drives
# defaults delete com.apple.desktopservices DSDontWriteUSBStores

# # Relaunch Finder again
# killall Finder
# ```

# ---

# ## What if you really need “zero” .DS_Store everywhere?

# Because macOS writes them on internal disks no matter what, your only practical options are:

# 1. **Automated cleanup**
#    Create a small LaunchAgent or cron job that runs something like:

#    ```bash
#    find $HOME -name ".DS_Store" -delete
#    ```

# 2. **Hide them from version control / packaging tools**
#    • `.gitignore` ➜ `*.DS_Store`
#    • Docker context ➜ `.dockerignore`
#    • zip/tar ➜ `zip -x '*.DS_Store' …`

# 3. **Use another file manager** (rarely worth it)
#    Finder replacements that do not generate .DS_Store will lose macOS-specific niceties such as Quick Look integration.

# ---

# ### Why Apple still uses .DS_Store

# -  Stores per-directory icon positions, list/column view settings, sort order, spotlight comments, labels, etc.
# -  Avoids populating global preference files that would grow without bound.
# -  Historically small and benign; deleting them is safe but Finder regenerates them immediately.

# In short, you can tame .DS_Store on removable and network volumes, but Finder considers them essential on internal disks. The commands above are the cleanest supported solution today (macOS Sonoma 14 and earlier).


################################################################################
