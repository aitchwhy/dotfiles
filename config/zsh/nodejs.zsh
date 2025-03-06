# ========================================================================
# Node.js Development Environment Setup
# ========================================================================
# https://nodejs.org/ and https://volta.sh

# Source common utilities if not already loaded
[[ -f "$ZDOTDIR/utils.zsh" ]] && source "$ZDOTDIR/utils.zsh"

# Volta JavaScript Tools Manager
# Set environment variables
export VOLTA_HOME="$HOME/.volta"
export NODE_REPL_HISTORY="$XDG_STATE_HOME/node_history"
# export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/npmrc"

# Installation check and setup
if ! has_command volta; then
  log_info "Installing Volta (Node.js tools manager)..."
  curl -LsSf https://get.volta.sh | bash

  # Add Volta to PATH for current session
  if [[ -d "$HOME/.volta" ]]; then
    path_add "$VOLTA_HOME/bin"
    log_info "Volta installed and environment loaded"
  fi
fi

# Optional: Use fnm instead of volta
# export FNM_DIR="$XDG_DATA_HOME/fnm"
# if ! has_command fnm; then
#   log_info "Installing fnm..."
#   curl -fsSL https://fnm.vercel.app/install | bash
# fi
