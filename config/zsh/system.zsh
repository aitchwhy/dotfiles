#!/usr/bin/env zsh

# ========================================================================
# Logging Functions
# ========================================================================
function info() {
  printf '%s[INFO]%s %s\n' "${BLUE:-}" "${RESET:-}" "$*"
}

function success() {
  printf '%s[SUCCESS]%s %s\n' "${GREEN:-}" "${RESET:-}" "$*"
}

function warn() {
  printf '%s[WARNING]%s %s\n' "${YELLOW:-}" "${RESET:-}" "$*" >&2
}

function error() {
  printf '%s[ERROR]%s %s\n' "${RED:-}" "${RESET:-}" "$*" >&2
}

# ========================================================================
# System Detection
# ========================================================================
function is_macos() {
  [[ "$(uname -s)" == "Darwin" ]]
}

function is_apple_silicon() {
  [[ "$(uname -m)" == "arm64" ]]
}

function is_rosetta() {
  # Check if a process is running under Rosetta translation
  if is_apple_silicon; then
    local arch_output
    arch_output=$(arch)
    [[ "$arch_output" != "arm64" ]]
  else
    false
  fi
}

function get_macos_version() {
  if is_macos; then
    sw_vers -productVersion
  else
    echo "Not macOS"
  fi
}

function has_command() {
  # command -v "$1" &>/dev/null
  command -v "$1" >/dev/null 2>&1
}

# # Initialize tools if installed
# has_command() {
#   command -v "$1" >/dev/null 2>&1
# }

# ========================================================================
# File & Directory Operations
# ========================================================================
function ensure_dir() {
  local dir="$1"
  if [[ ! -d "$dir" ]]; then
    mkdir -p "$dir"
    success "Created directory: $dir"
  fi
}

function backup_file() {
  local file="$1"
  if [[ -e "$file" ]]; then
    local backup_dir="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"
    ensure_dir "$backup_dir"
    mv "$file" "$backup_dir/"
    success "Backed up $file to $backup_dir"
  fi
}
# ========================================================================
# System & macOS Utilities
# ========================================================================
#
# #
# # # OS detection
# # is_macos() {
# #     [ "$(uname)" = "Darwin" ]
# # }
# #
# # is_linux() {
# #     [ "$(uname)" = "Linux" ]
# # }
# #
# # # Architecture detection
# # is_arm64() {
# #     [ "$(uname -m)" = "arm64" ] || [ "$(uname -m)" = "aarch64" ]
# # }
# #
# # is_x86_64() {
# #     [ "$(uname -m)" = "x86_64" ]
# # }
# #
# # # Shell detection
# # is_zsh() {
# #     [ -n "$ZSH_VERSION" ]
# # }
# #
# # is_bash() {
# #     [ -n "$BASH_VERSION" ]
# # }
# #

# #################################################################################
# # MacOS utils
# #################################################################################
#
# # Apply common macOS system preferences
# defaults_apply() {
#     if ! is_macos; then
#         log_error "Not running on macOS"
#         return 1
#     fi
#
#     log_info "Applying macOS preferences..."
#
#     defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
#     defaults write NSGlobalDomain AppleShowAllExtensions -bool true
#     defaults write NSGlobalDomain InitialKeyRepeat -int 15
#     defaults write NSGlobalDomain KeyRepeat -int 2
#     defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool TRUE
#     defaults write com.apple.dock autohide -bool false
#     defaults write com.apple.dock autohide -bool true
#     defaults write com.apple.dock autohide-delay -float 0
#     defaults write com.apple.dock show-recents -bool false
#     defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
#     defaults write com.apple.finder AppleShowAllFiles -bool true
#     defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
#     defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
#     defaults write com.apple.finder ShowPathbar -bool true
#     defaults write com.apple.finder ShowStatusBar -bool true
#     defaults write com.apple.finder _FXSortFoldersFirst -bool true
#
#     # Restart affected applications
#     for app in "Finder" "Dock"; do
#         killall "$app" >/dev/null 2>&1
#     done
#
#     log_success "macOS preferences applied"
# }

# ========================================================================
# System & macOS Utilities
# ========================================================================
function sys() {
  case "$1" in
  env | env-grep)
    echo "======== env vars =========="
    if [ -z "$2" ]; then
      printenv | sort | awk -F= '{ printf "%-30s %s\n", $1, $2 }'
    else
      printenv | sort | grep -i "$2" | awk -F= '{ printf "%-30s %s\n", $1, $2 }'
    fi
    echo "============================" # Search environment variables
    ;;

  hidden | toggle-hidden)
    local current
    current=$(defaults read com.apple.finder AppleShowAllFiles)
    defaults write com.apple.finder AppleShowAllFiles $((!current))
    killall Finder
    echo "Finder hidden files: $((!current))" # Toggle macOS hidden files
    ;;

  ql | quick-look)
    if [ -z "$2" ]; then
      echo "Usage: sys ql <file>"
      return 1
    fi
    qlmanage -p "${@:2}" &>/dev/null # Quick Look files from terminal
    ;;

  weather | wttr)
    local city="${2:-}"
    curl -s "wttr.in/$city?format=v2" # Get weather information
    ;;

  killport | kill-port)
    local port="$2"
    if [[ -z "$port" ]]; then
      echo "Please specify a port number"
      return 1
    fi

    local pid
    pid=$(lsof -i ":$port" | awk 'NR!=1 {print $2}')

    if [[ -z "$pid" ]]; then
      echo "No process found on port $port"
      return 1
    fi

    echo "Killing process(es) on port $port: $pid"
    echo "$pid" | xargs kill -9
    echo "Process(es) killed" # Kill process on specified port
    ;;

  ducks | top-files)
    local count="${2:-10}"
    du -sh * | sort -rh | head -"$count" # Show largest files in directory
    ;;

  man | batman)
    MANPAGER="sh -c 'col -bx | bat -l man -p'" man "${@:2}" # Improved man pages with bat
    ;;

  ports | listening)
    sudo lsof -iTCP -sTCP:LISTEN -n -P # Show all listening ports
    ;;

  space | disk)
    df -h # Check disk space usage
    ;;

  cpu)
    top -l 1 | grep -E "^CPU" # Show CPU usage
    ;;

  mem | memory)
    vm_stat | perl -ne '/page size of (\d+)/ and $size=$1; /Pages\s+([^:]+)[^\d]+(\d+)/ and printf("%-16s % 16.2f MB\n", "$1:", $2 * $size / 1048576);' # Show memory usage
    ;;

  path)
    echo $PATH | tr ':' '\n' | nl # List PATH entries
    ;;

  ip | myip)
    echo "Public IP: $(curl -s https://ipinfo.io/ip)"
    echo "Local IP: $(ipconfig getifaddr en0)" # Show IP addresses
    ;;

  help | *)
    if [[ "$1" != "help" && ! -z "$1" ]]; then
      echo "Unknown command: $1"
    fi

    echo "Usage: sys [command]"
    echo ""
    echo "Commands:"
    echo "  env [pattern]      - Display environment variables, optionally filtered"
    echo "  hidden             - Toggle hidden files in Finder"
    echo "  ql <file>          - Quick Look a file"
    echo "  weather [city]     - Show weather information"
    echo "  killport <port>    - Kill process running on specified port"
    echo "  ducks [count]      - Show largest files in current directory"
    echo "  man <command>      - Show man pages with syntax highlighting"
    echo "  ports              - Show all listening ports"
    echo "  space              - Check disk space usage"
    echo "  cpu                - Show CPU usage"
    echo "  mem                - Show memory usage"
    echo "  path               - List PATH entries"
    echo "  ip                 - Show public and local IP addresses"
    ;;
  esac
}

# ========================================================================
# Advanced Search with ripgrep + fzf + nvim
# ========================================================================
function rfv() {
  local RELOAD='reload:rg --column --color=always --smart-case {q} || :'
  local OPENER='if [[ $FZF_SELECT_COUNT -eq 0 ]]; then
                  vim {1} +{2}     # No selection. Open the current line in Vim.
                else
                  vim +cw -q {+f}  # Build quickfix list for the selected items.
                fi'

  fzf --disabled --ansi --multi \
    --bind "start:$RELOAD" --bind "change:$RELOAD" \
    --bind "enter:become:$OPENER" \
    --bind "ctrl-o:execute:$OPENER" \
    --bind 'alt-a:select-all,alt-d:deselect-all,ctrl-/:toggle-preview' \
    --delimiter : \
    --preview 'bat --style=full --color=always --highlight-line {2} {1}' \
    --preview-window '~4,+{2}+4/3,<80(up)' \
    --query "$*"
}

# # Keep commonly used aliases for convenience
alias penv='sys env'
# alias weather='sys weather'
# alias ql='sys ql'
# alias batman='sys man'
# alias ducks='sys ducks'
