#!/usr/bin/env zsh

# ========================================================================
# ZSH Functions - Core utility functions organized by category
# ========================================================================

# ========================================================================
# Environment Settings
# ========================================================================
DOTFILES="${DOTFILES:-$HOME/dotfiles}"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"

# ========================================================================
# Logging Functions
# ========================================================================
function log_info() {
  printf '%s[INFO]%s %s\n' "${BLUE:-}" "${RESET:-}" "$*"
}

function log_success() {
  printf '%s[SUCCESS]%s %s\n' "${GREEN:-}" "${RESET:-}" "$*"
}

function log_warning() {
  printf '%s[WARNING]%s %s\n' "${YELLOW:-}" "${RESET:-}" "$*" >&2
}

function log_error() {
  printf '%s[ERROR]%s %s\n' "${RED:-}" "${RESET:-}" "$*" >&2
}

# Progress indicator
function show_progress() {
  printf '%s→%s %s...\n' "${BLUE:-}" "${RESET:-}" "$*"
}

# ========================================================================
# File & Directory Management
# ========================================================================

# Create and enter directory
function mkcd() {
  mkdir -p "$1" && cd "$1" || return 1
}

# Create symbolic link with parent directory creation if needed
function slink() {
  local src_orig="$1"
  local dst_link="$2"
  local dst_dir

  dst_dir=$(dirname "$dst_link")
  mkdir -p "$dst_dir"
  ln -sf "$src_orig" "$dst_link"
}

# Clean .DS_Store files
function clean_ds_store() {
  log_info "Cleaning .DS_Store files..."
  find "${1:-$DOTFILES}" -name ".DS_Store" -delete
  log_success "Finished cleaning .DS_Store files"
}

# Extract various archive formats
function extract() {
  if [[ ! -f "$1" ]]; then
    log_error "'$1' is not a valid file"
    return 1
  fi

  case "$1" in
  *.tar.bz2) tar xjf "$1" ;;
  *.tar.gz) tar xzf "$1" ;;
  *.bz2) bunzip2 "$1" ;;
  *.rar) unrar x "$1" ;;
  *.gz) gunzip "$1" ;;
  *.tar) tar xf "$1" ;;
  *.tbz2) tar xjf "$1" ;;
  *.tgz) tar xzf "$1" ;;
  *.zip) unzip "$1" ;;
  *.Z) uncompress "$1" ;;
  *.7z) 7z x "$1" ;;
  *) log_error "'$1' cannot be extracted" ;;
  esac
}

# Enhanced tree command with eza/exa if available
function lstree() {
  local level="${1:-2}"

  if command -v eza &>/dev/null; then
    eza --tree --level="$level" --icons
  elif command -v exa &>/dev/null; then
    exa --tree --level="$level" --icons
  else
    find . -type d -not -path "*/\.*" -not -path "*/node_modules/*" -maxdepth "$level" | sort | sed -e 's/[^-][^\/]*\//  |/g' -e 's/|\([^ ]\)/|-\1/'
  fi
}

# ========================================================================
# Directory Bookmarks
# ========================================================================

# Create directory bookmark
function bm() {
  local mark_dir="$XDG_DATA_HOME/marks"
  mkdir -p "$mark_dir"
  ln -sf "$(pwd)" "$mark_dir/$1"
  log_success "Created bookmark '$1' -> $(pwd)"
}

# List all bookmarks
function marks() {
  local mark_dir="$XDG_DATA_HOME/marks"
  if [[ ! -d "$mark_dir" ]]; then
    log_error "No bookmarks directory found at $mark_dir"
    return 1
  fi

  ls -l "$mark_dir" | sed 's/  / /g' | cut -d' ' -f9- | sed 's/ -/\t-/g'
}

# Jump to bookmark
function jump() {
  local mark_dir="$XDG_DATA_HOME/marks"
  local mark="$1"

  if [[ -L "$mark_dir/$mark" ]]; then
    cd "$(readlink "$mark_dir/$mark")" || return 1
  else
    log_error "No such bookmark: $mark"
    return 1
  fi
}

# ========================================================================
# Git Utilities
# ========================================================================

# Clean merged branches
function gclean() {
  local branches_to_delete

  branches_to_delete=$(git branch --merged | grep -v "^\*" | grep -v "master\|main\|develop")

  if [[ -z "$branches_to_delete" ]]; then
    log_info "No merged branches to delete."
    return 0
  fi

  echo "The following branches will be deleted:"
  echo "$branches_to_delete"
  read -q "REPLY?Are you sure you want to delete these branches? [y/N] "
  echo

  if [[ $REPLY =~ ^[Yy]$ ]]; then
    git branch --merged | grep -v "^\*" | grep -v "master\|main\|develop" | xargs git branch -d
    log_success "Branches deleted successfully!"
  else
    log_info "Operation canceled."
  fi
}

# ========================================================================
# System & macOS Utilities
# ========================================================================

# Toggle macOS hidden files
function togglehidden() {
  local current
  current=$(defaults read com.apple.finder AppleShowAllFiles)
  defaults write com.apple.finder AppleShowAllFiles $((!current))
  killall Finder
  log_success "Finder hidden files: $((!current))"
}

# Quick Look from terminal
function ql() {
  qlmanage -p "$@" &>/dev/null
}

# Weather information with optional location
function weather() {
  local city="${1:-}"
  curl -s "wttr.in/$city?format=v2"
}

# Kill process running on a specified port
function killport() {
  local port="$1"
  if [[ -z "$port" ]]; then
    log_error "Please specify a port number"
    return 1
  fi

  local pid
  pid=$(lsof -i ":$port" | awk 'NR!=1 {print $2}')

  if [[ -z "$pid" ]]; then
    log_error "No process found on port $port"
    return 1
  fi

  echo "Killing process(es) on port $port: $pid"
  echo "$pid" | xargs kill -9
  log_success "Process(es) killed"
}

# Show top 10 largest files in current directory
function ducks() {
  du -sh * | sort -rh | head -10
}

# Improved man pages with bat
function batman() {
  MANPAGER="sh -c 'col -bx | bat -l man -p'" man "$@"
}

# ========================================================================
# Yazi File Manager Configuration
# ========================================================================
function y() {
  local tmp cwd
  tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(command cat -- "$tmp")" && [[ -n "$cwd" ]] && [[ "$cwd" != "$PWD" ]]; then
    builtin cd -- "$cwd" || return 1
  fi
  rm -f -- "$tmp"
}

# ========================================================================
# Homebrew Bundle Management
# ========================================================================
function bb() {
  case "$1" in
  save)
    brew bundle dump --force --describe --global
    ;;
  install)
    brew bundle install --global --all
    ;;
  check)
    brew bundle check --global --verbose --all
    ;;
  unlisted)
    brew bundle cleanup --global --verbose --all --zap
    ;;
  clean)
    brew bundle cleanup --global --verbose --all --zap -f
    ;;
  edit)
    brew bundle edit --global
    ;;
  *)
    echo "Usage: bb [save|install|check|unlisted|clean|edit]"
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
