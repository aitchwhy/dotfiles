#!/usr/bin/env zsh

################################################################################
# ZSH Functions Collection - Unified CLI Framework
################################################################################

# Color definitions
readonly BLUE='\033[0;34m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly RESET='\033[0m'

################################################################################
# CORE LOGGING
################################################################################

log_info() { printf "${BLUE}[INFO]${RESET} %s\n" "$*"; }
log_success() { printf "${GREEN}[SUCCESS]${RESET} %s\n" "$*"; }
log_warn() { printf "${YELLOW}[WARNING]${RESET} %s\n" "$*" >&2; }
log_error() { printf "${RED}[ERROR]${RESET} %s\n" "$*" >&2; }

# Aliases
info() { log_info "$@"; }
success() { log_success "$@"; }
warn() { log_warn "$@"; }
error() { log_error "$@"; }

################################################################################
# SYSTEM DETECTION
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
# GENERIC CLI FRAMEWORK
################################################################################

# Framework for creating consistent CLI commands with subcommands
# Usage: _cli_framework <namespace> <command> "$@"
_cli_framework() {
  local namespace="$1"
  local cmd_name="$2"
  echo "namespace : ${namespace} and ${cmd_name}"
  shift 2

  # Get command registry
  local commands="${namespace}_COMMANDS"
  local help_text="${namespace}_HELP"

  # No args - show interactive menu or help
  if [[ $# -eq 0 ]]; then
    if has_command fzf; then
      _cli_framework_menu "$namespace" "$cmd_name" "${commands[@]}"
    else
      echo "$help_text"
    fi
    return $?
  fi

  # Process command
  local subcmd="$1"
  shift

  # Check for help
  if [[ "$subcmd" =~ ^(help|--help|-h)$ ]]; then
    echo "$help_text"
    return 0
  fi

  # Find and execute command
  for cmd_info in "${commands[@]}"; do
    local -a parts
    IFS=':' read -rA parts <<< "$cmd_info"
    local cmd="${parts[1]}"
    local aliases="${parts[2]:-}"
    local desc="${parts[3]}"
    local func="${parts[4]}"

    # Check main command and aliases
    if [[ "$subcmd" == "$cmd" ]] || [[ ",$aliases," == *",$subcmd,"* ]]; then
      $func "$@"
      return $?
    fi
  done

  # Command not found
  log_error "Unknown command: $subcmd"
  echo "$help_text"
  return 1
}

# Interactive menu for CLI framework
_cli_framework_menu() {
  local namespace="$1"
  local cmd_name="$2"
  shift 2
  local commands=("$@")

  local menu_items=()
  for cmd_info in "${commands[@]}"; do
    local -a parts
    IFS=':' read -rA parts <<< "$cmd_info"
    local cmd="${parts[1]}"
    local desc="${parts[3]}"
    menu_items+=("$cmd:$desc")
  done

  local selected=$(printf "%s\n" "${menu_items[@]}" |
    awk -F: '{printf "%-20s %s\n", $1, $2}' |
    fzf --header="Select $cmd_name command" \
        --preview="echo Description: {2..}" \
        --preview-window=bottom:3:wrap)

  [[ -z "$selected" ]] && return 0

  local subcmd=$(echo "$selected" | awk '{print $1}')
  $cmd_name "$subcmd"
}

# Generate help text from command registry
_cli_generate_help() {
  local name="$1"
  local desc="$2"
  shift 2
  local commands=("$@")

  local help="$desc\n\nUsage: $name <command> [arguments]\n\nCommands:\n"

  for cmd_info in "${commands[@]}"; do
    local -a parts
    IFS=':' read -rA parts <<< "$cmd_info"
    local cmd="${parts[1]}"
    local aliases="${parts[2]:-}"
    local desc="${parts[3]}"

    if [[ -n "$aliases" ]]; then
      help+=$(printf "  %-15s %-10s %s\n" "$cmd" "($aliases)" "$desc")
    else
      help+=$(printf "  %-15s %11s%s\n" "$cmd" "" "$desc")
    fi
  done

  help+="\nRunning without arguments shows interactive menu (requires fzf)"
  echo -e "$help"
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
# IDE/EDITOR COMMANDS
################################################################################

cursor_ext_import() {
  local ext_file="${DOTFILES}/config/vscode/extensions.txt"
  [[ ! -f "$ext_file" ]] && { error "Extensions file not found: $ext_file"; return 1; }

  while read extension; do
    cursor --install-extension "$extension"
  done < "$ext_file"
}

_ide_volta_list() {
  has_command volta || { error "Volta not installed"; return 1; }
  volta list --format=plain
}

# IDE command registry
IDE_COMMANDS=(
  "cursor-ext::Import Cursor/VSCode extensions:cursor_ext_import"
  "volta-list:volta,v:List Volta managed tools:_ide_volta_list"
)

IDE_HELP=$(_cli_generate_help "ide" "IDE and editor management" "${IDE_COMMANDS[@]}")

ide() { _cli_framework IDE ide "$@"; }

################################################################################
# FILE OPERATIONS
################################################################################

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

FILE_COMMANDS=(
  "cp-repo:cp:Copy git repository preserving structure:cp_repo"
  "slink:ln:Create symbolic link:slink"
  "slink-init::Initialize all dotfiles symlinks:slink_init"
)

FILE_HELP=$(_cli_generate_help "file" "File operations" "${FILE_COMMANDS[@]}")

file() { _cli_framework FILE file "$@"; }

################################################################################
# SYSTEM UTILITIES
################################################################################

_sys_env() {
  local pattern="$1"
  echo "======== env vars =========="
  if [[ -z "$pattern" ]]; then
    printenv | sort | awk -F= '{ printf "%-30s %s\n", $1, $2 }'
  else
    printenv | sort | grep -i "$pattern" | awk -F= '{ printf "%-30s %s\n", $1, $2 }'
  fi
  echo "============================"
}

_sys_hidden() {
  local current=$(defaults read com.apple.finder AppleShowAllFiles)
  defaults write com.apple.finder AppleShowAllFiles $((!current))
  killall Finder
  echo "Finder hidden files: $((!current))"
}

_sys_ql() {
  [[ -z "$1" ]] && { echo "Usage: sys ql <file>"; return 1; }
  qlmanage -p "$@" &>/dev/null
}

_sys_killport() {
  local port="$1"
  [[ -z "$port" ]] && { echo "Usage: sys killport <port>"; return 1; }

  local pid=$(lsof -i ":$port" | awk 'NR!=1 {print $2}')
  [[ -z "$pid" ]] && { echo "No process found on port $port"; return 1; }

  echo "Killing process(es) on port $port: $pid"
  echo "$pid" | xargs kill -9
  success "Process(es) killed"
}

_sys_man() {
  [[ -z "$1" ]] && { echo "Usage: sys man <command>"; return 1; }
  MANPAGER="sh -c 'col -bx | bat -l man -p'" man "$@"
}

_sys_ports() { sudo lsof -iTCP -sTCP:LISTEN -n -P; }
_sys_disk() { df -h; }
_sys_cpu() { top -l 1 | grep -E "^CPU"; }
_sys_mem() { vm_stat | perl -ne '/page size of (\d+)/ and $size=$1; /Pages\s+([^:]+)[^\d]+(\d+)/ and printf("%-16s % 16.2f MB\n", "$1:", $2 * $size / 1048576);'; }
_sys_path() { echo "PATH components:"; echo $PATH | tr ':' '\n' | nl | awk '{printf "  %2d: %s\n", $1, $2}'; }
_sys_ip() { echo "Public IP: $(curl -s https://ipinfo.io/ip)"; echo "Local IP: $(ipconfig getifaddr en0)"; }

SYS_COMMANDS=(
  "env:env-grep:Display environment variables:_sys_env"
  "hidden:toggle-hidden:Toggle hidden files in Finder:_sys_hidden"
  "ql:quick-look:Quick Look a file:_sys_ql"
  "killport:kill-port,kp:Kill process on port:_sys_killport"
  "man:batman:Man pages with syntax highlighting:_sys_man"
  "ports:listening:Show all listening ports:_sys_ports"
  "disk:space,df:Check disk space usage:_sys_disk"
  "cpu::Show CPU usage:_sys_cpu"
  "mem:memory:Show memory usage:_sys_mem"
  "path::List PATH entries:_sys_path"
  "ip:myip:Show IP addresses:_sys_ip"
)

SYS_HELP=$(_cli_generate_help "sys" "System utilities" "${SYS_COMMANDS[@]}")

sys() { _cli_framework SYS sys "$@"; }

################################################################################
# MACOS DEFAULTS
################################################################################
#
# _defaults_all() {
#   info "Applying all macOS preferences..."
#   _defaults_keyboard
#   _defaults_finder
#   _defaults_dock
#   _defaults_trackpad
#   success "All macOS preferences applied"
# }
#
# _defaults_keyboard() {
#   defaults write NSGlobalDomain KeyRepeat -int 2
#   defaults write NSGlobalDomain InitialKeyRepeat -int 15
#   defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
#   success "Keyboard preferences applied"
# }
#
# _defaults_finder() {
#   defaults write NSGlobalDomain AppleShowAllExtensions -bool true
#   defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
#   defaults write com.apple.finder AppleShowAllFiles -bool true
#   defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
#   defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
#   defaults write com.apple.finder ShowPathbar -bool true
#   defaults write com.apple.finder ShowStatusBar -bool true
#   defaults write com.apple.finder _FXSortFoldersFirst -bool true
#   killall Finder &>/dev/null || true
#   success "Finder preferences applied"
# }
#
# _defaults_dock() {
#   defaults write com.apple.dock autohide -bool true
#   defaults write com.apple.dock autohide-delay -float 0
#   defaults write com.apple.dock show-recents -bool false
#   killall Dock &>/dev/null || true
#   success "Dock preferences applied"
# }
#
# _defaults_trackpad() {
#   defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
#   success "Trackpad preferences applied"
# }
#
# DEFAULTS_COMMANDS=(
#   "apply:all:Apply all macOS preferences:_defaults_all"
#   "keyboard:kb:Apply keyboard settings:_defaults_keyboard"
#   "finder::Apply Finder settings:_defaults_finder"
#   "dock::Apply Dock settings:_defaults_dock"
#   "trackpad::Apply trackpad settings:_defaults_trackpad"
# )
#
# DEFAULTS_HELP=$(_cli_generate_help "defaults" "macOS defaults management" "${DEFAULTS_COMMANDS[@]}")
#
# defaults() {
#   # Pass through to system defaults for read/write
#   if [[ "$1" == "write" ]] || [[ "$1" == "read" ]]; then
#     command defaults "$@"
#     return $?
#   fi
#   _cli_framework DEFAULTS defaults "$@"
# }
#
# # Compatibility aliases
# setup_macos_preferences() { _defaults_all; }
# defaults_apply() { _defaults_all; }

################################################################################
# MAC APP STORE
################################################################################

_mas_select() {
  mas list | fzf --header="$1" | awk '{print $1}'
}

_mas_install() {
  local id="${1:-$(_mas_select "Select app to install")}"
  [[ -z "$id" ]] && return 1
  info "Installing Mac App Store app: $id"
  mas install "$id"
}

_mas_uninstall() {
  local id="${1:-$(_mas_select "Select app to uninstall")}"
  [[ -z "$id" ]] && return 1
  local app_name=$(mas list | grep "^$id" | awk '{$1=""; print $0}' | xargs)
  info "Uninstalling: $app_name"
  osascript -e "tell application \"Finder\" to move application \"$app_name\" to trash"
}

_mas_info() {
  local id="${1:-$(_mas_select "Select app for info")}"
  [[ -z "$id" ]] && return 1
  mas info "$id"
}

_mas_outdated() {
  info "Outdated Mac App Store apps:"
  mas outdated
}

_mas_upgrade() {
  info "Upgrading all Mac App Store apps..."
  mas upgrade
}

MAS_COMMANDS=(
  "install:in,i:Install app from Mac App Store:_mas_install"
  "uninstall:rm:Uninstall app:_mas_uninstall"
  "info::Show app information:_mas_info"
  "outdated::Show outdated apps:_mas_outdated"
  "upgrade:up:Upgrade all apps:_mas_upgrade"
)

MAS_HELP=$(_cli_generate_help "mas" "Mac App Store management" "${MAS_COMMANDS[@]}")

mas() {
  if ! has_command mas; then
    command mas "$@"
    return $?
  fi
  _cli_framework MAS mas "$@"
}

################################################################################
# HOMEBREW
################################################################################

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

_brew_check() {
  has_command brew || { error "Homebrew not installed"; return 1; }
}

# Brewfile path resolution
_brewfile_path() {
  [[ "$1" == "--global" ]] && echo "--global" || echo "${1:-$_BREWFILE}"
}

# Basic brew operations
_b_update() {
  _brew_check || return 1
  info "Updating Homebrew..."
  brew update && brew upgrade && brew cleanup
  success "Homebrew updated"
}

_b_install() {
  _brew_check || return 1
  [[ -z "$1" ]] && { error "Usage: b install <package>"; return 1; }
  brew install "$@"
}

_b_cask() {
  _brew_check || return 1
  [[ -z "$1" ]] && { error "Usage: b cask <cask>"; return 1; }
  brew install --cask "$@"
}

_b_remove() {
  _brew_check || return 1
  [[ -z "$1" ]] && { error "Usage: b remove <package>"; return 1; }
  brew uninstall "$@"
}

_b_info() {
  _brew_check || return 1
  [[ -z "$1" ]] && { error "Usage: b info <package>"; return 1; }
  brew info "$@"
}

_b_list() {
  _brew_check || return 1
  case "$1" in
    casks) brew list --cask ;;
    leaves) brew leaves ;;
    *) brew list ;;
  esac
}

_b_cleanup() {
  _brew_check || return 1
  brew cleanup --prune=all && brew autoremove
}

# Interactive brew operations
_bf_install() {
  _brew_check && _fzf_check || return 1

  local selected=$(brew search | _fzf_select "Select packages to install (TAB: multiple)" "brew info {}" multi)
  [[ -z "$selected" ]] && return 0

  info "Installing: $selected"
  echo "$selected" | xargs -r brew install
}

_bf_cask() {
  _brew_check && _fzf_check || return 1

  local selected=$(brew search --casks | _fzf_select "Select casks to install (TAB: multiple)" "brew info --cask {}" multi)
  [[ -z "$selected" ]] && return 0

  info "Installing casks: $selected"
  echo "$selected" | xargs -r brew install --cask
}

_bf_remove() {
  _brew_check && _fzf_check || return 1

  local selected=$(brew list | _fzf_select "Select packages to remove (TAB: multiple)" "brew info {}" multi)
  [[ -z "$selected" ]] && return 0

  info "Removing: $selected"
  echo "$selected" | xargs -r brew uninstall
}

# Brewfile operations
_bb_install() {
  _brew_check || return 1
  local brewfile=$(_brewfile_path "$1")
  local cmd="brew bundle install --verbose"

  if [[ "$brewfile" == "--global" ]]; then
    cmd="$cmd --global"
  else
    [[ ! -f "$brewfile" ]] && { error "Brewfile not found: $brewfile"; return 1; }
    cmd="$cmd --file=$brewfile"
  fi

  eval "$cmd --cleanup"
}

_bb_check() {
  _brew_check || return 1
  local brewfile=$(_brewfile_path "$1")
  local cmd="brew bundle check --verbose"

  [[ "$brewfile" == "--global" ]] && cmd="$cmd --global" || cmd="$cmd --file=$brewfile"
  eval "$cmd"
}

_bb_dump() {
  _brew_check || return 1
  local brewfile=$(_brewfile_path "$1")
  local cmd="brew bundle dump --verbose --force"

  [[ "$brewfile" == "--global" ]] && cmd="$cmd --global" || cmd="$cmd --file=$brewfile"
  eval "$cmd"
}

_bb_cleanup() {
  _brew_check || return 1
  local brewfile=$(_brewfile_path "$1")
  local cmd="brew bundle cleanup --verbose"

  [[ "$brewfile" == "--global" ]] && cmd="$cmd --global" || cmd="$cmd --file=$brewfile"

  local to_remove=$(eval "$cmd")
  [[ -z "$to_remove" ]] && { info "No packages to remove"; return 0; }

  echo "$to_remove"
  echo "\nProceed with removal? (y/n)"
  read -k 1 confirm
  echo ""

  [[ "$confirm" == "y" ]] && eval "$cmd --force"
}

_bb_edit() {
  _brew_check || return 1
  local brewfile=$(_brewfile_path "$1")

  if [[ "$brewfile" == "--global" ]]; then
    brew bundle edit --global
  else
    [[ ! -f "$brewfile" ]] && touch "$brewfile"
    ${EDITOR:-vi} "$brewfile"
  fi
}

B_COMMANDS=(
  "update:up:Update and upgrade all packages:_b_update"
  "install:in,i:Install package:_b_install"
  "cask::Install cask:_b_cask"
  "remove:rm,un:Remove package:_b_remove"
  "info::Show package info:_b_info"
  "list:ls:List installed packages:_b_list"
  "cleanup:clean:Clean up old versions:_b_cleanup"
  "fin::Interactive package install:_bf_install"
  "fcask::Interactive cask install:_bf_cask"
  "frm::Interactive package removal:_bf_remove"
)

BB_COMMANDS=(
  "install:in,i:Install from Brewfile:_bb_install"
  "check:c:Check Brewfile status:_bb_check"
  "dump:d:Create Brewfile from installed:_bb_dump"
  "cleanup:clean:Remove packages not in Brewfile:_bb_cleanup"
  "edit:e:Edit Brewfile:_bb_edit"
)

B_HELP=$(_cli_generate_help "b" "Homebrew management" "${B_COMMANDS[@]}")
BB_HELP=$(_cli_generate_help "bb" "Brewfile management" "${BB_COMMANDS[@]}")

unalias b
function b() {
  if [[ $# -gt 0 ]] && ! [[ "$1" =~ ^(update|install|cask|remove|info|list|cleanup|fin|fcask|frm|help|up|in|i|rm|un|ls|clean|--help|-h)$ ]]; then
    command brew "$@"
  else
    _cli_framework B b "$@"
  fi
}

bb() { _cli_framework BB bb "$@"; }

# Compatibility function
uninstall_brew() {
  has_command brew || { warn "Homebrew is not installed"; return 1; }
  info "Uninstalling Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
}

################################################################################
# DOCKER
################################################################################

_docker_select() {
  local type="$1" header="$2"
  case "$type" in
    container) docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}" | tail -n +2 ;;
    all-container) docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}" | tail -n +2 ;;
    image) docker images --format "table {{.Repository}}:{{.Tag}}\t{{.ID}}\t{{.Size}}" | tail -n +2 ;;
    volume) docker volume ls --format "table {{.Name}}\t{{.Driver}}" | tail -n +2 ;;
    network) docker network ls --format "table {{.Name}}\t{{.Driver}}" | tail -n +2 ;;
  esac | fzf --header="$header" | awk '{print $1}'
}

_d_sh() {
  local container=$(_docker_select container "Select container for sh")
  [[ -n "$container" ]] && docker exec -it "$container" sh
}

_d_bash() {
  local container=$(_docker_select container "Select container for bash")
  [[ -n "$container" ]] && docker exec -it "$container" bash
}

_d_exec() {
  local container=$(_docker_select container "Select container for exec")
  [[ -z "$container" ]] && return 1

  read "cmd?Enter command: "
  docker exec -it "$container" $cmd
}

_d_logs() {
  local container=$(_docker_select container "Select container for logs")
  [[ -n "$container" ]] && docker logs -f "$container"
}

_d_stats() {
  local container=$(_docker_select container "Select container for stats")
  [[ -n "$container" ]] && docker stats "$container"
}

_d_inspect() {
  local container=$(_docker_select container "Select container to inspect")
  [[ -n "$container" ]] && docker inspect "$container" | bat -l json
}

_d_rm() {
  local container=$(_docker_select all-container "Select container to remove")
  [[ -n "$container" ]] && docker rm "$container"
}

_d_rmi() {
  local image=$(_docker_select image "Select image to remove")
  [[ -n "$image" ]] && docker rmi "$image"
}

_d_stop() {
  local container=$(_docker_select container "Select container to stop")
  [[ -n "$container" ]] && docker stop "$container"
}

_d_start() {
  local container=$(_docker_select all-container "Select container to start")
  [[ -n "$container" ]] && docker start "$container"
}

_d_restart() {
  local container=$(_docker_select container "Select container to restart")
  [[ -n "$container" ]] && docker restart "$container"
}

_d_ports() {
  local container=$(_docker_select container "Select container for port info")
  [[ -n "$container" ]] && docker port "$container"
}

_d_env() {
  local container=$(_docker_select container "Select container for env vars")
  [[ -n "$container" ]] && docker exec "$container" env | sort
}

_d_ps() {
  local container=$(_docker_select container "Select container for process list")
  [[ -n "$container" ]] && docker top "$container"
}

_d_diff() {
  local container=$(_docker_select container "Select container for diff")
  [[ -n "$container" ]] && docker diff "$container"
}

_d_cp() {
  local container=$(_docker_select container "Select container for copy")
  [[ -z "$container" ]] && return 1

  read "src?Source path (container:path or local): "
  read "dst?Destination path: "

  if [[ "$src" == *:* ]]; then
    docker cp "$container:${src#*:}" "$dst"
  else
    docker cp "$src" "$container:$dst"
  fi
}

_d_commit() {
  local container=$(_docker_select container "Select container to commit")
  [[ -z "$container" ]] && return 1

  read "repo?Repository name: "
  read "tag?Tag (default: latest): "
  docker commit "$container" "$repo:${tag:-latest}"
}

_d_vol() {
  local volume=$(_docker_select volume "Select volume to inspect")
  [[ -n "$volume" ]] && docker volume inspect "$volume" | bat -l json
}

_d_net() {
  local network=$(_docker_select network "Select network to inspect")
  [[ -n "$network" ]] && docker network inspect "$network" | bat -l json
}

_d_compose() {
  local file=$(find . -name "docker-compose*.yml" | fzf --header="Select compose file")
  [[ -n "$file" ]] && docker compose -f "$file" "$@"
}

_d_clean() {
  info "Cleaning up Docker resources..."
  docker system prune -f
  success "Docker cleanup complete"
}

D_COMMANDS=(
  "sh::Open sh shell in container:_d_sh"
  "bash::Open bash shell in container:_d_bash"
  "exec:e:Execute command in container:_d_exec"
  "logs:l:Follow container logs:_d_logs"
  "stats:s:Show container stats:_d_stats"
  "inspect:i:Inspect container:_d_inspect"
  "rm:remove:Remove container:_d_rm"
  "rmi::Remove image:_d_rmi"
  "stop::Stop container:_d_stop"
  "start::Start container:_d_start"
  "restart:rs:Restart container:_d_restart"
  "ports:p:Show port mappings:_d_ports"
  "env::Show environment variables:_d_env"
  "ps:top:Show processes:_d_ps"
  "diff:d:Show filesystem changes:_d_diff"
  "cp:copy:Copy files to/from container:_d_cp"
  "commit:c:Commit container to image:_d_commit"
  "vol:v:Inspect volume:_d_vol"
  "net:n:Inspect network:_d_net"
  "compose:comp:Docker compose operations:_d_compose"
  "clean::Clean up resources:_d_clean"
)

D_HELP=$(_cli_generate_help "d" "Docker management" "${D_COMMANDS[@]}")

unalias d
function d() {
  if ! has_command docker; then
    command docker "$@"
    return $?
  fi

  if [[ $# -gt 0 ]] && ! [[ "$1" =~ ^(sh|bash|exec|logs|stats|inspect|rm|rmi|stop|start|restart|ports|env|ps|diff|cp|commit|vol|net|compose|clean|help|e|l|s|i|remove|rs|p|top|d|copy|c|v|n|comp|--help|-h)$ ]]; then
    command docker "$@"
  else
    _cli_framework D d "$@"
  fi
}

# Compatibility aliases
alias dsh='d sh'
alias dbash='d bash'
alias dlogs='d logs'
alias dstats='d stats'
alias dinspect='d inspect'
alias drm='d rm'
alias drmi='d rmi'
alias dstop='d stop'
alias dstart='d start'
alias drestart='d restart'
alias dports='d ports'
alias denv='d env'
alias dps='d ps'
alias ddiff='d diff'
alias dcp='d cp'
alias dexec='d exec'
alias dcommit='d commit'
alias dvol='d vol'
alias dnet='d net'
alias dcomp='d compose'
alias dclean='d clean'
alias dtop='d ps'
alias drma='d rm'

################################################################################
# PATH MANAGEMENT
################################################################################

_path_add() {
  [[ -z "$1" ]] && { echo "Usage: path add <dir>"; return 1; }
  local dir="$1"

  if [[ -d "$dir" ]] && [[ ":$PATH:" != *":$dir:"* ]]; then
    export PATH="$dir:$PATH"
    success "Added to PATH: $dir"
  else
    warn "Directory not added (doesn't exist or already in PATH)"
  fi
}

_path_remove() {
  [[ -z "$1" ]] && { echo "Usage: path remove <dir>"; return 1; }
  local dir="$1"

  if [[ ":$PATH:" == *":$dir:"* ]]; then
    export PATH=${PATH//:$dir:/:}
    export PATH=${PATH/#$dir:/}
    export PATH=${PATH/%:$dir/}
    success "Removed from PATH: $dir"
  else
    warn "Directory not in PATH"
  fi
}

_path_list() {
  echo $PATH | tr ':' '\n' | nl | awk '{printf "  %2d: %s\n", $1, $2}'
}

PATH_COMMANDS=(
  "add:a:Add directory to PATH:_path_add"
  "remove:rm:Remove directory from PATH:_path_remove"
  "list:ls,l:List PATH entries:_path_list"
)

PATH_HELP=$(_cli_generate_help "path" "PATH management" "${PATH_COMMANDS[@]}")

path() { _cli_framework PATH path "$@"; }

# Compatibility
path_add() { _path_add "$@"; }
path_remove() { _path_remove "$@"; }
path_list() { _path_list; }
path_print() { _path_list; }

################################################################################
# FZF COMMANDS FRAMEWORK
################################################################################

# Core search function
_f_search() {
  local preview_cmd="$1" header="$2" action_cmd="$3" query="${4:-}" opts="${5:-}"

  if [[ -z "$action_cmd" ]]; then
    fzf --preview "$preview_cmd" --header "$header" --query "$query" $opts
  else
    fzf --preview "$preview_cmd" --header "$header" --query "$query" $opts | eval "$action_cmd"
  fi
}

# Command implementations
_f_find() {
  local target="${1:-.}"
  fd --type f --hidden --follow --exclude .git . "$target" 2>/dev/null |
    _f_search "bat --style=numbers --color=always {}" "Find files" "${EDITOR:-nvim} {}" "" "--multi"
}

_f_dir() {
  local target="${1:-.}"
  fd --type d --hidden --follow --exclude .git . "$target" 2>/dev/null |
    _f_search "tree -C {} | head -200" "Find directories" "cd {}"
}

_f_grep() {
  local query="${*:1}"
  local reload='reload:rg --column --color=always --smart-case {q} || :'
  local opener='if [[ $FZF_SELECT_COUNT -eq 0 ]]; then
                  ${EDITOR:-nvim} {1} +{2}
                else
                  ${EDITOR:-nvim} +cw -q {+f}
                fi'

  fzf --disabled --ansi --multi \
      --bind "start:$reload" --bind "change:$reload" \
      --bind "enter:become:$opener" \
      --bind 'alt-a:select-all,alt-d:deselect-all,ctrl-/:toggle-preview' \
      --delimiter : \
      --preview 'bat --style=full --color=always --highlight-line {2} {1}' \
      --preview-window '~4,+{2}+4/3,<80(up)' \
      --query "$query"
}

_f_checkout() {
  git rev-parse --is-inside-work-tree &>/dev/null || { echo "Not in git repo"; return 1; }

  git branch --all | grep -v HEAD |
    fzf --header "Git checkout branch" |
    sed "s/.* //" | sed "s#remotes/[^/]*/##" |
    xargs -I {} git checkout {}
}

_f_add() {
  git rev-parse --is-inside-work-tree &>/dev/null || { echo "Not in git repo"; return 1; }

  git -c color.status=always status --short |
    _f_search "git diff --color=always {2}" "Git add files" \
      "cut -c4- | sed 's/.* -> //' | xargs -r git add" "" "--ansi --multi"
  git status --short
}

_f_stash() {
  git rev-parse --is-inside-work-tree &>/dev/null || { echo "Not in git repo"; return 1; }

  local action="${1:-$(printf "apply\nshow\npop\ndrop\ncreate" | fzf --header "Choose stash action")}"
  [[ -z "$action" ]] && return 0

  case "$action" in
    create)
      read -r "msg?Stash message: "
      [[ -n "$msg" ]] && git stash push -m "$msg" || git stash push
      ;;
    show|apply|pop|drop)
      local stash=$(git stash list | fzf --header "Choose stash for $action" | grep -o "stash@{[0-9]*}")
      [[ -z "$stash" ]] && return 0

      case "$action" in
        show) git stash show -p "$stash" | bat --style=numbers,changes --color=always ;;
        apply) git stash apply "$stash" ;;
        pop) git stash pop "$stash" ;;
        drop) git stash drop "$stash" ;;
      esac
      ;;
  esac
}

_f_log() {
  git rev-parse --is-inside-work-tree &>/dev/null || { echo "Not in git repo"; return 1; }

  local author="${1:-}"
  local filter=""
  [[ -n "$author" ]] && filter="--author=$author"

  git log --graph --color=always --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" $filter |
    fzf --ansi --no-sort --reverse --tiebreak=index \
        --preview 'f() { set -- $(echo -- "$@" | grep -o "[a-f0-9]\{7\}"); [ $# -eq 0 ] || git show --color=always $1; }; f {}' \
        --preview-window=right:60% \
        --bind='ctrl-/:toggle-preview' \
        --header='Browse git log' \
        --bind='enter:execute:(grep -o "[a-f0-9]\{7\}" | head -1 | xargs -I % sh -c "git show --color=always % | less -R") <<< {}'
}

_f_kill() {
  ps -ef | sed 1d |
    _f_search "echo {}" "Kill process" "awk '{print \$2}' | xargs -r kill -${1:-15}" "" "--multi"
}

_f_port() {
  lsof -i -P -n | grep LISTEN |
    _f_search "echo {}" "Kill process on port" "awk '{print \$2}' | xargs -r kill -9"
}

_f_man() {
  man -k . |
    _f_search "echo {} | cut -d' ' -f1 | xargs -I% man %" "Browse man pages" \
      "awk '{print \$1}' | xargs -r man" "${1:-}" "--preview-window=right:70%"
}

_f_history() {
  history |
    _f_search "echo {}" "Search command history" \
      "awk '{print substr(\$0, index(\$0, \$2))}' | ${SHELL:-zsh}" "${1:-}" \
      "--sort --exact --preview-window=down:3:wrap"
}

_f_npm() {
  [[ ! -f package.json ]] && { echo "No package.json found"; return 1; }

  jq -r '.scripts | to_entries | .[] | .key' package.json |
    _f_search "jq -r .scripts.{} package.json" "Run npm script" \
      'xargs -I{} sh -c "echo \"Running npm run {}...\" && npm run {}"'
}

_f_z() {
  has_command zoxide || { error "zoxide not installed"; return 1; }

  local dir=$(zoxide query -l | _f_search "ls -la {}" "Jump to directory" "echo" "${1:-}")
  [[ -n "$dir" ]] && cd "$dir"
}

F_COMMANDS=(
  "find:fd,f:Find files:_f_find"
  "dir:d:Find directories:_f_dir"
  "grep:g,rg:Grep in files:_f_grep"
  "checkout:co:Git checkout:_f_checkout"
  "add:ga:Git add files:_f_add"
  "stash:gs:Git stash:_f_stash"
  "log:gl:Git log:_f_log"
  "kill:k:Kill process:_f_kill"
  "port:p:Kill by port:_f_port"
  "man:m:Browse man pages:_f_man"
  "history:h:Search history:_f_history"
  "npm:n:Run npm scripts:_f_npm"
  "z::Jump to directory:_f_z"
)

F_HELP=$(_cli_generate_help "f" "FZF-powered commands" "${F_COMMANDS[@]}")

f() { _cli_framework F f "$@"; }

################################################################################
# UTILITIES
################################################################################

ensure_dir() {
  [[ -z "$1" ]] && { echo "Usage: ensure_dir <dir>"; return 1; }
  [[ ! -d "$1" ]] && mkdir -p "$1" && success "Created directory: $1"
}

safe_source() {
  [[ -z "$1" ]] && { echo "Usage: safe_source <file>"; return 1; }
  [[ -r "$1" ]] && source "$1"
}

backup_file() {
  [[ -z "$1" ]] && { echo "Usage: backup_file <file> [backup_dir]"; return 1; }
  local file="$1" backup_dir="${2:-$_BACKUP_DIR}"

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
    [[ -f "$_DOTFILES/Brewfile" ]] && brew bundle install --verbose --global --all --force
  fi
}

setup_zsh() {
  info "Setting up ZSH configuration..."
  local zdotdir_src="${ZDOTDIR_SRC:-$_DOTFILES/config/zsh}"

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

verify_repo_structure() {
  info "Verifying repository structure..."

  [[ ! -d "$_DOTFILES" ]] && { error "Dotfiles directory not found at $_DOTFILES"; return 1; }
  [[ ! -d "$_DOTFILES/.git" ]] && { error "Not a git repository"; return 1; }

  local missing=()
  local required=(
    "Brewfile"
    "config"
    "config/zsh"
    "config/zsh/.zshenv"
    "config/zsh/.zprofile"
    "config/zsh/.zshrc"
    "config/zsh/utils.zsh"
  )

  for item in "${required[@]}"; do
    [[ ! -e "$_DOTFILES/$item" ]] && missing+=("$item")
  done

  if ((${#missing[@]} > 0)); then
    error "Missing required files:"
    printf "  - %s\n" "${missing[@]}"
    return 1
  fi

  success "Repository structure verified"
}

# Compatibility
alias dir_exists='ensure_dir'
alias file_exists='[[ -r "$1" ]]'

UTILS_COMMANDS=(
  "list::List all utility functions:list_utils"
  "ensure-dir:mkdir:Create directory if needed:ensure_dir"
  "safe-source:source:Source file if exists:safe_source"
  "backup::Backup file:backup_file"
)

UTILS_HELP=$(_cli_generate_help "utils" "Utility functions" "${UTILS_COMMANDS[@]}")

utils() { _cli_framework UTILS utils "$@"; }
