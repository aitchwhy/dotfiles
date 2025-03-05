# -----------------------------------------------------------------------------
# ~/.zprofile (Invoked once at login on macOS)
#
# mac.install.guide tips (https://mac.install.guide/terminal/zshrc-zprofile)
# - Use ~/.zprofile to set the PATH and EDITOR environment variables.
# -----------------------------------------------------------------------------
# Application directories for macOS
# export APPLICATIONS="/Applications"
# export USER_APPLICATIONS="$HOME/Applications"

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
  "$VOLTA_HOME/bin"
  "$HOME/.cargo/bin" # Rust
  # "$HOME/.deno/bin"  # Deno
  # "$HOME/.bun/bin" # Bun
  "$HOME/go/bin" # Go
  # "$HOME/.local/bin"
  # "$HOME/bin"
  # "$HOMEBREW_PREFIX/opt/llvm/bin"
  # "$HOMEBREW_PREFIX/opt/ruby/bin"
  # "$HOMEBREW_PREFIX/opt/python/libexec/bin"
  # "$HOMEBREW_PREFIX/opt/node/bin"
  # "$HOMEBREW_PREFIX/opt/sqlite/bin"
  # "$HOMEBREW_PREFIX/opt/openssl/bin"
  # "$HOMEBREW_PREFIX/opt/curl/bin"
  $path
)

# Rust
# TODO: may not need this if adding rustup to PATH directly
# [[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
