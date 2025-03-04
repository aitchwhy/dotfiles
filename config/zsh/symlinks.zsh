# ========================================================================
# Dotfiles Symlink Map Configuration
# ========================================================================

# This file defines the mapping between dotfiles source locations and their
# target locations in the user's home directory. It's used by the installation
# script and other dotfiles management tools.

declare -gA DOTFILES_TO_SYMLINK_MAP=(
    ["$DOTFILES/config/git/gitconfig"]="$HOME/.gitconfig"
    ["$DOTFILES/config/git/gitignore"]="$HOME/.gitignore"
    ["$DOTFILES/config/starship.toml"]="$XDG_CONFIG_HOME/starship.toml"
    ["$DOTFILES/config/karabiner/karabiner.json"]="$XDG_CONFIG_HOME/karabiner/karabiner.json"
    ["$DOTFILES/config/nvim"]="$XDG_CONFIG_HOME/nvim"
    ["$DOTFILES/config/ghostty"]="$XDG_CONFIG_HOME/ghostty"
    ["$DOTFILES/config/atuin"]="$XDG_CONFIG_HOME/atuin"
    ["$DOTFILES/config/bat"]="$XDG_CONFIG_HOME/bat"
    ["$DOTFILES/config/lazygit"]="$XDG_CONFIG_HOME/lazygit"
    ["$DOTFILES/config/zellij"]="$XDG_CONFIG_HOME/zellij"
    ["$DOTFILES/config/espanso"]="$XDG_CONFIG_HOME/espanso"
    ["$DOTFILES/config/vscode/settings.json"]="$HOME/Library/Application Support/Code/User/settings.json"
    ["$DOTFILES/config/vscode/keybindings.json"]="$HOME/Library/Application Support/Code/User/keybindings.json"
    ["$DOTFILES/config/cursor/settings.json"]="$HOME/Library/Application Support/Cursor/User/settings.json"
    ["$DOTFILES/config/cursor/keybindings.json"]="$HOME/Library/Application Support/Cursor/User/keybindings.json"
    ["$DOTFILES/config/hammerspoon"]="$HOME/.hammerspoon"
    ["$DOTFILES/config/ai/claude/claude_desktop_config.json"]="$HOME/Library/Application Support/Claude/claude_desktop_config.json"
    ["$DOTFILES/config/ai/cline/cline_mcp_settings.json"]="$HOME/Library/Application Support/Cursor/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json"
)

# Export the map for use in other scripts
export DOTFILES_TO_SYMLINK_MAP
