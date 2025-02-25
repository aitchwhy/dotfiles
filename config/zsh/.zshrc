# Performance monitoring (uncomment to debug startup time)
# zmodload zsh/zprof

# Shell Options
setopt AUTO_CD              # Change directory without cd
setopt AUTO_PUSHD           # Push directory to stack on cd
setopt PUSHD_IGNORE_DUPS    # Don't store duplicates in stack
setopt PUSHD_SILENT         # Don't print stack after pushd/popd
setopt EXTENDED_GLOB        # Extended globbing
setopt INTERACTIVE_COMMENTS # Allow comments in interactive shells
setopt NO_CASE_GLOB         # Case insensitive globbing

# History Options
setopt EXTENDED_HISTORY       # Record timestamp
setopt HIST_EXPIRE_DUPS_FIRST # Delete duplicates first
setopt HIST_IGNORE_DUPS       # Don't record duplicates
setopt HIST_VERIFY            # Don't execute immediately upon history expansion
setopt SHARE_HISTORY          # Share history between sessions
setopt HIST_IGNORE_SPACE      # Don't record commands starting with space

# Completions
########
# autoload -U compinit
# compinit
########

if type brew &>/dev/null; then
	FPATH=$(brew --prefix)/share/zsh-abbr:$FPATH

	autoload -Uz compinit
	compinit
fi

# Vi Mode Configuration
bindkey -v

# (keybindings) Maintain some emacs-style bindings in vi mode
bindkey '^P' up-line-or-history
bindkey '^N' down-line-or-history
bindkey '^E' end-of-line
bindkey '^A' beginning-of-line
bindkey '^?' backward-delete-char

# Load plugins if available
# Plugin installation path
source "$DOTFILES/utils.sh"

# -----------------------------------------------------------------------------
# Initialize tools if installed
# -----------------------------------------------------------------------------
# (( $+commands[fzf] )) && eval "$( init zsh)" + fzf -> https://junegunn.github.io/fzf/shell-integration/

# setup_zsh() {
#   ensure_dir "$ZDOTDIR"
#   setup_zshenv
#
#   make_link "$DOTFILES/config/zsh/.zshrc" "$ZDOTDIR/.zshrc"
#   make_link "$DOTFILES/config/zsh/.zprofile" "$ZDOTDIR/.zprofile"
#   make_link "$DOTFILES/config/zsh/aliases.zsh" "$ZDOTDIR/aliases.zsh"
#   make_link "$DOTFILES/config/zsh/functions.zsh" "$ZDOTDIR/functions.zsh"
#   make_link "$DOTFILES/config/zsh/fzf.zsh" "$ZDOTDIR/fzf.zsh"
# }

has_command starship && eval "$(starship init zsh)"
has_command atuin && eval "$(atuin init zsh)"
has_command zoxide && eval "$(zoxide init zsh)"
has_command atuin && eval "$(atuin init zsh)"
has_command uv && eval "$(uv generate-shell-completion zsh)"
has_command pyenv && eval "$(pyenv init -)"
has_command zoxide && eval "$(zoxide init zsh)"
has_command direnv && eval "$(direnv hook zsh)"
has_command fnm && eval "$(fnm env --use-on-cd)"
has_command abbr && eval "$(abbr init zsh)"
has_command nvim && export EDITOR="nvim"

# Initialize tools if installed
# (( $+commands[atuin] )) && eval "$(atuin init zsh --disable-up-arrow)"
# (( $+commands[atuin] )) && eval "$(atuin init zsh --disable-ctrl-r)"
# Initialize zsh-abbr if installed

PLUGIN_DIR="$HOMEBREW_PREFIX/share"
# ensure_dir "$PLUGIN_DIR"
plugins=(
    "zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
    "zsh-autosuggestions/zsh-autosuggestions.zsh"
    "zsh-abbr/zsh-abbr.zsh"
)
for plugin in $plugins; do
    plugin_path="$PLUGIN_DIR/$plugin"
    if [[ ! -f "$plugin_path" ]]; then
        echo "no zsh plugin file at $plugin_path... skipping..."
    else
        source "$plugin_path"
    fi
done
# source $(brew --prefix)/share/zsh/site-functions/_todoist_fzf

#################################
# Functions
#################################
# FZF Functions

alias hf=huggingface-cli

# aliases
falias() {
    local aliases
    aliases=$(alias |
        fzf --multi \
            --preview 'git diff --color=always {2}' \
            --header 'Aliases' |
        awk '{print $0}')

    [ -n "$aliases" ] && echo "$aliases"
}

# Homebrew functions
# Interactive brew install
fbin() {
    local packages
    packages=$(brew search |
        fzf --multi \
            --preview 'brew info {}' \
            --header 'Install packages')

    [ -n "$packages" ] && echo "$packages" | xargs brew install
}

# Interactive brew uninstall
fbrm() {
    local packages
    packages=$(brew leaves |
        fzf --multi \
            --preview 'brew info {}' \
            --header 'Remove packages')

    [ -n "$packages" ] && echo "$packages" | xargs brew uninstall
}

# Interactive git checkout file
fgco() {
    local files
    files=$(git ls-files -m |
        fzf --multi \
            --preview 'git diff --color=always {}' \
            --header 'Checkout files')

    [ -n "$files" ] && echo "$files" | xargs git checkout
}
# Process management
fkill() {
    local pid
    pid=$(ps -ef | sed 1d |
        fzf --multi \
            --preview 'echo {}' \
            --header 'Kill processes' |
        awk '{print $2}')

    [ -n "$pid" ] && echo "$pid" | xargs kill -${1:-9}
}

# Docker functions
# Container management
fdocker() {
    local container
    container=$(docker ps --format "{{.Names}}" |
        fzf --preview 'docker stats --no-stream {}' \
            --header 'Select container')

    [ -n "$container" ] && docker exec -it "$container" bash
}

# VSCode projects
fcode() {
    local dir
    dir=$(fd --type d --max-depth 3 --exclude node_modules --exclude .git |
        fzf --preview 'tree -C {} | head -200' \
            --header 'Open in VSCode')

    [ -n "$dir" ] && code "$dir"
}

# Chrome bookmarks search
fbm() {
    local bookmarks_path="$HOME/Library/Application Support/Google/Chrome/Default/Bookmarks"

    if [[ ! -f "$bookmarks_path" ]]; then
        echo "Chrome Bookmarks file not found"
        return 1
    fi

    local jq_script='
        def ancestors: while(. | length >= 2; del(.[-1,-2]));
        . as $root | paths(try .url catch false) as $path | $path | . as $p |
        $root | getpath($p) | {name,url, path: [$p[0:-2] | ancestors as $a | $root | getpath($a) | .name?] | reverse | join("/") } | .path + "/" + .name + "\t" + .url
    '

    local bookmark_url=$(jq -r "$jq_script" <"$bookmarks_path" |
        sed -E 's/\t/│/g' |
        fzf --delimiter='│' \
            --with-nth=1 \
            --preview-window=hidden \
            --header 'Open bookmark' |
        cut -d'│' -f2)

    [ -n "$bookmark_url" ] && open "$bookmark_url"
}

# Advanced git log browser
fglog() {
    local filter
    if [ -n "$1" ]; then
        filter="--author=$1"
    fi
    git log --graph --color=always --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" $filter |
        fzf --ansi --no-sort --reverse --tiebreak=index \
            --preview 'f() { set -- $(echo -- "$@" | grep -o "[a-f0-9]\{7\}"); [ $# -eq 0 ] || git show --color=always $1; }; f {}' \
            --preview-window=right:60% \
            --bind='ctrl-/:toggle-preview' \
            --header='Browse git log' \
            --bind='enter:execute:
            (grep -o "[a-f0-9]\{7\}" | head -1 |
            xargs -I % sh -c "git show --color=always % | less -R") <<< {}'
}

# NPM script runner
fnr() {
    local script
    script=$(cat package.json | jq -r '.scripts | to_entries | .[] | .key' |
        fzf --preview 'cat package.json | jq -r .scripts.{}' \
            --preview-window=right:60% \
            --bind='ctrl-/:toggle-preview' \
            --header='Run npm script')
    if [ -n "$script" ]; then
        echo "Running 'npm run $script'..."
        npm run "$script"
    fi
}

# Enhanced man page viewer
fman() {
    man -k . | fzf --prompt='Man> ' \
        --preview 'echo {} | cut -d" " -f1 | xargs -I% man %' \
        --preview-window=right:70% \
        --bind='ctrl-/:toggle-preview' \
        --header='View man pages' |
        awk '{print $1}' | xargs -r man
}

# # Homebrew cask installer
# fcask() {
#     local token
#     token=$(brew search --casks | fzf --preview 'brew info --cask {}' \
#         --preview-window=right:60% \
#         --bind='ctrl-/:toggle-preview' \
#         --header='Install Homebrew cask')
#     if [ -n "$token" ]; then
#         echo "Installing cask $token..."
#         brew install --cask "$token"
#     fi
# }

# Directory history navigation
fz() {
    local dir
    dir=$(z -l | awk '{print $2}' | fzf --preview 'tree -C {} | head -200' \
        --preview-window=right:60% \
        --bind='ctrl-/:toggle-preview' \
        --header='Jump to directory from history')
    if [ -n "$dir" ]; then
        cd "$dir"
    fi
}

# Environment variable explorer
fenv() {
    local var
    var=$(env | sort | fzf --preview 'echo {}' \
        --preview-window=down:3:wrap \
        --bind='ctrl-/:toggle-preview' \
        --header='Explore environment variables')
    if [ -n "$var" ]; then
        echo "$var" | pbcopy
        echo "Copied to clipboard: $var"
    fi
}

# Port process killer
fport() {
    local port_pid
    port_pid=$(lsof -i -P -n | grep LISTEN |
        fzf --preview 'echo {}' \
            --preview-window=down:3:wrap \
            --bind='ctrl-/:toggle-preview' \
            --header='Kill process on port' |
        awk '{print $2}')
    if [ -n "$port_pid" ]; then
        echo "Killing process $port_pid..."
        kill -9 "$port_pid"
    fi
}

# Kubernetes context switcher
fkctx() {
    local context
    context=$(kubectl config get-contexts --no-headers |
        fzf --preview 'kubectl config get-contexts {}' \
            --preview-window=right:60% \
            --bind='ctrl-/:toggle-preview' \
            --header='Switch Kubernetes context' |
        awk '{print $1}')
    if [ -n "$context" ]; then
        kubectl config use-context "$context"
    fi
}

# Dotfiles editor
fdot() {
    local file
    file=$(fd --type f . "$DOTFILES/config" |
        fzf --preview 'bat --style=numbers --color=always {}' \
            --preview-window=right:60% \
            --bind='ctrl-/:toggle-preview' \
            --header='Edit dotfiles')
    if [ -n "$file" ]; then
        ${EDITOR:-nvim} "$file"
    fi
}

# HTTP status code lookup
fhttp() {
    local code
    code=$(cat "$DOTFILES/config/zsh/data/http_status_codes.txt" |
        fzf --preview 'echo {}' \
            --preview-window=down:3:wrap \
            --bind='ctrl-/:toggle-preview' \
            --header='HTTP status codes')
    if [ -n "$code" ]; then
        echo "$code" | pbcopy
        echo "Copied to clipboard: $code"
    fi
}

# Enhanced file search with rg and preview
frg() {
    local file line
    read -r file line <<<"$(rg --line-number --no-heading --color=always --smart-case "$@" |
        fzf --ansi \
            --color "hl:-1:underline,hl+:-1:underline:reverse" \
            --delimiter : \
            --preview "bat --style=numbers --color=always --highlight-line {2} {1}" \
            --preview-window "right,60%,border-left,+{2}+3/3,~3" \
            --bind='ctrl-/:toggle-preview' \
            --header='Search in files with ripgrep')"
    if [ -n "$file" ]; then
        ${EDITOR:-nvim} "$file" +"$line"
    fi
}

# https://github.com/junegunn/fzf/issues/2789
rfv() {
    # rg
    # --field-match-separator ' ' - tell rg to separate the filename and linenumber with
    # spaces to play well with fzf, (when recognizing index variables to use in the fzf
    # preview command, fzf uses a default delimiter of space, see below)

    # fzf
    # --preview window ~8,+{1}-5
    #   this is a fzf feature
    #   ~8 - show first 8 lines (header)
    #   +{2} - fzf delimits the input piped in to it and provides access via index variables {n}.
    #   the default delimiter fzf uses is space but can be specified via --delimiter <delimiter>
    #   pass the second index variable from bat (which is the line number)
    #   the number is signed, you can show eg the +n row or the -n row (the nth row from the bottom)
    #   -5 subtract 5 rows (go up 5 rows) so that you don't show the highlighted line as the first line
    #   since you want to provide context by showing the rows above the highlighted line

    rg --line-number --with-filename . --color=always --field-match-separator ' ' |
        fzf --preview "bat --color=always {1} --highlight-line {2}" \
            --preview-window ~8,+{2}-5
}

# # Load fzf completion and key bindings
# [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

##################### END

# # Base FZF configuration
# export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
# export FZF_DEFAULT_OPTS="
#     --height 80%
#     --layout=reverse
#     --border sharp
#     --margin=1
#     --padding=1
#     --info=inline
#     --prompt='❯ '
#     --pointer='▶'
#     --marker='✓'
#     --preview-window='right:60%:border-left'
#     --bind='ctrl-/:toggle-preview'
#     --bind='ctrl-y:execute-silent(echo {} | pbcopy)'
#     --bind='ctrl-e:execute(nvim {} < /dev/tty > /dev/tty)'
#     --bind='ctrl-f:preview-page-down'
#     --bind='ctrl-b:preview-page-up'
#     --bind='ctrl-a:select-all'
#     --bind='ctrl-d:deselect-all'
#     --bind='change:first'
#     --color=fg:#c0caf5,bg:#1a1b26,hl:#bb9af7
#     --color=fg+:#c0caf5,bg+:#292e42,hl+:#7dcfff
#     --color=info:#7aa2f7,prompt:#7dcfff,pointer:#7dcfff
#     --color=marker:#9ece6a,spinner:#9ece6a,header:#9ece6a
# "

# # File preview configuration
# export FZF_PREVIEW_COMMAND="bat --style=numbers,changes --color=always --line-range :500 {}"

# # Directory preview
# export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
# export FZF_ALT_C_OPTS="
#     --preview 'tree -C {} | head -200'
#     --bind 'ctrl-/:toggle-preview'
#     --header 'Jump to directory'
# "

# # File search configuration
# export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
# export FZF_CTRL_T_OPTS="
#     --preview '$FZF_PREVIEW_COMMAND'
#     --bind 'ctrl-/:toggle-preview'
#     --header 'Select files'
# "

# # History search configuration
# export FZF_CTRL_R_OPTS="
#     --preview 'echo {}'
#     --preview-window=down:3:wrap
#     --bind 'ctrl-/:toggle-preview'
#     --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'
#     --header 'Search command history'
#     --sort
#     --exact
# "

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
        *) echo "'$1' cannot be extracted" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Git utilities

# Unalias conflicting names (e.g. 'gco') before defining functions
# unalias gco 2>/dev/null

# Enhanced git checkout
gco() {
    if [ $# -eq 0 ]; then
        git branch | fzf | xargs git checkout
    else
        git checkout "$@"
    fi
}

# Git add with fzf
# unalias ga 2>/dev/null
ga() {
    if [ $# -eq 0 ]; then
        git status -s | fzf --multi | awk '{print $2}' | xargs git add
    else
        git add "$@"
    fi
}

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

# Directory bookmarks
bm() {
    local mark_dir="$XDG_DATA_HOME/marks"
    mkdir -p "$mark_dir"
    ln -s "$(pwd)" "$mark_dir/$1"
}

# Enhanced tree command with eza
lstree() {
    eza --tree --level="${1:-2}" --icons
}

# macOS specific
# Show/hide hidden files
togglehidden() {
    local current=$(defaults read com.apple.finder AppleShowAllFiles)
    defaults write com.apple.finder AppleShowAllFiles $((!current))
    killall Finder
}
#
# Quick Look from terminal
ql() {
    qlmanage -p "$@" &>/dev/null
}
#
# Additional utilities will be added as needed...
#
# ###############################
# # fzf examples -> https://github.com/junegunn/fzf/wiki/examples#homebrew
# ###############################
#
#

# Clean .DS_Store files
clean_ds_store() {
    log "Cleaning .DS_Store files..."
    find "$DOTFILES" -name ".DS_Store" -delete
}
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
# Homebrew utilities
function has_brew() {
    command -v brew >/dev/null 2>&1
}

function ensure_brew() {
    if ! has_brew; then
        log_info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Add to PATH for current session if installed
        if is_arm64; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        else
            eval "$(/usr/local/bin/brew shellenv)"
        fi
    fi
}

function update_brew() {
    if has_brew; then
        log_info "Updating Homebrew..."
        brew update
        brew upgrade
        brew cleanup
    fi
}

#################################################################################
# MacOS utils
#################################################################################

# Apply common macOS system preferences
defaults_apply() {
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

# fzf + zoxide integration
function z() {
    local dir
    dir=$(
        zoxide query --list --score |
            fzf --height 40% --layout reverse --info inline \
                --preview 'tree -C {} | head -200' \
                --preview-window='right:60%:border-left' \
                --bind='ctrl-/:toggle-preview' \
                --border-label='Zoxide Directories' \
                --nth 2.. --tac --query "$*"
    ) && cd "$(echo "$dir" | sed 's/^[0-9,.]* *//')"
}

# ripgrep + fzf + neovim integration
function rgv() {
    local file
    local line

    read -r file line <<<"$(rg --no-heading --line-number "$@" |
        fzf --delimiter : \
            --preview 'bat --style=numbers --color=always --highlight-line {2} {1}' \
            --preview-window='right:60%:border-left+{2}+3/3,~3' \
            --bind='ctrl-/:toggle-preview')"

    if [[ -n "$file" ]]; then
        nvim "$file" +"$line"
    fi
}

# Homebrew bundle management
function bb() {
    case "$1" in
    save)
        brew bundle dump --force --describe --file="$HOMEBREW_BUNDLE_FILE"
        ;;
    install)
        brew bundle --file="$HOMEBREW_BUNDLE_FILE"
        ;;
    check)
        brew bundle check --verbose --file="$HOMEBREW_BUNDLE_FILE"
        ;;
    clean)
        brew bundle cleanup --force --file="$HOMEBREW_BUNDLE_FILE"
        ;;
    *)
        echo "Usage: brewfile [save|install|check|clean]"
        ;;
    esac
}

# # Docker shortcuts
# function dex() {
#   docker exec -it "$1" "${2:-bash}"
# }

# function dlog() {
#   docker logs -f "$1"
# }

# # Git utilities
# function gclean() {
#   git branch --merged | grep -v '\*\|master\|main\|develop' | xargs -n 1 git branch -d
# }
#
# # macOS utilities
# function spot() {
#   mdfind "kMDItemDisplayName == '$@'wc"
# }

# # Quick HTTP server
# function serve() {
#   local port="${1:-8000}"
#   python3 -m http.server "$port"
# }
#

# ====== Yazi File Manager Configuration ======
function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}

#-----------------------------------------------------
# Custom functions (example)
#-----------------------------------------------------

function slink() {
    local src_orig=$1
    local dst_link=$2
    local dst_dir=$(dirname "$dst_link")

    # Create the directory if it does not exist
    mkdir -p "$dst_dir"

    # Create the symlink
    ln -sf "$src_orig" "$dst_link"
}

# Base FZF configuration
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS="
    --height 80%
    --multi
    --layout=reverse
    --border sharp
    --margin=1
    --padding=1
    --info=inline
    --prompt='❯ '
    --pointer='▶'
    --marker='✓'
    --preview-window='right:60%:border-left'
    --bind='ctrl-/:toggle-preview'
    --bind='ctrl-y:execute-silent(echo {} | pbcopy)'
    --bind='ctrl-e:execute(nvim {} < /dev/tty > /dev/tty)'
    --bind='ctrl-f:preview-page-down'
    --bind='ctrl-b:preview-page-up'
    --bind='ctrl-a:select-all'
    --bind='ctrl-d:deselect-all'
    --bind='change:first'
    --color=fg:#c0caf5,bg:#1a1b26,hl:#bb9af7
    --color=fg+:#c0caf5,bg+:#292e42,hl+:#7dcfff
    --color=info:#7aa2f7,prompt:#7dcfff,pointer:#7dcfff
    --color=marker:#9ece6a,spinner:#9ece6a,header:#9ece6a
"

# File preview configuration
export FZF_PREVIEW_COMMAND="bat --style=numbers,changes --color=always --line-range :500 {}"

# Directory preview
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
export FZF_ALT_C_OPTS="
    --preview 'tree -C {} | head -200'
    --bind 'ctrl-/:toggle-preview'
    --header 'Jump to directory'
"

# File search configuration
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="
    --preview '$FZF_PREVIEW_COMMAND'
    --bind 'ctrl-/:toggle-preview'
    --header 'Select files'
"

# History search configuration
export FZF_CTRL_R_OPTS="
    --preview 'echo {}'
    --preview-window=down:3:wrap
    --bind 'ctrl-/:toggle-preview'
    --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'
    --header 'Search command history'
    --sort
    --exact
"

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
