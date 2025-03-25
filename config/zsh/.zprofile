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

# # install core utils
# brew install --quiet \
#   nvim \
#   bat \
#   fzf \
#   gh \
#   ghostty \
#   lazygit \
#   go \
#   starship \
#   atuin \
#   zoxide \
#   zsh-completions \
#   zsh-syntax-highlighting \
#   zsh-autosuggestions \
#   zsh-history-substring-search

# zsh setup
# TODO: fzf-zsh https://github.com/unixorn/fzf-zsh-plugin

# ========================================================================
# Editor & Terminal Settings
# ========================================================================

# Default editor
export EDITOR="nvim"
export VISUAL="$EDITOR"
# export PAGER="less -FRX"
export PAGER="bat --pager"

# Remove duplicate entries from PATH
# typeset -U path PATH
typeset -U path PATH

export COLORTERM="truecolor"
export PATH

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init.zsh 2>/dev/null || :
