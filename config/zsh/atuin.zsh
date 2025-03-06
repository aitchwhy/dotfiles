# Atuin shell history configuration
# No installation logic here - that's handled by .zshrc install_tool function

# Optional: Add any atuin-specific configuration here
# These will only be applied if atuin exists
if command -v atuin &>/dev/null; then
  # Example: Custom keybindings or settings
  # export ATUIN_NOBIND="true"
  # export ATUIN_SEARCH_MODE="fullscreen"
  
  # Note: The actual initialization is handled in .zshrc
  # via the line: has_command atuin && eval "$(atuin init zsh)"
fi
