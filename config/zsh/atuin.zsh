# ========================================================================
# Atuin Shell History Configuration
# ========================================================================
# https://github.com/atuinsh/atuin

# Source common utilities if not already loaded
# [[ -f "$ZDOTDIR/utils.zsh" ]] && source "$ZDOTDIR/utils.zsh"

# Note: Installation logic is handled in .zshrc via the install_tool function

# # Ensure required directories exist
# if ! [[ -d "$XDG_DATA_HOME/atuin" ]]; then
#   ensure_dir "$XDG_DATA_HOME/atuin"
#   log_info "Created Atuin data directory at $XDG_DATA_HOME/atuin"
# fi

# if ! [[ -d "$XDG_CONFIG_HOME/atuin" ]]; then
#   ensure_dir "$XDG_CONFIG_HOME/atuin"
#   log_info "Created Atuin config directory at $XDG_CONFIG_HOME/atuin"
# fi

# Atuin environment variables
# export ATUIN_NOBIND="false"              # Enable default keybindings
# export ATUIN_SEARCH_MODE="fullscreen"    # Use fullscreen search mode
# export ATUIN_DB_PATH="$XDG_DATA_HOME/atuin/history.db"
# export ATUIN_KEY_PATH="$XDG_DATA_HOME/atuin/key"
# export ATUIN_SESSION_PATH="$XDG_DATA_HOME/atuin/session"

# The actual initialization happens in .zshrc via:
# has_command atuin && eval "$(atuin init zsh)"
