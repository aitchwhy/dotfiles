# ========================================================================
# ZSH Configuration (.zshrc)
# ========================================================================
# Main configuration for interactive shells - consolidated and minimal

# Performance monitoring (uncomment to debug)
# zmodload zsh/zprof

# ========================================================================
# Shell Options
# ========================================================================
setopt AUTO_PUSHD        # Push directory to stack on cd
setopt PUSHD_IGNORE_DUPS # Don't store duplicates in dir stack
setopt PUSHD_SILENT      # Don't print stack after pushd/popd
setopt NO_CASE_GLOB      # Case insensitive globbing

# ┌─────────┬──────────────────────────────────────────────────────────────────────────────┐
# │  bash   │ Comments always active. .#foo is not a comment (since # is inside token).    │
# │  zsh    │ Comments off unless setopt interactive_comments is set.                      │
# │         │ If on, first # starts a comment; e.g., nix run . # rest is ignored.          │
# └─────────┴──────────────────────────────────────────────────────────────────────────────┘
setopt INTERACTIVE_COMMENTS # Allow comments in interactive shells
setopt NO_NOMATCH           # Don't error on no glob matches
setopt EXTENDEDGLOB         # extended glob (e.g. '*')

# History Configuration
setopt SHARE_HISTORY     # Share history between sessions
setopt HIST_IGNORE_DUPS  # Don't record duplicates
setopt HIST_IGNORE_SPACE # Ignore commands starting with space
setopt HIST_VERIFY       # Don't execute immediately on history expansion
setopt EXTENDED_HISTORY  # Record timestamp

# Nix environment (if installed)
if [[ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]]; then
    source '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
fi

# ========================================================================
# Environment Variables
# ========================================================================
export COLORTERM="truecolor"

export HISTFILE="$HOME/.zsh_history"
export HISTSIZE=100000
export SAVEHIST=$HISTSIZE

# Shortcuts
export CFS="$DOTFILES/.config"
export CFSZSH="$CFS/zsh"
export CMD="$DOTFILES/scripts"
export OBS="$HOME/obsidian/primary"


# Essential environment variables
export DOTFILES="$HOME/dotfiles"
export CFS="$DOTFILES/.config"
export ZDOTDIR="$DOTFILES/zsh"
# export XDG_CONFIG_HOME="$DOTFILES/.config"
# export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
# export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
# export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
# XDG directories
# # Create XDG directories if they don't exist
# for dir in "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME"; do
#     [[ ! -d "$dir" ]] && mkdir -p "$dir"
# done


# Set Homebrew bundle file to custom location in dotfiles repo dir
export HOMEBREW_BUNDLE_FILE="$CFS/brew/Brewfile"
export HOMEBREW_NO_ANALYTICS=1




# Volta (Node.js version manager)
# export VOLTA_HOME="$HOME/.volta"
# export PATH="$VOLTA_HOME/bin:$PATH"

. "$HOME/.cargo/env"

# Tool configurations
export BAT_THEME="OneHalfDark"
export DELTA_PAGER="bat --plain --paging=never"
export FZF_DEFAULT_OPTS='--height 40% --border --cycle --layout=reverse --marker="✓" --bind=ctrl-j:down,ctrl-k:up'
export STARSHIP_CONFIG="$CFS/starship/starship.toml"
# export GIT_CONFIG_GLOBAL="$CFS/git/.config"
export LG_CONFIG_FILE="$CFS/git/lazygit.yml"

export ATUIN_CONFIG_DIR="$CFS/atuin"
export YAZI_CONFIG_DIR="$CFS/yazi"
export ZELLIJ_CONFIG_DIR="$CFS/zellij"

export DYLD_FALLBACK_LIBRARY_PATH=/opt/homebrew/lib:$DYLD_FALLBACK_LIBRARY_PATH

# NPM configuration - using standard ~/.npmrc (symlinked from dotfiles)
# export NPM_CONFIG_USERCONFIG="$CFS/npm/.npm-global"  # No longer needed

# Add a directory to PATH if it exists and isn't already in PATH
function path_add() {
    local dir=$1
    if [[ -d "$dir" ]] && [[ ":$PATH:" != *":$dir:"* ]]; then
        export PATH="$dir:$PATH"
        return 0
    fi
    return 1
}

export GLOBAL_JUSTFILE="$DOTFILES/justfile"
export LDFLAGS="-L/opt/homebrew/opt/ruby/lib"
export CPPFLAGS="-I/opt/homebrew/opt/ruby/include"

path_add /opt/homebrew/opt/ruby/bin

# path_add "$CFS/npm-global/bin" # Add npm global packages to PATH
# path_add "$HOME/.volta/bin" # Add npm global packages to PATH
alias cs="claude-squad"
alias pc="process-compose"

# ========================================================================
# Completions
# ========================================================================
# Add Homebrew completions
if [[ -n "$HOMEBREW_PREFIX" ]]; then
    FPATH="$HOMEBREW_PREFIX/share/zsh/site-functions:$FPATH"
fi

# Add Nix completions if available
if [[ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]]; then
    fpath+=(/nix/var/nix/profiles/default/share/zsh/site-functions)
fi

# Add custom completions
fpath=("$CFS/zsh/.zfunc" $fpath)

for x in ; do
    [[ ! -d "$dir" ]] && mkdir -p "$dir"
done


# Initialize completion system
autoload -Uz compinit && compinit

# ========================================================================
# Key Bindings
# ========================================================================
bindkey -v
export KEYTIMEOUT=1

# ========================================================================
# Plugins (from Homebrew)
# ========================================================================
if [[ -d "$HOMEBREW_PREFIX/share" ]]; then
    # Load all available zsh plugins from Homebrew
    for plugin_dir in "$HOMEBREW_PREFIX/share"/zsh-*; do
        if [[ -d "$plugin_dir" ]]; then
            plugin_name=$(basename "$plugin_dir")
            plugin_script="$plugin_dir/$plugin_name.zsh"
            [[ -f "$plugin_script" ]] && source "$plugin_script"
        fi
    done
fi
# ========================================================================
# Core Functions
# ========================================================================

# Check if command exists
has_command() {
    command -v "$1" &>/dev/null
}

# Add to PATH if not already present
path_add() {
    [[ -d "$1" && ":$PATH:" != *":$1:"* ]] && export PATH="$PATH:$1"
}

# ========================================================================
# Aliases - File System
# ========================================================================
alias ls='eza --git --icons'
alias l='eza --git --icons -lF'
alias ll='eza -lahF --git'
alias lll="eza -1F --git --icons"
# alias llm='ll --sort=modified'
alias la='eza -lbhHigUmuSa --color-scale --git --icons'
alias lx='eza -lbhHigUmuSa@ --color-scale --git --icons'
alias lt='eza --tree --level=2'
alias llt='eza -lahF --tree --level=2'
alias ltt='eza -lahF | grep "$(date +"%d %b")"'

# ========================================================================
# Aliases - Navigation
# ========================================================================
# alias ..='cd ..'
# alias ...='cd ../..'
# alias ....='cd ../../..'

# ========================================================================
# Aliases - Editors
# ========================================================================
alias v='$EDITOR'
alias vi='$EDITOR'
alias vim='$EDITOR'

# ========================================================================
# Aliases - Zsh
# ========================================================================
alias zr="exec zsh"
alias ze="$EDITOR $ZDOTDIR/.zshrc"
alias zeall="$EDITOR $ZDOTDIR/{.zshrc,.zprofile,.zshenv}"
alias zcompreset="rm -f ~/.zcompdump; compinit"

alias br="exec bash"
alias be="$EDITOR ~/.bashrc ~/.bash_profeil"
alias beall="$EDITOR $ZDOTDIR/{.bashrc,.bash_profile,.profile}"


# ========================================================================
# Aliases - Git
# ========================================================================
alias g='git'
alias ga='git add'
alias gaa='git add --all'
alias gai='git add -i'
alias gc='git commit'
alias gca='git commit --amend --no-edit'
alias gcm='git commit -m'
alias gll='git pull'
alias gp='git push'
alias gs='git status'
alias lgdot='lazygit --path $DOTFILES'
alias lg='lazygit'
alias gw='git worktree'

# ========================================================================
# Aliases - Modern CLI Tools
# ========================================================================
alias cat='bat --paging=never'
alias grep='rg'
alias find='fd'
alias ps='procs'
alias diff='delta'
alias ping='gping'
alias du='dust'
alias sed='sd'
alias md='glow'
alias ch='cheat'

# ========================================================================
# Aliases - Homebrew
# ========================================================================
alias b='brew'
alias bup='brew update && brew upgrade'
alias bclean='brew cleanup --prune=all && rm -rf $(brew --cache) && brew autoremove'
alias bi='brew info'
alias bin='brew install'
alias brein='brew reinstall'
alias bs='brew search'

# ========================================================================
# Aliases - Docker
# ========================================================================
alias d='docker'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias dimg='docker images'
alias dx='docker exec -it'
alias dc='docker-compose'
alias ld='lazydocker'
alias k='k9s'

# ========================================================================
# Aliases - Just
# ========================================================================
alias j='just'
alias .j="just --justfile $GLOBAL_JUSTFILE"

# ========================================================================
# Aliases - System
# ========================================================================
alias ports='lsof -i -P -n | grep LISTEN'
alias printpath='echo $PATH | tr ":" "\n"'
alias ip='ipconfig getifaddr en0'
alias publicip='curl -s https://api.ipify.org'
alias flush='dscacheutil -flushcache && killall -HUP mDNSResponder'

# ========================================================================
# Aliases - Terminal Multiplexers
# ========================================================================
alias zj='zellij'
alias zjls='zellij list-sessions'
alias zja='zellij attach "$(zellij list-sessions -n | fzf --reverse --border --no-sort --height 40% | awk '\''{print $1}'\'')"'

# ========================================================================
# Aliases - Other Tools
# ========================================================================
alias tm='task-master'
# alias claude='/Users/hank/.claude/local/claude'

alias sp='supabase'
alias ts='tailscale'
alias hf='huggingface-cli'
alias rx='repomix'
alias at='atuin'
alias aero='aerospace'
alias pc='process-compose'
alias envx='dotenvx'

alias ycwd='yazi --cwd-file'

# ========================================================================
# Aliases - Nix
# ========================================================================

# alias nz='nix develop --command zsh'
function nz() {
    nix develop ".#$1" --command zsh
}
alias nd='nix develop'
alias npkgs='nix search'
alias nst='nix store'
alias nf='nix flake'
alias nfc='nix flake check -L'
alias nb='nix build'
alias ncf='nix config'
alias nr='nix run'
alias nfmt='nix fmt'
alias np='nix profile'

# ========================================================================
# Functions - Directory Navigation
# ========================================================================

# # Edit directories
# () {
#     local DIRPATH="$1"
#     nvim $(fd . -t d --exact-depth 1 --color never $DIRPATH | fzf --prompt="${DIRPATH} configs>" --preview='gls -s {}')
# }

xdg() {
    fdirs $XDG_CONFIG_HOME
}

cfs() {
    fdirs $CFS
}

# ========================================================================
# Functions - Yazi File Manager
# ========================================================================
y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}

# source "$DOTS/scripts/ant.zsh"

# ========================================================================
# Functions - File Operations
# ========================================================================
ff() {
    local cmd result
    local fd_options="--type f --follow --hidden --exclude .git"
    case "$1" in
    find | file)
        result=$(fd $fd_options | fzf --preview="bat --color=always {}")
        echo "$result"
        ;;
    edit)
        result=$(fd $fd_options | fzf --preview="bat --color=always {}")
        [[ -n "$result" ]] && "$EDITOR" "$result"
        ;;
    dir)
        yazi --cwd $(fd $fd_options | fzf --preview="eza --tree --level=1 --color=always {}")
        ;;
    cd)
        result=$(fd $fd_options | fzf --preview="eza --tree --level=1 --color=always {}")
        [[ -n "$result" ]] && cd "$result"
        ;;
    cd)
        echo $(fd --hidden -t f . $ZDOTDIR)
        ;;
    *)
        echo "Usage: f {find|file|edit|dir|cd}"
        ;;
    esac
}

# ========================================================================
# Tool Initialization
# ========================================================================

# Starship prompt
has_command starship && eval "$(starship init zsh)"
has_command zoxide && eval "$(zoxide init zsh)"

has_command luarocks && eval "$(luarocks path --bin)"
has_command direnv && eval "$(direnv hook zsh)"

# Atuin (history management)
# [[ -f "$HOME/.atuin/bin/env" ]] && source "$HOME/.atuin/bin/env"
has_command atuin && eval "$(atuin init zsh)"




# Load utility functions if available
[[ -f "$ZDOTDIR/utils.zsh" ]] && source "$ZDOTDIR/utils.zsh"

# Load local/private configuration if exists
# [[ -f "$ZDOTDIR/.zshrc.local" ]] && source "$ZDOTDIR/.zshrc.local"

# Load local/private configuration if exists
# [[ -f "$DOTS/scripts/functions.zsh" ]] && source "$DOTS/scripts/functions.zsh"

# for f in $(lsz); do
#   echo $(fd --hidden -t f . $ZDOTDIR)
#
#     [ -f "$f" ] && cp "$src/$f" "$dest/"
# done

alias flopilot="cd ~/src/vibes/apps/flopilot && npm i && ./deploy-local.sh && cd -"

function cp_repo() {
  local FROM_DIR="$1"
  [[ ! -d ~/src/ant ]] && mkdir -p ~/src/ant
  rsync -av \
    --recursive \
    --exclude=".git*" \
    --exclude=".github" \
    --exclude="node_modules" \
    --exclude=".venv" \
    --exclude=".gitignore" \
    --exclude=".pytest_cache" \
    --exclude=".obsidian" \
    --exclude=".ruff_cache" \
    --exclude=".venv" \
    --exclude=".DS*" \
    --progress \
    "$FROM_DIR" ~/src/ant/"$(basename "$FROM_DIR")"
}

function generate_ssh() {
    echo "Generating new SSH key..."
    ssh-keygen -t ed25519 -C "$1" -f ~/.ssh/id_ed25519_new

    echo -e "\n=== Copy these to Bitwarden ===\n"
    echo "PRIVATE KEY:"
    cat ~/.ssh/id_ed25519_new
    echo -e "\nPUBLIC KEY:"
    cat ~/.ssh/id_ed25519_new.pub
}

function cp_repos() {
  local selected_dirs

  # Let fzf handle terminal directly
  selected_dirs=$(fd . ~/src --max-depth 1 --min-depth 1 --type d | fzf --multi --prompt="Select directories to copy: " --height=80% --layout=reverse --preview 'ls -la {}' --preview-window=right:50%)

  [[ -z "$selected_dirs" ]] && echo "No directories selected." && return 1

  # Process each line
  while IFS= read -r dir; do
    echo "Copying $(basename "$dir")..."
    cp_repo "$dir"
  done <<< "$selected_dirs"

  for d in $selected_dirs; do
    echo "--- cp_repo $d"
    cp_repo $d
  done

  echo "✓ Done copying."
}
#############################

function ant-npm-strict-install() {
    npm install --strict-peer-deps true --prefer-dedupe true
}

function clean-node() {
    fd --hidden --no-ignore .venv | xargs -I _ rm -rf _
}

function clean-python() {
    fd --hidden --no-ignore .venv | xargs -I _ rm -rf _
    fd --hidden --no-ignore .pytest_cache | xargs -I _ rm -rf _
    fd --hidden --no-ignore .ruff_cache | xargs -I _ rm -rf _
}



#############################



# ========================================================================
# Cleanup
# ========================================================================
# Performance monitoring (uncomment to debug)
# zprof
#
#

alias claude="/Users/hank/dotfiles/.config/claude/local/claude"
