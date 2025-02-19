#!/usr/bin/env bash

# Enhanced cd with ls
# function cd() {
#     builtin cd "$@" && eza --icons --group-directories-first
# }

# Create and enter directory
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Extract archives
extract() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2) tar xjf "$1" ;;
            *.tar.gz)  tar xzf "$1" ;;
            *.bz2)     bunzip2 "$1" ;;
            *.rar)     unrar x "$1" ;;
            *.gz)      gunzip "$1"  ;;
            *.tar)     tar xf "$1"  ;;
            *.tbz2)    tar xjf "$1" ;;
            *.tgz)     tar xzf "$1" ;;
            *.zip)     unzip "$1"   ;;
            *.Z)       uncompress "$1" ;;
            *.7z)      7z x "$1"    ;;
            *)         echo "'$1' cannot be extracted" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Git utilities

# Unalias conflicting names (e.g. 'gco') before defining functions
# unalias gco 2>/dev/null

# Enhanced git checkout
# gco() {
#     if [ $# -eq 0 ]; then
#         git branch | fzf | xargs git checkout
#     else
#         git checkout "$@"
#     fi
# }


# Git add with fzf
# unalias ga 2>/dev/null
# ga() {
#     if [ $# -eq 0 ]; then
#         git status -s | fzf --multi | awk '{print $2}' | xargs git add
#     else
#         git add "$@"
#     fi
# }

# Clean merged branches
# unalias gclean 2>/dev/null
gclean() {
    git branch --merged | grep -v '\*\|master\|main\|develop' | xargs -n 1 git branch -d
}

# Docker utilities
# Docker exec with container selection
# unalias dex 2>/dev/null
# dex() {
#     local cid
#     cid=$(docker ps | sed 1d | fzf -q "$1" | awk '{print $1}')
#     [ -n "$cid" ] && docker exec -it "$cid" "${2:-bash}"
# }

# Docker container logs
# unalias dlog 2>/dev/null
# dlog() {
#     local cid
#     cid=$(docker ps | sed 1d | fzf -q "$1" | awk '{print $1}')
#     [ -n "$cid" ] && docker logs -f "$cid"
# }

# System utilities
# Find large files
bigfiles() {
    local size="${1:-500M}"
    fd --type f --size "+${size}" . "${2:-.}" 
}

# Process management
killport() {
    local port="$1"
    lsof -i ":$port" | awk 'NR!=1 {print $2}' | xargs kill
}

# Directory utilities
# Directory bookmarks
bm() {
    local mark_dir="$XDG_DATA_HOME/marks"
    mkdir -p "$mark_dir"
    ln -s "$(pwd)" "$mark_dir/$1"
}

# jump() {
#     local mark_dir="$XDG_DATA_HOME/marks"
#     cd -P "$mark_dir/$1" 2>/dev/null || echo "No such mark: $1"
# }
#
marks() {
    local mark_dir="$XDG_DATA_HOME/marks"
    ls -l "$mark_dir" | sed 's/  / /g' | cut -d' ' -f9- | sed 's/ -/\t-/g'
}

# # Enhanced tree command with eza
# lstree() {
#     eza --tree --level="${1:-2}" --icons
# }
#
# # Weather information
# weather() {
#     local city="${1:-}"
#     curl -s "wttr.in/$city?format=v2"
# }
#
# # Quick HTTP server
# serve() {
#     local port="${1:-8000}"
#     python3 -m http.server "$port"
# }
#
# # macOS specific
# # Show/hide hidden files
# togglehidden() {
#     local current=$(defaults read com.apple.finder AppleShowAllFiles)
#     defaults write com.apple.finder AppleShowAllFiles $((!current))
#     killall Finder
# }
#
# # Quick Look from terminal
# ql() {
#     qlmanage -p "$@" &>/dev/null
# }
#
# Additional utilities will be added as needed...
#
# ###############################
# # fzf examples -> https://github.com/junegunn/fzf/wiki/examples#homebrew
# ###############################
#
#
#
# # Clean .DS_Store files
# clean_ds_store() {
#   log "Cleaning .DS_Store files..."
#   find "$DOTFILES" -name ".DS_Store" -delete
# }
#
# # Default paths (can be overridden before sourcing)
# DOTFILES="${DOTFILES:-$HOME/dotfiles}"
# CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
#
# # Logging functions
# log_info() {
#     printf '%s[INFO]%s %s\n' "${BLUE}" "${RESET}" "$*"
# }
#
# log_success() {
#     printf '%s[SUCCESS]%s %s\n' "${GREEN}" "${RESET}" "$*"
# }
#
# log_warning() {
#     printf '%s[WARNING]%s %s\n' "${YELLOW}" "${RESET}" "$*" >&2
# }
#
# log_error() {
#     printf '%s[ERROR]%s %s\n' "${RED}" "${RESET}" "$*" >&2
# }
#
# # Progress indicator
# show_progress() {
#     printf '%s→%s %s...\n' "${BLUE}" "${RESET}" "$*"
# }
#
#
# ################################################################################
# # SYSTEM AND ENVIRONMENT DETECTION
# ################################################################################
#
# # OS detection
# is_macos() {
#     [ "$(uname)" = "Darwin" ]
# }
#
# is_linux() {
#     [ "$(uname)" = "Linux" ]
# }
#
# # Architecture detection
# is_arm64() {
#     [ "$(uname -m)" = "arm64" ] || [ "$(uname -m)" = "aarch64" ]
# }
#
# is_x86_64() {
#     [ "$(uname -m)" = "x86_64" ]
# }
#
# # Shell detection
# is_zsh() {
#     [ -n "$ZSH_VERSION" ]
# }
#
# is_bash() {
#     [ -n "$BASH_VERSION" ]
# }
#
# ################################################################################
# # PACKAGE MANAGEMENT
# # https://github.com/junegunn/fzf/wiki/examples#homebrew
# ################################################################################
#
# # Homebrew utilities
# function has_brew() {
#     command -v brew >/dev/null 2>&1
# }
#
# function ensure_brew() {
#     if ! has_brew; then
#         log_info "Installing Homebrew..."
#         /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
#
#         # Add to PATH for current session if installed
#         if is_arm64; then
#             eval "$(/opt/homebrew/bin/brew shellenv)"
#         else
#             eval "$(/usr/local/bin/brew shellenv)"
#         fi
#     fi
# }
#
# function update_brew() {
#     if has_brew; then
#         log_info "Updating Homebrew..."
#         brew update
#         brew upgrade
#         brew cleanup
#     fi
# }
#
#
#
# ################################################################################
# # MACOS SPECIFIC UTILITIES
# ################################################################################
#
# # Apply common macOS system preferences
# apply_macos_prefs() {
#     if ! is_macos; then
#         log_error "Not running on macOS"
#         return 1
#     fi
#
#     log_info "Applying macOS preferences..."
#
#     # Finder preferences
#     defaults write com.apple.finder AppleShowAllFiles -bool true
#     defaults write NSGlobalDomain AppleShowAllExtensions -bool true
#     defaults write com.apple.finder ShowPathbar -bool true
#     defaults write com.apple.finder ShowStatusBar -bool true
#
#     # Dock preferences
#     defaults write com.apple.dock autohide -bool true
#     defaults write com.apple.dock autohide-delay -float 0
#     defaults write com.apple.dock show-recents -bool false
#
#     # Keyboard preferences
#     defaults write NSGlobalDomain KeyRepeat -int 2
#     defaults write NSGlobalDomain InitialKeyRepeat -int 15
#     defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
#
#     # Restart affected applications
#     for app in "Finder" "Dock"; do
#         killall "$app" >/dev/null 2>&1
#     done
#
#     log_success "macOS preferences applied"
# }
#
#
#
# # Create directory and cd into it
# mkcd() {
#     mkdir -p "$1" && cd "$1"
# }
#
#
# function symlinks_dead_configs() {
#   CONFIGS_DIR="$HOME/.config"
#   fd -H -t l . "$CONFIGS_DIR" | while read -r link; do
#     if [ ! -e "$(readlink -f "$link")" ]; then
#       echo "Found dead symlink @ $link --- removing..."
#       unlink $link
#     fi
#   done
# }
#
# # Extract various archive formats
# extract() {
#     if [ -f $1 ]; then
#         case $1 in
#             *.tar.bz2)  tar xjf $1   ;;
#             *.tar.gz)   tar xzf $1   ;;
#             *.bz2)      bunzip2 $1   ;;
#             *.rar)      unrar x $1   ;;
#             *.gz)       gunzip $1    ;;
#             *.tar)      tar xf $1    ;;
#             *.tbz2)     tar xjf $1   ;;
#             *.tgz)      tar xzf $1   ;;
#             *.zip)      unzip $1     ;;
#             *.Z)        uncompress $1 ;;
#             *.7z)       7z x $1      ;;
#             *)          echo "'$1' cannot be extracted via extract()" ;;
#         esac
#     else
#         echo "'$1' is not a valid file"
#     fi
# }
#
# # Create a new directory and enter it
# function take() {
#   mkdir -p "$@" && cd "$@"
# }
#
# # fzf + zoxide integration
# function z() {
#   local dir
#   dir=$(
#     zoxide query --list --score |
#     fzf --height 40% --layout reverse --info inline \
#         --preview 'tree -C {} | head -200' \
#         --preview-window='right:60%:border-left' \
#         --bind='ctrl-/:toggle-preview' \
#         --border-label='Zoxide Directories' \
#         --nth 2.. --tac --query "$*"
#   ) && cd "$(echo "$dir" | sed 's/^[0-9,.]* *//')"
# }
#
# # ripgrep + fzf + neovim integration
# function rgv() {
#   local file
#   local line
#
#   read -r file line <<<"$(rg --no-heading --line-number "$@" |
#     fzf --delimiter : \
#         --preview 'bat --style=numbers --color=always --highlight-line {2} {1}' \
#         --preview-window='right:60%:border-left+{2}+3/3,~3' \
#         --bind='ctrl-/:toggle-preview')"
#
#   if [[ -n "$file" ]]; then
#     nvim "$file" +"$line"
#   fi
# }
#
# # Homebrew bundle management
# # function brewfile() {
# #   case "$1" in
# #     save)
# #       brew bundle dump --force --describe --file="$HOMEBREW_BUNDLE_FILE"
# #       ;;
# #     install)
# #       brew bundle --file="$HOMEBREW_BUNDLE_FILE"
# #       ;;
# #     check)
# #       brew bundle check --verbose --file="$HOMEBREW_BUNDLE_FILE"
# #       ;;
# #     clean)
# #       brew bundle cleanup --force --file="$HOMEBREW_BUNDLE_FILE"
# #       ;;
# #     *)
# #       echo "Usage: brewfile [save|install|check|clean]"
# #       ;;
# #   esac
# # }
#
# # Docker shortcuts
# function dex() {
#   docker exec -it "$1" "${2:-bash}"
# }
#
# function dlog() {
#   docker logs -f "$1"
# }
#
# # Git utilities
# function gclean() {
#   git branch --merged | grep -v '\*\|master\|main\|develop' | xargs -n 1 git branch -d
# }
#
# # macOS utilities
# function spot() {
#   mdfind "kMDItemDisplayName == '$@'wc"
# }
#
# # Quick HTTP server
# function serve() {
#   local port="${1:-8000}"
#   python3 -m http.server "$port"
# }
#
# # ====== Yazi File Manager Configuration ======
# function y() {
# 	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
# 	yazi "$@" --cwd-file="$tmp"
# 	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
# 		builtin cd -- "$cwd"
# 	fi
# 	rm -f -- "$tmp"
# }
#
# # -----------------------------------------------------
# # Custom functions (example)
# # -----------------------------------------------------
#
#
#
# # Custom functions
# # symlink
# slink() {
#     local src_orig=$1
#     local dst_link=$2
#     local dst_dir=$(dirname "$dst_link")
#     mkdir -p "$dst_dir"
#     ln -sf "$src_orig" "$dst_link"
# }
#
# mkcd () {
#  mkdir -p "$1" && cd "$1"
# }
#
#
# # custom functions
# # symlink
# slink() {
#     local src_orig=$1
#     local dst_link=$2
#     local dst_dir=$(dirname "$dst_link")
#
#     # Create the directory if it does not exist
#     mkdir -p "$dst_dir"
#
#     # Create the symlink
#     ln -sf "$src_orig" "$dst_link"
# }
#
# # fzf + zoxide :  https://junegunn.github.io/fzf/examples/directory-navigation/#zoxidehttpsgithubcomajeetdsouzazoxide
# z() {
#   local dir=$(
#     zoxide query --list --score |
#     fzf --height 40% --layout reverse --info inline \
#         --nth 2.. --tac --no-sort --query "$*" \
#         --bind 'enter:become:echo {2..}'
#   ) && cd "$dir"
# }
#
# # ripgrep->fzf->nvim [QUERY]
# # https://junegunn.github.io/fzf/tips/ripgrep-integration/#8-handle-multiple-selections
# rfv() (
#   RELOAD='reload:rg --column --color=always --smart-case {q} || :'
#   OPENER='if [[ $FZF_SELECT_COUNT -eq 0 ]]; then
#             vim {1} +{2}     # No selection. Open the current line in Vim.
#           else
#             vim +cw -q {+f}  # Build quickfix list for the selected items.
#           fi'
#   fzf --disabled --ansi --multi \
#       --bind "start:$RELOAD" --bind "change:$RELOAD" \
#       --bind "enter:become:$OPENER" \
#       --bind "ctrl-o:execute:$OPENER" \
#       --bind 'alt-a:select-all,alt-d:deselect-all,ctrl-/:toggle-preview' \
#       --delimiter : \
#       --preview 'bat --style=full --color=always --highlight-line {2} {1}' \
#       --preview-window '~4,+{2}+4/3,<80(up)' \
#       --query "$*"
# )
#
# # # https://github.com/junegunn/fzf/issues/2789
# # rfv() {
# #   # rg
# #   # --field-match-separator ' ' - tell rg to separate the filename and linenumber with
# #   # spaces to play well with fzf, (when recognizing index variables to use in the fzf
# #   # preview command, fzf uses a default delimiter of space, see below)
# #
# #   # fzf
# #   # --preview window ~8,+{1}-5
# #   #   this is a fzf feature
# #   #   ~8 - show first 8 lines (header)
# #   #   +{2} - fzf delimits the input piped in to it and provides access via index variables {n}. 
# #   #   the default delimiter fzf uses is space but can be specified via --delimiter <delimiter>
# #   #   pass the second index variable from bat (which is the line number)
# #   #   the number is signed, you can show eg the +n row or the -n row (the nth row from the bottom)
# #   #   -5 subtract 5 rows (go up 5 rows) so that you don't show the highlighted line as the first line
# #   #   since you want to provide context by showing the rows above the highlighted line
# #
# #   rg --line-number --with-filename . --color=always --field-match-separator ' '\
# #     | fzf --preview "bat --color=always {1} --highlight-line {2}" \
# #     --preview-window ~8,+{2}-5
# # }
