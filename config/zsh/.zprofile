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
# Homebrew Setup (install if not installed)
# ========================================================================

if [[ ! -x /opt/homebrew/bin/brew ]]; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# setup homebrew shell path
eval "$(/opt/homebrew/bin/brew shellenv)"

# install core utils
export DOTFILES="$HOME/dotfiles"
local CORE_BREWFILE="$DOTFILES/core.Brewfile"
cat "$CORE_BREWFILE"
# brew bundle install --quiet --file="$CORE_BREWFILE"

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

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init.zsh 2>/dev/null || :
