echo "-------- python --------"

# Install uv if not already installed
# uv - https://docs.astral.sh/uv/getting-started/installation/
echo "-------- uv --------"
if ! command -v uv &>/dev/null; then
  log_info "Installing uv Python package manager..."
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi

#   # Add uv to PATH for current session if needed
#   if [[ -d "$HOME/.cargo/bin" ]] && [[ -x "$HOME/.cargo/bin/uv" ]]; then
#     export PATH="$HOME/.cargo/bin:$PATH"
#     log_info "uv installed and available in PATH"
#   fi
