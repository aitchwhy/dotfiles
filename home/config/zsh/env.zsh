# ~/.config/zsh/env.zsh - Environment variables

# Tool-specific configurations
export BAT_CONFIG_PATH="${XDG_CONFIG_HOME}/bat/config"
export RIPGREP_CONFIG_PATH="${XDG_CONFIG_HOME}/ripgrep/config"

# FZF configuration
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border"

# Zoxide configuration
export _ZO_DATA_DIR="${XDG_DATA_HOME}/zoxide"

# Ensure cache directories exist
[[ -d "${XDG_CACHE_HOME}/zsh" ]] || mkdir -p "${XDG_CACHE_HOME}/zsh"
[[ -d "${XDG_STATE_HOME}/zsh" ]] || mkdir -p "${XDG_STATE_HOME}/zsh"

# Helper functions
load_if_exists() {
    local cmd="$1"
    local setup_cmd="$2"
    
    if command -v "$cmd" > /dev/null; then
        eval "$setup_cmd"
    fi
}

load_config_if_exists() {
    local config="$1"
    [[ -f "$config" ]] && source "$config"
}