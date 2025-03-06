# ========================================================================
# Rust Development Environment Setup
# ========================================================================
# https://rust-lang.org and https://rustup.rs

# Source common utilities if not already loaded
[[ -f "$ZDOTDIR/utils.zsh" ]] && source "$ZDOTDIR/utils.zsh"

# Rust environment variables
export CARGO_HOME="${CARGO_HOME:-$HOME/.cargo}"
export RUSTUP_HOME="${RUSTUP_HOME:-$HOME/.rustup}"

# Installation check and setup
if ! has_command rustup; then
  log_info "Installing Rust via rustup..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
  
  # Source the cargo environment if installed
  if [[ -f "$CARGO_HOME/env" ]]; then
    source "$CARGO_HOME/env"
    log_success "Rust installed and environment loaded"
  else
    log_warn "Rust installation may need manual configuration"
  fi
fi

# Add cargo bin to PATH if not already there
[[ -d "$CARGO_HOME/bin" ]] && path_add "$CARGO_HOME/bin"

# Optional: Add cargo completions
# if has_command rustup; then
#   mkdir -p "$ZDOTDIR/.zfunc"
#   rustup completions zsh > "$ZDOTDIR/.zfunc/_rustup"
#   rustup completions zsh cargo > "$ZDOTDIR/.zfunc/_cargo"
# fi

# Note: For Apple Silicon Macs, the Rust toolchain is installed with native arm64 support
