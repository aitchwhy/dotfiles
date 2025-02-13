# Function to safely load brew-installed plugins
_load_brew_plugin() {
    local plugin_name="$1"
    local plugin_path="$(brew --prefix)/share/zsh-${plugin_name}/${plugin_name}.zsh"
    if [[ -f "$plugin_path" ]]; then
        source "$plugin_path"
    else
        echo "Warning: Plugin $plugin_name not found at $plugin_path"
    fi
}

# Load essential plugins
_load_brew_plugin "syntax-highlighting"
_load_brew_plugin "autosuggestions"

# # Initialize fzf
# if [[ -f "${HOMEBREW_PREFIX}/opt/fzf/shell/completion.zsh" ]]; then
#     source "${HOMEBREW_PREFIX}/opt/fzf/shell/completion.zsh"
#     source "${HOMEBREW_PREFIX}/opt/fzf/shell/key-bindings.zsh"
# fi