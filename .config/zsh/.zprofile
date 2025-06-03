# ========================================================================
# ZSH Profile (.zprofile)
# ========================================================================
# Executed at login (after .zshenv) - for PATH and environment setup

# Homebrew Setup
if [[ -x "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x "/usr/local/bin/brew" ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

# Editor and Pager
export EDITOR="nvim"
export VISUAL="$EDITOR"
export PAGER="bat --paging=always"

# Clean PATH management using zsh arrays
typeset -U path  # Ensure unique entries
path=(
    # User paths (highest priority)
    "$HOME/.local/bin"
    "$HOME/dotfiles/bin"
    
    # Language/tool paths
    "$HOME/.cargo/bin"
    "$HOME/go/bin"
    "$VOLTA_HOME/bin"
    
    # Homebrew Ruby (if installed)
    "/opt/homebrew/opt/ruby/bin"
    
    # System paths (already added, but included for completeness)
    $path
)

# Additional tool initialization
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
[[ -f "$HOME/.orbstack/shell/init.zsh" ]] && source "$HOME/.orbstack/shell/init.zsh" 2>/dev/null