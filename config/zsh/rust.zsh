echo "-------- rust --------"

# Install Rust if not already installed
if ! command -v rustup &>/dev/null; then
  log_info "Installing Rust via rustup..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
  
  # Source the cargo environment if installed
  if [[ -f "$HOME/.cargo/env" ]]; then
    source "$HOME/.cargo/env"
    log_info "Rust installed and environment loaded"
  else
    log_info "Rust installation may need manual configuration"
  fi
fi
