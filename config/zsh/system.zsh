#!/usr/bin/env zsh

# ========================================================================
# Dotfiles Symlink Map Configuration
# ========================================================================

# This file defines the mapping between dotfiles source locations and their
# target locations in the user's home directory. It's used by the installation
# script and other dotfiles management tools.

declare -gA DOTFILES_TO_SYMLINK_MAP=(
  # Git configurations
  ["$DOTFILES/config/git/gitconfig"]="$HOME/.gitconfig"
  ["$DOTFILES/config/git/gitignore"]="$HOME/.gitignore"
  ["$DOTFILES/config/git/gitattributes"]="$HOME/.gitattributes"
  ["$DOTFILES/config/git/gitmessage"]="$HOME/.gitmessage"

  # XDG configurations
  ["$DOTFILES/config/starship.toml"]="$XDG_CONFIG_HOME/starship.toml"
  ["$DOTFILES/config/karabiner/karabiner.json"]="$XDG_CONFIG_HOME/karabiner/karabiner.json"
  ["$DOTFILES/config/nvim"]="$XDG_CONFIG_HOME/nvim"
  ["$DOTFILES/config/ghostty"]="$XDG_CONFIG_HOME/ghostty"
  ["$DOTFILES/config/atuin"]="$XDG_CONFIG_HOME/atuin"
  ["$DOTFILES/config/bat"]="$XDG_CONFIG_HOME/bat"
  ["$DOTFILES/config/lazygit"]="$XDG_CONFIG_HOME/lazygit"
  ["$DOTFILES/config/zellij"]="$XDG_CONFIG_HOME/zellij"
  ["$DOTFILES/config/zed"]="$XDG_CONFIG_HOME/zed"
  ["$DOTFILES/config/espanso"]="$XDG_CONFIG_HOME/espanso"
  ["$DOTFILES/config/yazi"]="$XDG_CONFIG_HOME/yazi"
  ["$DOTFILES/config/warp/keybindings.yaml"]="$XDG_CONFIG_HOME/warp/keybindings.yaml"

  # Editor configurations
  ["$DOTFILES/config/vscode/settings.json"]="$HOME/Library/Application Support/Code/User/settings.json"
  ["$DOTFILES/config/vscode/keybindings.json"]="$HOME/Library/Application Support/Code/User/keybindings.json"
  ["$DOTFILES/config/cursor/settings.json"]="$HOME/Library/Application Support/Cursor/User/settings.json"
  ["$DOTFILES/config/cursor/keybindings.json"]="$HOME/Library/Application Support/Cursor/User/keybindings.json"

  # macOS-specific configurations
  ["$DOTFILES/config/hammerspoon"]="$HOME/.hammerspoon"

  # AI tools configurations
  ["$DOTFILES/config/ai/claude/claude_desktop_config.json"]="$HOME/Library/Application Support/Claude/claude_desktop_config.json"
  ["$DOTFILES/config/ai/cline/cline_mcp_settings.json"]="$HOME/Library/Application Support/Cursor/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json"
)

# Define additional paths that might have specific Apple Silicon considerations
# if needed in the future

# Export the map for use in other scripts
export DOTFILES_TO_SYMLINK_MAP

# ========================================================================
# ZSH aliases - Organized by category
# ========================================================================

# alias optbrew="/opt/homebrew/bin/brew"
# ========================================================================
# System utils
# ========================================================================
# Color with built-in ANSI codes, no external dependencies
# alias penv='printenv | sort | awk -F= '\''{
#   printf "\033[36m%-30s\033[0m \033[37m%s\033[0m\n", $1, $2
# }'\'''

# ========================================================================
# Navigation Shortcuts
# ========================================================================
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias home="cd ~"

# ========================================================================
# List Files - Prioritize eza/exa with fallback to ls
# ========================================================================
if command -v eza &>/dev/null; then
  alias ls="eza --icons --group-directories-first"
  alias ll="eza --icons --group-directories-first -la"
  alias la="eza --icons --group-directories-first -a"
  alias lt="eza --icons --group-directories-first --tree"
  alias lt2="eza --icons --group-directories-first --tree --level=2"
else
  alias ls="ls -G"
  alias ll="ls -la"
  alias la="ls -a"
fi

# ========================================================================
# File Operations - Safety Guards
# ========================================================================
# alias cp="cp -i"       # Confirm before overwriting
# alias mv="mv -i"       # Confirm before overwriting
# alias rm="rm -i"       # Confirm before removal
# alias mkdir="mkdir -p" # Create parent directories as needed

# ========================================================================
# Networking Utilities
# ========================================================================
alias ip="ipconfig getifaddr en0"
alias localip="ipconfig getifaddr en0"
alias publicip="curl -s https://api.ipify.org"
alias ports="sudo lsof -i -P -n | grep LISTEN"
alias flush="dscacheutil -flushcache && killall -HUP mDNSResponder" # Flush DNS

# ========================================================================
# Dotfiles Management
# ========================================================================

# Keep individual aliases for quick access (see functions.zsh for util func "dot()")
alias cdz='cd $ZDOTDIR'
alias cdd="cd $DOTFILES"

# alias ze="fd --no-ignore --hidden --follow --type f -x $EDITOR $ZDOTDIR"
alias zr="exec zsh"
alias ze="fd --hidden . $ZDOTDIR | xargs nvim"
alias dot="fd --hidden . $DOTFILES | xargs nvim"
# alias dotedit="fd --no-ignore --hidden --follow --type f -x $EDITOR $DOTFILES"

# ========================================================================
# System Information
# ========================================================================
alias ppath='echo $PATH | tr ":" "\n"'
alias pfuncs='print -l ${(k)functions[(I)[^_]*]} | sort'
alias pfpath='for fp in $fpath; do echo $fp; done; unset fp'
alias printpath='ppath'
alias printfuncs='pfuncs'
alias printfpath='pfpath'

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
  command -v "$1" &>/dev/null
  # command -v "$1" >/dev/null 2>&1
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

# #################################################################################
# # MacOS utils
# #################################################################################
#
# Apply common macOS system preferences
function defaults_apply() {
  if ! is_macos; then
    log_error "Not running on macOS"
    return 1
  fi

  log_info "Applying macOS preferences..."

  defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
  defaults write NSGlobalDomain AppleShowAllExtensions -bool true
  defaults write NSGlobalDomain InitialKeyRepeat -int 15
  defaults write NSGlobalDomain KeyRepeat -int 2
  defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool TRUE
  defaults write com.apple.dock autohide -bool false
  defaults write com.apple.dock autohide -bool true
  defaults write com.apple.dock autohide-delay -float 0
  defaults write com.apple.dock show-recents -bool false
  defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
  defaults write com.apple.finder AppleShowAllFiles -bool true
  defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
  defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
  defaults write com.apple.finder ShowPathbar -bool true
  defaults write com.apple.finder ShowStatusBar -bool true
  defaults write com.apple.finder _FXSortFoldersFirst -bool true

  # Restart affected applications
  for app in "Finder" "Dock"; do
    killall "$app" >/dev/null 2>&1
  done

  log_success "macOS preferences applied"
}

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
alias ql='sys ql'
alias batman='sys man'
# alias ducks='sys ducks'

# ========================================================================
# Text Editors and Cat Replacement
# ========================================================================
# has_command nvim && alias vim="nvim" && alias vi="nvim"
# has_command bat && alias cat="bat"

# ========================================================================
# Misc Shortcuts
# ========================================================================
alias c="clear"
alias hf="huggingface-cli"
