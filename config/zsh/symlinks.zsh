# ========================================================================
# Dotfiles Symlink Map Configuration
# ========================================================================

# This file defines the mapping between dotfiles source locations and their
# target locations in the user's home directory. It's used by the installation
# script and other dotfiles management tools.

declare -gA DOTFILES_TO_SYMLINK_MAP=(
    # Git configurations
    ["$DOTFILES/config/git/gitconfig"]="$HOME/.gitconfig"
    ["$DOTFILES/config/git/gitignore"]="$HOME/.gitignore"
    ["$DOTFILES/config/git/gitattributes"]="$HOME/.gitattributes"
    ["$DOTFILES/config/git/gitmessage"]="$HOME/.gitmessage"

    # XDG configurations
    ["$DOTFILES/config/starship.toml"]="$XDG_CONFIG_HOME/starship.toml"
    ["$DOTFILES/config/karabiner/karabiner.json"]="$XDG_CONFIG_HOME/karabiner/karabiner.json"
    ["$DOTFILES/config/nvim"]="$XDG_CONFIG_HOME/nvim"
    ["$DOTFILES/config/ghostty"]="$XDG_CONFIG_HOME/ghostty"
    ["$DOTFILES/config/atuin"]="$XDG_CONFIG_HOME/atuin"
    ["$DOTFILES/config/bat"]="$XDG_CONFIG_HOME/bat"
    ["$DOTFILES/config/lazygit"]="$XDG_CONFIG_HOME/lazygit"
    ["$DOTFILES/config/zellij"]="$XDG_CONFIG_HOME/zellij"
    ["$DOTFILES/config/zed"]="$XDG_CONFIG_HOME/zed"
    ["$DOTFILES/config/espanso"]="$XDG_CONFIG_HOME/espanso"
    ["$DOTFILES/config/yazi"]="$XDG_CONFIG_HOME/yazi"
    ["$DOTFILES/config/warp/keybindings.yaml"]="$XDG_CONFIG_HOME/warp/keybindings.yaml"

    # Editor configurations
    ["$DOTFILES/config/vscode/settings.json"]="$HOME/Library/Application Support/Code/User/settings.json"
    ["$DOTFILES/config/vscode/keybindings.json"]="$HOME/Library/Application Support/Code/User/keybindings.json"
    ["$DOTFILES/config/cursor/settings.json"]="$HOME/Library/Application Support/Cursor/User/settings.json"
    ["$DOTFILES/config/cursor/keybindings.json"]="$HOME/Library/Application Support/Cursor/User/keybindings.json"

    # macOS-specific configurations
    ["$DOTFILES/config/hammerspoon"]="$HOME/.hammerspoon"

    # AI tools configurations
    ["$DOTFILES/config/ai/claude/claude_desktop_config.json"]="$HOME/Library/Application Support/Claude/claude_desktop_config.json"
    ["$DOTFILES/config/ai/cline/cline_mcp_settings.json"]="$HOME/Library/Application Support/Cursor/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json"
)

# Define additional paths that might have specific Apple Silicon considerations
# if needed in the future

# Export the map for use in other scripts
export DOTFILES_TO_SYMLINK_MAP
