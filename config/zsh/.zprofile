# -----------------------------------------------------------------------------
# ~/.zprofile (Invoked once at login on macOS)
#
# mac.install.guide tips (https://mac.install.guide/terminal/zshrc-zprofile)
# - Use ~/.zprofile to set the PATH and EDITOR environment variables.
# -----------------------------------------------------------------------------

# ~/.dotfiles/config/zsh/.zprofile
# Executed at login - useful for setting environment that requires X11

# Ensure XDG directories exist
mkdir -p "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME"

# Initialize Homebrew (in .zprofile, not .zshrc)
if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

# Ruby environment if installed
if [[ -d "/opt/homebrew/opt/ruby/bin" ]]; then
    export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
    if [[ -n "$(command -v gem)" ]]; then
        export PATH="$(gem environment gemdir)/bin:$PATH"
    fi
fi

# Python - prefer user packages
export PIP_USER=1

# Rust
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# Additional path setup for login
path=(
  "$HOMEBREW_PREFIX/opt/coreutils/libexec/gnubin"
  "$HOMEBREW_PREFIX/opt/findutils/libexec/gnubin"
  "$HOMEBREW_PREFIX/opt/gnu-sed/libexec/gnubin"
  "$HOMEBREW_PREFIX/opt/grep/libexec/gnubin"
  $path
)

# Remove duplicate paths
typeset -U path
export PATH




######
#
#
#
# # XDG Base Directory Specification
# export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
# export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
# export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
# export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
#
# # editor
# export ZDOTDIR="${ZDOTDIR:-$XDG_CONFIG_HOME/zsh}"
# export EDITOR="vim"
# export VISUAL="$EDITOR"
#
# # History configuration
# export HISTFILE="$HOME/.zsh_history"
# export HISTSIZE=1000000
# export SAVEHIST=1000000
#
# # Core paths
# export DOTFILES="$HOME/dotfiles"
#
# # Go configuration
# export GOPATH="$HOME/go"
# export GOBIN="$GOPATH/bin"
#
# export _ZO_DATA_DIR="$XDG_DATA_HOME/zoxide"
# export VOLTA_HOME="$HOME/.volta"
#
# # Ensure critical directories exist
# mkdir -p "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME"
#
#
#
# # Ensure path arrays do not contain duplicates
# # - 2.5.11 "Path" section at (https://zsh.sourceforge.io/Guide/zshguide02.html#l6)
# # - https://mac.install.guide/terminal/path
# # - https://tech.serhatteker.com/post/2019-11/how-to-add-path-uniquely-to-path/
# typeset -U path
# path=(
#     $HOME/.local/bin
#     $HOME/bin
#     $VOLTA_HOME/bin
#     $PATH
# )
# export PATH
#
#
# #########
#
# # Ruby environment if installed
# if [[ -d "/opt/homebrew/opt/ruby/bin" ]]; then
#     export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
#     if [[ -n "$(command -v gem)" ]]; then
#         export PATH="$(gem environment gemdir)/bin:$PATH"
#     fi
# fi
#
# # Python - prefer user packages
# export PIP_USER=1
#
# # Rust
# [[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
#
# # Additional path setup for login
# path=(
#   "$HOMEBREW_PREFIX/opt/coreutils/libexec/gnubin"
#   "$HOMEBREW_PREFIX/opt/findutils/libexec/gnubin"
#   "$HOMEBREW_PREFIX/opt/gnu-sed/libexec/gnubin"
#   "$HOMEBREW_PREFIX/opt/grep/libexec/gnubin"
#   $path
# )
#
# # Remove duplicate paths
# typeset -U path
# export PATH
#
