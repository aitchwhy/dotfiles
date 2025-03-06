# ========================================================================
# Node.js Development Environment Setup
# ========================================================================

# Volta JavaScript Tools Manager
# https://docs.volta.sh

# Set environment variables
export VOLTA_HOME="$HOME/.volta"

# Installation check and setup
if ! command -v volta &>/dev/null; then
  log_info "Installing Volta (Node.js tools manager)..."
  curl -LsSf https://get.volta.sh | bash
  
  # Add Volta to PATH for current session
  if [[ -d "$HOME/.volta" ]]; then
    export PATH="$VOLTA_HOME/bin:$PATH"
    log_info "Volta installed and environment loaded"
  fi
fi

# Optional Node.js settings
# export NODE_REPL_HISTORY="$XDG_STATE_HOME/node_history"
# export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/npmrc"
