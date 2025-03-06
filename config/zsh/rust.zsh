# ========================================================================
# Rust Development Environment Setup
# ========================================================================

# Rust environment variables
export CARGO_HOME="${CARGO_HOME:-$HOME/.cargo}"
export RUSTUP_HOME="${RUSTUP_HOME:-$HOME/.rustup}"

# Installation check and setup
if ! command -v rustup &>/dev/null; then
  log_info "Installing Rust via rustup..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
  
  # Source the cargo environment if installed
  if [[ -f "$CARGO_HOME/env" ]]; then
    source "$CARGO_HOME/env"
    log_info "Rust installed and environment loaded"
  else
    log_info "Rust installation may need manual configuration"
  fi
fi

# Optional: Add cargo completions
# rustup completions zsh > $ZDOTDIR/.zfunc/_rustup
# rustup completions zsh cargo > $ZDOTDIR/.zfunc/_cargo

# Note: For Apple Silicon Macs, the Rust toolchain is installed with native arm64 support
