# ========================================================================
# ZSH Profile (.zprofile)
# ========================================================================
# Executed at login (after .zshenv)
# Used primarily for setting PATH and environment variables
# References:
# - https://wiki.archlinux.org/title/Zsh#Configuration_files
# - https://gist.github.com/Linerre/f11ad4a6a934dcf01ee8415c9457e7b2
# - https://mac.install.guide/terminal/zshrc-zprofile

# ========================================================================
# Homebrew Setup
# ========================================================================

# Setup Homebrew for the current architecture
if [[ -x /opt/homebrew/bin/brew ]]; then
  # Apple Silicon path
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  # Intel Mac path
  eval "$(/usr/local/bin/brew shellenv)"
fi

# ========================================================================
# Path Configuration
# ========================================================================

# Remove duplicate entries from PATH
typeset -U path PATH

# Add prioritized paths
path=(
  # Language-specific paths
  "$VOLTA_HOME/bin"  # Node.js via Volta
  "$HOME/.cargo/bin" # Rust
  "$HOME/go/bin"     # Go

  # Uncomment paths as needed
  # "$HOME/.deno/bin"         # Deno
  # "$HOME/.bun/bin"          # Bun
  "$HOME/.local/bin" # User local binaries
  "$HOME/bin"        # User personal binaries

  # Homebrew-managed packages (uncomment as needed)
  # "$HOMEBREW_PREFIX/opt/llvm/bin"
  # "$HOMEBREW_PREFIX/opt/ruby/bin"
  # "$HOMEBREW_PREFIX/opt/python/libexec/bin"
  # "$HOMEBREW_PREFIX/opt/node/bin"
  # "$HOMEBREW_PREFIX/opt/sqlite/bin"
  # "$HOMEBREW_PREFIX/opt/openssl/bin"
  # "$HOMEBREW_PREFIX/opt/curl/bin"

  # Maintain existing PATH
  $path
)

# ========================================================================
# Additional Environment Setup
# ========================================================================

# Load OS-specific configurations
# if [[ -f "$ZDOTDIR/os/$(uname -s).zsh" ]]; then
#   source "$ZDOTDIR/os/$(uname -s).zsh"
# fi
