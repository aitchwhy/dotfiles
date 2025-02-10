############################
# Consolidated Zsh configuration for interactive shells
# Organized for performance and clarity
############################

# source "$HOME/dotfiles/scripts/utils.sh"


# # Helper functions
# _load_if_exists() 
#     local cmd="$1"
#     local setup_cmd="$2"
#
#     if command -v "$cmd" > /dev/null; then
#         eval "$setup_cmd"
#     fi
# }
#
# _load_config_if_exists() {
#     local config="$1"
#     [[ -f "$config" ]] && source "$config"
# }

# ============================================================================ #
# .zshenv
# ============================================================================ #

# ====== Environment Variables ======
# XDG Base Directory Specification
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

# Ensure directories exist
mkdir -p "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME/zsh"

# Tool configurations
export LANG=en_US.UTF-8
export EDITOR="nvim"
export VISUAL="nvim"

export STARSHIP_CONFIG="$XDG_CONFIG_HOME/starship/starship.toml"
export ATUIN_CONFIG_DIR="$XDG_CONFIG_HOME/atuin"
export ZELLIJ_CONFIG_DIR="$XDG_CONFIG_HOME/zellij"
# export VOLTA_HOME="$HOME/.volta"

export BAT_CONFIG_PATH="$XDG_CONFIG_HOME/bat/config"
export RIPGREP_CONFIG_PATH="$XDG_CONFIG_HOME/ripgrep/config"
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border"

# Zoxide configuration
export _ZO_DATA_DIR="${XDG_DATA_HOME}/zoxide"


# Enable TF metal acceleration
export METAL_DEVICE_WRAPPER_TYPE=1
export TF_ENABLE_METAL=1

# History configuration
export HISTFILE="$XDG_STATE_HOME/zsh/history"
export HISTSIZE=10000
export SAVEHIST=10000

# # Runs in all sessions
# export CARGO_HOME="$HOME/.cargo"
# export CLICOLOR=1
# export GOPATH="$HOME/go"
# if [[ -d "$CARGO_HOME" ]]; then
#     source "$HOME/.cargo/env"
# fi

# ============================================================================ #
# .zprofile
# ============================================================================ #

# ====== Path Configuration ======
# Initialize Homebrew (this also sets up PATH)
if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi
# Use /opt/homebrew if on Apple Silicon
# export HOMEBREW_PREFIX="/opt/homebrew"
# export PATH="$HOMEBREW_PREFIX/bin:$PATH"

# Additional PATH entries (only add if they exist and aren't already in PATH)
typeset -U path  # Ensure unique entries
local additional_paths=(
    "$HOME/.local/bin"
    # "/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
    "$CARGO_HOME/bin"
    "$GOPATH/bin"
    "$PYENV_ROOT/bin"
)

for p in $additional_paths; do
    if [[ -d "$p" ]] && [[ ":$PATH:" != *":$p:"* ]]; then
        path+=("$p")
    fi
done


# ============================================================================ #
# .zshrc
# ============================================================================ #

# ====== Shell Options ======
setopt AUTO_CD              # Change directory without cd
setopt EXTENDED_GLOB        # Extended globbing
setopt NOTIFY              # Report status of background jobs immediately
setopt PROMPT_SUBST        # Enable parameter expansion in prompts
setopt INTERACTIVE_COMMENTS # Allow comments in interactive shells
setopt HIST_IGNORE_DUPS    # Don't record duplicated entries in history
setopt HIST_REDUCE_BLANKS  # Remove unnecessary blanks from history
setopt HIST_VERIFY         # Don't execute immediately upon history expansion

# ====== Vi Mode Configuration ======
bindkey -v
export KEYTIMEOUT=1

# Maintain some emacs-style bindings in vi mode
bindkey '^P' up-line-or-history
bindkey '^N' down-line-or-history
bindkey '^E' end-of-line
bindkey '^A' beginning-of-line
bindkey '^?' backward-delete-char

# ====== Completion System ======

# https://docs.brew.sh/Shell-Completion#configuring-completions-in-zsh
# Initialize completions for Homebrew and installed packages
# if type brew &>/dev/null; then
#     FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
#
#     # Load brew-installed completions
#     local completion_file
#     for completion_file in "$(brew --prefix)/share/zsh/site-functions"/_*; do
#         if [[ -f "$completion_file" ]]; then
#             source "$completion_file"
#         fi
#     done
# fi

# Load completion system
autoload -Uz compinit
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
    compinit
else
    compinit -C
fi


# ====== Plugin Loading ======
# Function to load brew-installed plugins
_load_brew_plugin() {
    local plugin_name="$1"
    local plugin_path="$(brew --prefix)/share/zsh-${plugin_name}/${plugin_name}.zsh"
    [[ -f "$plugin_path" ]] && source "$plugin_path"
}

# Load essential plugins
_load_brew_plugin "syntax-highlighting"
_load_brew_plugin "autosuggestions"

# ====== Tool Initialization ======
# Initialize starship prompt if installed
(( $+commands[starship] )) && eval "$(starship init zsh)"

# Initialize atuin if installed (with up arrow disabled due to vi mode)
(( $+commands[atuin] )) && eval "$(atuin init zsh --disable-up-arrow)"

# Initialize zsh-abbr if installed
(( $+commands[abbr] )) && eval "$(abbr init zsh)"

(( $+commands[zoxide] )) && eval "$(zoxide init zsh)"


# Initialize zellij if installed and not already in a session
# if (( $+commands[zellij] )) && [[ -z "$ZELLIJ" ]]; then
#     eval "$(zellij setup --generate-auto-start zsh)"
# fi

# pyenv
# (( $+commands[pyenv] )) && eval "$(pyenv init -)"

# fnm
(( $+commands[fnm] )) && eval "$(fnm env --use-on-cd)"

# uv

# # Python (pyenv)
# if command -v pyenv >/dev/null; then
#     eval "$(pyenv init -)"
# fi

# # Node.js (fnm)
# if command -v fnm >/dev/null; then
#     eval "$(fnm env --use-on-cd)"
# fi


# ====== Yazi File Manager Configuration ======
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}


# ====== Aliases ======
# Modern replacements


# # Navigation
# alias ..='cd ..'
# alias ...='cd ../..'
# alias ....='cd ../../..'
# alias -- -='cd -'

# Aliases
# Modern CLI tool alternatives
if command -v eza >/dev/null; then
    alias ls='eza --icons --group-directories-first'
    alias ll='eza -l --git --icons --group-directories-first'
    alias la='eza -la --git --icons --group-directories-first'
    alias lt='eza --tree --icons --group-directories-first'
fi


# Editor
alias v='$EDITOR'
alias vi='$EDITOR'
alias vim='$EDITOR'
alias ls="ls --color=auto"
alias ll="ls -la"
alias cat="bat"

command -v bat >/dev/null && alias cat='bat --paging=never'
command -v rg >/dev/null && alias grep='rg'
command -v fd >/dev/null && alias find='fd'
command -v lazygit >/dev/null && alias lg='lazygit'


# Git shortcuts
alias g="git"
alias ga="git add"
alias gc="git commit"
alias gp="git push"
alias gs="git status"
alias gp='git push'
alias gl='git pull'

# Example: flush DNS
alias flushdns="sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder"
alias showhidden="defaults write com.apple.finder AppleShowAllFiles YES; killall Finder"


# Package management
alias brewup='brew update && brew upgrade && brew cleanup'

# Load Custom Functions
# [[ -f "${ZDOTDIR}/functions.zsh" ]] && source "${ZDOTDIR}/functions.zsh"

# ====== Local Configuration ======
# Source local customizations if they exist
# [[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
# [[ -f "$ZDOTDIR/local.zsh" ]] && source "$ZDOTDIR/local.zsh"

