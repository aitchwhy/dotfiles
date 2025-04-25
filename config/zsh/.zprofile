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

# ========================================================================
# Homebrew Setup (install if not installed)
# ========================================================================
# set -x
echo "Loading Homebrew shell environment..."
# setup homebrew shell path
eval "$(/opt/homebrew/bin/brew shellenv)"

# zsh setup
# TODO: fzf-zsh https://github.com/unixorn/fzf-zsh-plugin

# minio / s3 frontend -> http://localhost:51021
# noggin server -> http://localhost:59000
# vibes frontend -> http://localhost:3000
# prefect (job runner) -> http://localhost:52000/runs/flow-run

# MINIO_S3_STORAGE="http://localhost:51021/"
# NOGGIN_SERVER="http://localhost:59000/"
# VIBES_FRONTEND="http://localhost:3000/"
# PREFECT_JOB_RUNNER="http://localhost:52000/runs/flow-run"1
#

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

. "$HOME/.cargo/env"
export PATH="$HOME/.npm-global/bin/:$PATH"
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init.zsh 2>/dev/null || :
