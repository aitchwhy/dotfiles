echo "-------- nodejs --------"

# Install volta if not already installed
# Volta - https://docs.volta.sh/installation/
echo "-------- volta --------"
if ! command -v volta &>/dev/null; then
  log_info "Installing Volta..."
  curl -LsSf https://get.volta.sh | bash
  
  # Add Volta to PATH for current session
  if [[ -d "$HOME/.volta" ]]; then
    export VOLTA_HOME="$HOME/.volta"
    export PATH="$VOLTA_HOME/bin:$PATH"
    log_info "Volta installed and environment loaded"
  fi
fi
