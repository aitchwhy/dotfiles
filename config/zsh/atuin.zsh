# Install atuin if command not found
echo "-------- atuin --------"
if ! command -v atuin &>/dev/null; then
  log_info "Installing Atuin..."
  curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh
  
  # Initialize atuin if newly installed
  if command -v atuin &>/dev/null; then
    log_info "Initializing Atuin..."
    eval "$(atuin init zsh)"
  fi
fi
