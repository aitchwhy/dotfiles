# -----------------------------------------------------------------------------
# ~/.zprofile (Invoked once at login on macOS)
#
# mac.install.guide tips (https://mac.install.guide/terminal/zshrc-zprofile)
# - Use ~/.zprofile to set the PATH and EDITOR environment variables.
# -----------------------------------------------------------------------------

# Initialize Homebrew
if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Editor configurations
export EDITOR="vim"
export VISUAL="vim"
export PAGER="cat"
# export MANPAGER="sh -c 'col -bx | bat -l man -p'"

# Language configurations
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# Homebrew configuration
# export HOMEBREW_NO_ENV_HINTS=1
# export HOMEBREW_NO_ANALYTICS=1
# export HOMEBREW_AUTOREMOVE=1
# export HOMEBREW_NO_BOTTLE_SOURCE_FALLBACK=1

# # Tool configuration paths
# export STARSHIP_CONFIG="$XDG_CONFIG_HOME/starship/starship.toml"
# export STARSHIP_CACHE="$XDG_CACHE_HOME/starship"
# export ATUIN_CONFIG_DIR="$XDG_CONFIG_HOME/atuin"
# export ZELLIJ_CONFIG_DIR="$XDG_CONFIG_HOME/zellij"
# export BAT_CONFIG_PATH="$XDG_CONFIG_HOME/bat/config"
# export RIPGREP_CONFIG_PATH="$XDG_CONFIG_HOME/ripgrep/config"

# # Additional tool configurations
# export NODE_REPL_HISTORY="$XDG_STATE_HOME/node/repl_history"
# export PYTHONSTARTUP="$XDG_CONFIG_HOME/python/startup.py"
# export DOCKER_CONFIG="$XDG_CONFIG_HOME/docker"
# export AWS_CONFIG_FILE="$XDG_CONFIG_HOME/aws/config"
# export AWS_SHARED_CREDENTIALS_FILE="$XDG_CONFIG_HOME/aws/credentials"
#
# # Ruby configuration
# if [ -d "/opt/homebrew/opt/ruby/bin" ]; then
#     _add_to_path_if_exists "/opt/homebrew/opt/ruby/bin" "prepend"
#     _add_to_path_if_exists "$(gem environment gemdir)/bin" "prepend"
# fi


# Ensure path arrays do not contain duplicates
# - 2.5.11 "Path" section at (https://zsh.sourceforge.io/Guide/zshguide02.html#l6)
# - https://mac.install.guide/terminal/path
typeset -U path
# path=(
#     $HOME/.local/bin
#     $HOME/bin
#     $path
# )
# export PATH
