# ========================================================================
# ZSH Profile (.zprofile)
# ========================================================================
# Executed at login (after .zshenv)
# Used primarily for setting PATH and environment variables
# References:
# - https://wiki.archlinux.org/title/Zsh#Configuration_files
# - https://gist.github.com/Linerre/f11ad4a6a934dcf01ee8415c9457e7b2
# - https://mac.install.guide/terminal/zshrc-zprofile
echo "Loading .zprofile from $ZDOTDIR"
# echo "Loading /etc/profile.d/nix.sh from $ZDOTDIR"

# ========================================================================
# Homebrew Setup (install if not installed)
# ========================================================================
# set -x
echo "Loading Homebrew shell environment..."
# setup homebrew shell path
eval "$(/opt/homebrew/bin/brew shellenv)"

# zsh setup
# TODO: fzf-zsh https://github.com/unixorn/fzf-zsh-plugin


# ========================================================================
# Editor & Terminal Settings
# ========================================================================

# Default editor
export EDITOR="nvim"
export VISUAL="$EDITOR"
# export PAGER="less -FRX"
export PAGER="bat --pager always"

# Remove duplicate entries from PATH
# typeset -U path PATH
typeset -U path PATH

export COLORTERM="truecolor"

# export PATH="$HOME/.npm-global/bin/:$PATH"
export VOLTA_HOME="$HOME/.volta"

paths=(
  # last in PATH
  "$HOME/.cargo/bin"
  "$HOME/.npm-global/bin"
  "$HOME/.volta/bin"
  "$HOME/./bin"
  "$HOME/.local/bin"
  "$HOME/dotfiles/bin"
  # https://mac.install.guide/ruby/13
  "/opt/homebrew/opt/ruby/bin"
  "`gem environment gemdir`/bin"
  $PATH
  # "$HOME/.nix-profile/bin"
  # "/nix/var/nix/profiles/default/bin"
  # first in PATH
)
for p in "${paths[@]}"; do 
  PATH="$p:$PATH"
done


# Set up Homebrew
export HOMEBREW_PREFIX="${HOMEBREW_PREFIX:-$(brew --prefix 2>/dev/null)}"



# Add Nix to path
# export PATH=$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$PATH

. "$HOME/.cargo/env"

export PATH

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init.zsh 2>/dev/null || :
