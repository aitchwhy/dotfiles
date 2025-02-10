# -----------------------------------------------------
# Login shell configuration
# -----------------------------------------------------

# .zprofile
# This file is loaded for login shells (e.g., when you log in via SSH,
# or launch a terminal as a "login" shell). Typically environment variables go here.
# Overlaps somewhat with .zshrc. Keep minimal.


# If you prefer to source .zshrc from here, uncomment:
# source "${ZDOTDIR:-$HOME}/.zshrc"


# macOS Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"
# if [[ -f /opt/homebrew/bin/brew ]]; then
#     eval "$(/opt/homebrew/bin/brew shellenv)"
# fi

# # uv python management
# eval "$(uv generate-shell-completion zsh)"
# if command -v uv > /dev/null; then
#     eval "$(uv env)"
# fi

# # Node.js management
# if command -v fnm > /dev/null; then
#     eval "$(fnm env --use-on-cd)"
# fi

# # Rust environment
# [[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# # Bun
# [[ -f "$HOME/.bun/_bun" ]] && source "$HOME/.bun/_bun"

# GPG
# export GPG_TTY=$(tty)

# # Example: set PATH overrides or environment vars
# export PATH="$HOME/.local/bin:$PATH"
