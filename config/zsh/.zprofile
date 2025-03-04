# -----------------------------------------------------------------------------
# ~/.zprofile (Invoked once at login on macOS)
#
# mac.install.guide tips (https://mac.install.guide/terminal/zshrc-zprofile)
# - Use ~/.zprofile to set the PATH and EDITOR environment variables.
# -----------------------------------------------------------------------------

# Environment variables that should be set for all shells
# XDG Base Directory specification
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export ZDOTDIR=${ZDOTDIR:-$XDG_CONFIG_HOME/zsh}

# Dotfiles location
export DOTFILES="${DOTFILES:-$HOME/dotfiles}"

# Editor
export EDITOR="nvim"
export VISUAL="$EDITOR"
export PAGER="less -FRX"

# macOS specific
export HOMEBREW_NO_ANALYTICS=1         # Disable Homebrew analytics
export HOMEBREW_NO_INSTALL_CLEANUP=1   # Don't clean up after install
export HOMEBREW_BUNDLE_NO_LOCK=1       # Don't create Brewfile.lock.json
export HOMEBREW_AUTOREMOVE=1           # Auto remove unused dependencies
export HOMEBREW_CASK_OPTS="--no-quarantine"  # Disable macOS quarantine for casks

# Application directories for macOS
export APPLICATIONS="/Applications"
export USER_APPLICATIONS="$HOME/Applications"

# If you need to have rustup first in your PATH, run:
#   echo 'export PATH="/opt/homebrew/opt/rustup/bin:$PATH"' >> /Users/hank/dotfiles/config/zsh/.zshrc
#
# zsh completions have been installed to:
#   /opt/homebrew/opt/rustup/share/zsh/site-functions

# docs
# - https://wiki.archlinux.org/title/Zsh#Configuration_files
# - https://gist.github.com/Linerre/f11ad4a6a934dcf01ee8415c9457e7b2

# PATH configuration for Apple Silicon
# Homebrew setup for Apple Silicon
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# Remove duplicate paths
typeset -U path PATH
path=(
  "$HOME/.local/bin"
  "$HOME/bin"
  "$HOMEBREW_PREFIX/opt/llvm/bin"
  "$HOMEBREW_PREFIX/opt/ruby/bin"
  "$HOMEBREW_PREFIX/opt/python/libexec/bin"
  "$HOMEBREW_PREFIX/opt/node/bin"
  "$HOMEBREW_PREFIX/opt/sqlite/bin"
  "$HOMEBREW_PREFIX/opt/openssl/bin"
  "$HOMEBREW_PREFIX/opt/curl/bin"
  "$HOME/.cargo/bin"                   # Rust
  "$HOME/.deno/bin"                    # Deno
  "$HOME/.bun/bin"                     # Bun
  "$HOME/go/bin"                       # Go
  $path
)

# Rust
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# Go
export GOPATH="$HOME/go"
export GOBIN="$GOPATH/bin"

# Python
export PYTHONSTARTUP="$XDG_CONFIG_HOME/python/pythonrc"
export PYTHONDONTWRITEBYTECODE=1       # Don't create .pyc files
[[ -d "$HOME/.pyenv" ]] && {
  export PYENV_ROOT="$HOME/.pyenv"
  path=("$PYENV_ROOT/bin" $path)
  eval "$(pyenv init --path)"
}

# Node.js
export NODE_REPL_HISTORY="$XDG_STATE_HOME/node_history"
export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/npmrc"

# Java
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"

# Less (used by man)
export LESS="-FRX"            # Quit if one screen, preserve colors, don't clear screen
export LESS_TERMCAP_md=$'\E[01;31m'    # Bold mode - Red
export LESS_TERMCAP_me=$'\E[0m'        # End
export LESS_TERMCAP_us=$'\E[01;32m'    # Underline - Green
export LESS_TERMCAP_ue=$'\E[0m'        # End
export LESS_TERMCAP_so=$'\E[01;44;33m' # Standout mode - Yellow on Blue
export LESS_TERMCAP_se=$'\E[0m'        # End
export LESS_TERMCAP_mb=$'\E[01;33m'    # Blink - Yellow
export LESSHISTFILE="-"                # Disable Less history file

# Terminal
export COLORTERM=truecolor
export TERM_PROGRAM="${TERM_PROGRAM:-Apple_Terminal}"
