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
# Source Utility Functions (Non-Interactive Mode)
# ========================================================================

# Source utils.zsh for environment variables and utility functions
# This provides XDG_* variables and other core environment settings
[[ -f "$ZDOTDIR/utils.zsh" ]] && source "$ZDOTDIR/utils.zsh"

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
#
# https://stackoverflow.com/questions/11530090/adding-a-new-entry-to-the-path-variable-in-zsh
# # append
# path+=('/home/david/pear/bin')
# # or prepend
# path=('/home/david/pear/bin' $path)
# ========================================================================

# export VOLTA_HOME="$HOME/.volta"
# export PATH="$VOLTA_HOME/bin:$PATH"

# Remove duplicate entries from PATH
# typeset -U path PATH
typeset -U path

# Add prioritized paths
path=(
  # Version managers (need to be before Homebrew)
  "$HOME/.volta/bin" # Node.js version manager

  # Other language-specific paths
  "$HOME/.cargo/bin" # Rust
  "$HOME/go/bin"     # Go

  # System paths
  "$HOME/.local/bin" # User local binaries
  "$HOME/bin"        # User personal binaries

  # Keep existing PATH (includes Homebrew)
  $path
)

export PATH
