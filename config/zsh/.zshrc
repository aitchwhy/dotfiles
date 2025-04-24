# ========================================================================
# ZSH Configuration File (.zshrc)
# ========================================================================
# Main configuration file for interactive ZSH shells
# References:
# - https://wiki.archlinux.org/title/Zsh#Configuration_files
# - https://gist.github.com/Linerre/f11ad4a6a934dcf01ee8415c9457e7b2

# Performance monitoring (uncomment to debug startup time)
# zmodload zsh/zprof

# ========================================================================
# Core Shell Options
# ========================================================================

# Navigation Options
# setopt AUTO_CD           # Change directory without cd
setopt AUTO_PUSHD        # Push directory to stack on cd
setopt PUSHD_IGNORE_DUPS # Don't store duplicates in stack
setopt PUSHD_SILENT      # Don't print stack after pushd/popd

# Globbing and Pattern Matching
setopt EXTENDED_GLOB # Extended globbing
setopt NO_CASE_GLOB  # Case insensitive globbing

# Misc Options
setopt INTERACTIVE_COMMENTS # Allow comments in interactive shells

# History Options
setopt EXTENDED_HISTORY       # Record timestamp
setopt HIST_EXPIRE_DUPS_FIRST # Delete duplicates first
setopt HIST_IGNORE_DUPS       # Don't record duplicates
setopt HIST_VERIFY            # Don't execute immediately upon history expansion
setopt SHARE_HISTORY          # Share history between sessions
setopt HIST_IGNORE_SPACE      # Don't record commands starting with space

# ========================================================================
# XDG Base Directory Specification
# ========================================================================

# export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/dotfiles/config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
# export XDG_BIN_HOME="${XDG_BIN_HOME:-$HOME/.local/bin}"

# Ensure XDG directories exist
[[ ! -d "$XDG_CONFIG_HOME" ]] && mkdir -p "$XDG_CONFIG_HOME"
[[ ! -d "$XDG_CACHE_HOME" ]] && mkdir -p "$XDG_CACHE_HOME"
[[ ! -d "$XDG_DATA_HOME" ]] && mkdir -p "$XDG_DATA_HOME"
[[ ! -d "$XDG_STATE_HOME" ]] && mkdir -p "$XDG_STATE_HOME"

# Ensure ZSH config directory is set
export zdot=${ZDOTDIR:-$XDG_CONFIG_HOME/zsh}
export dot="${DOTFILES:-$HOME/dotfiles}"
export cf="$dot/config"
export cfz="$dot/config/zsh"
export DOTFILES="${DOTFILES:-$HOME/dotfiles}"
export bpre="$(brew --prefix)"

# ========================================================================
# Keyboard & Input Configuration
# ========================================================================

# Vi Mode
bindkey -v
export KEYTIMEOUT=1

# ========================================================================
# Source Utility Functions
# ========================================================================

# Source our utility functions from utils.zsh
export UTILS="$DOTFILES/config/zsh/utils.zsh"
source "$UTILS"

# Check if a command exists
function has_command() {
	command -v "$1" &>/dev/null
}

# ========================================================================
# create XDG config symlinks for all configs
#
# Set a variable with a list of strings
# my_list=("apple" "banana" "cherry" "date")

# # Iterate over the list
# for item in "${my_list[@]}"; do
#     echo "Fruit: $item"
# done
# ========================================================================

#
# my_list=(
# 	"$cf/git/config"
# 	"$cf/lazygit/config.yml"
# 	"$cf/starship/starship.toml"
# 	"$cf/ghostty/config"
# 	"$cf/atuin/config.toml"
# )

# # Iterate over the list
# for item in "${my_list[@]}"; do
# 	echo "TODO: $item"
# done

# ========================================================================
# git

# https://git-scm.com/docs/git-config
# ========================================================================

export GIT_CONFIG="$cf/git/config"

# Lazygit custom config file location (https://github.com/jesseduffield/lazygit/blob/master/docs/Config.md#overriding-default-config-file-location)
# export CONFIG_DIR="$cf/lazygit"
export LG_CONFIG_FILE="$cf/lazygit/config.yml"

# ========================================================================
# starship
# ========================================================================

# ln -sf "$DOTFILES/config/starship.toml" "$XDG_CONFIG_HOME/starship.toml"
export STARSHIP_CONFIG="$cf/starship/starship.toml"
eval "$(starship init zsh)"

# ========================================================================
# ghostty
# ========================================================================

if ! has_command ghostty; then
	echo "ghostty not found. Installing ghostty..."
	brew install --quiet ghostty
fi

# if [[ ! -f "$/ghostty/config" ]]; then
#   echo "Linking ghostty config..."
#   ln -sf "$dOTFILES/config/ghostty/config" "$XDG_CONFIG_HOME/ghostty/config"
# fi

# ========================================================================
# zoxide
# ========================================================================
if ! has_command zoxide; then
	echo "zoxide not found. Installing zoxide..."
	brew install --quiet zoxide
fi

# if [[ ! -f "$XDG_CONFIG_HOME/zoxide/config.toml" ]]; then
#   echo "Linking zoxide config..."
#   ln -sf "$DOTFILES/config/zoxide/config.toml" "$XDG_CONFIG_HOME/zoxide/config.toml"
# fi

# ========================================================================
# atuin
# ========================================================================

# https://docs.atuin.sh/configuration/config/
export ATUIN_CONFIG_DIR="$cf/atuin"

# path_add "$HOME/.atuin/bin"

# if ! has_command atuin; then
#   echo "atuin not found. Installing atuin..."
#   curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh
#   echo "sourcing $HOME/.atuin/bin/env to add it to PATH"
#   source $HOME/.atuin/bin/env
# fi

# if [[ ! -f "$XDG_CONFIG_HOME/atuin/config.toml" ]]; then
#   echo "Linking atuin config..."
#   ln -sf "$DOTFILES/config/atuin/config.toml" "$XDG_CONFIG_HOME/atuin/config.toml"
# fi

# ln -sf "$DOTFILES/config/atuin/config.toml" "$XDG_CONFIG_HOME/atuin/config.toml"

. $HOME/.atuin/bin/env

# atuin zsh shell plugin
eval "$(atuin init zsh)"

# # Bind ctrl-r but not up arrow
# eval "$(atuin init zsh --disable-up-arrow)"
#
# # Bind up-arrow but not ctrl-r
# eval "$(atuin init zsh --disable-ctrl-r)"

# atuin import auto

# ========================================================================
# uv
# ========================================================================
# export PATH="/Users/hank/.local/share/../bin:$PATH"
# path_add "$HOME/.local/share/../bin"

# ========================================================================
# NodeJS
# ========================================================================
# Volta
# export VOLTA_HOME="$HOME/.volta"
# export PATH="$VOLTA_HOME/bin:$PATH"
has_command volta && path_add "$VOLTA_HOME/bin"

# TODO: add github extensions list
# - gh extension install dlvhdr/gh-dash
# TODO: add nodejs global packages (bun + etc)
# TODO: add uv global packages
# gpt-repository-loader v0.10.0
#- gpt-repository-loader
# llm v0.24.2
# - llm
# mitmproxy2swagger v0.10.1
# - mitmproxy2swagger
# poetry v2.1.1
# - poetry
# prefect v3.3.4
# - prefect
# strip-tags v0.6
# - strip-tags
# ttok v0.3
# - ttok

# mkdir -p ~/.npm-global
# path_add "~/.npm-global/bin"
# path_add "$HOME/.npm-global/bin"

# npm config set prefix ~/.npm-global

# TODO: npm install -g @anthropic-ai/claude-code
# TODO: npm install --save-dev commitizen commitlint husky
# claude
# liam
# bru
# mitmproxy2swagger
# pino-pretty
# prettier
# prisma

# ========================================================================
# nvim
# ========================================================================

export EDITOR="nvim"
export VISUAL="$EDITOR"

if ! has_command nvim; then
	echo "nvim not found. Installing nvim..."
	brew install --quiet neovim
fi

# ========================================================================
# fzf
# ========================================================================
if ! has_command fzf; then
	echo "fzf not found. Installing fzf..."
	brew install --quiet fzf
fi

# ========================================================================
# bat
# ========================================================================
export PAGER="bat --pager always"

if ! has_command bat; then
	echo "bat not found. Installing bat..."
	brew install --quiet bat
fi

# ========================================================================
# TODO: delta
# ========================================================================

# ========================================================================
# rust (rustup)
# https://rust-lang.org and https://rustup.rs
# ========================================================================

# Rust environment variables
export CARGO_HOME="${CARGO_HOME:-$HOME/.cargo}"
export RUSTUP_HOME="${RUSTUP_HOME:-$HOME/.rustup}"
path_add "$HOME/.cargo/bin"

# Installation check and setup
if ! has_command rustup; then
	log_info "Installing Rust via rustup..."
	curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
	[[ -f "$CARGO_HOME/env" ]] && source "$CARGO_HOME/env"
fi

#

# Add cargo bin to PATH if not already there
if [[ -d "$CARGO_HOME/bin" ]]; then
	path_add "$CARGO_HOME/bin"
fi

# ========================================================================
# claude
# ========================================================================

#
# if [[ ! -f "$XDG_CONFIG_HOME/claude/config.json" ]]; then
#   echo "Linking claude config..."
#   ln -sf "$DOTFILES/config/claude/config.json" "$XDG_CONFIG_HOME/claude/config.json"
# fi
#
# ========================================================================
# chatgpt
# ========================================================================

# if ! has_command chatgpt; then
#   echo "chatgpt not found. Installing chatgpt..."
#   brew install --quiet chatgpt
# fi

# brew services restart postgresql@17

# postgresql://[user[:password]@][host][:port][/dbname][?param1=value1&...]
# Here's an example of how you might set up a connection string:
#
# postgresql://username:password@localhost:5432/mydatabase
# 	•	username: Your PostgreSQL username.
# 	•	password: Your PostgreSQL password.
# 	•	localhost: The host where your PostgreSQL server is running. If it's on your local machine, you can use localhost.
# 	•	5432: The default port for PostgreSQL. Change it if your server uses a different port.
# 	•	mydatabase: The name of the database you want to connect to.
# If you have PostgreSQL installed on your Mac and want to connect to it locally, ensure that the PostgreSQL server is running. You can start the server using:
#
# brew services start postgresql
# Make sure to replace the placeholders in the connection string with your actual database credentials and details.

# ========================================================================
# Go
# ========================================================================
export GOPATH="$HOME/go"
export GOBIN="$GOPATH/bin"

# ========================================================================
# Completions
# ========================================================================

# Load ZSH plugins from Homebrew if available
if [[ -d "$HOMEBREW_PREFIX/share" ]]; then
	plugins=(
		"zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
		"zsh-autosuggestions/zsh-autosuggestions.zsh"
		"zsh-abbr/zsh-abbr.zsh"
	)
	for plugin in $plugins; do
		plugin_path="$HOMEBREW_PREFIX/share/$plugin"
		# has_command abbr && FPATH=$brewp/share/zsh-abbr:$FPATH
		if [[ -f "$plugin_path" ]]; then
			source "$plugin_path"
			# Completions setup
			FPATH=$plugin_path:$FPATH
		fi
	done

fi

# Completions setup
FPATH=$brewp/share/zsh/site-functions:$FPATH

autoload -Uz compinit
compinit

# ========================================================================
# atuin
# ========================================================================
export ATUIN_CONFIG_DIR="$cf/atuin"

! has_command atuin && eval "$(atuin init zsh)"

. "$HOME/.atuin/bin/env"

# ========================================================================
# zellij
# ========================================================================

export ZELLIJ_CONFIG_DIR="$cf/zellij"
# Zellij (auto-start on startup)
has_command zellij && eval "$(zellij setup --generate-auto-start zsh)"

# zellij issue with Yazi (image preview) - https://yazi-rs.github.io/docs/image-preview#zellij
# TERM=xterm-kitty yazi

# ========================================================================
# yazi
# ========================================================================

export YAZI_CONFIG_DIR="$cf/yazi"
# yazi (https://yazi-rs.github.io/docs/quick-start)

function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

# ========================================================================
# fzf
# ========================================================================
has_command fzf && source <(fzf --zsh)
# Load FZF completions
# [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# ========================================================================
# Tool Initialization
# ========================================================================

# Initialize tools only if they are installed
has_command starship && eval "$(starship init zsh)"
has_command zoxide && eval "$(zoxide init zsh)"
has_command direnv && eval "$(direnv hook zsh)"
# has_command fnm && eval "$(fnm env --use-on-cd)"
# has_command volta && eval "$(volta setup)"
has_command uv && eval "$(uv generate-shell-completion zsh)"
# has_command pyenv && eval "$(pyenv init -)"
# has_command abbr && eval "$(abbr init zsh)"

# Source aliases and functions
[[ -f "${ZDOTDIR}/aliases.zsh" ]] && source "${ZDOTDIR}/aliases.zsh"
[[ -f "${ZDOTDIR}/functions.zsh" ]] && source "${ZDOTDIR}/functions.zsh"

# ========================================================================
# install core
# ========================================================================
# brew install --quiet --file="$DOTFILES/Brewfile.core"

# ========================================================================
# Path Configuration
#
# https://stackoverflow.com/questions/11530090/adding-a-new-entry-to-the-path-variable-in-zsh
# # append
# path+=('/home/david/pear/bin')
# # or prepend
# path=('/home/david/pear/bin' $path)
# Add a new path, if it's not already there
# path+=(~/my_bin)
# ========================================================================

# ========================================================================
# Dotfiles Symlink Map Configuration
# ========================================================================

# This defines the mapping between dotfiles source locations and their
# target locations in the user's home directory. It's used by the installation
# script and other dotfiles management tools.

declare -gA LINKMAP=(
	#   # Git configurations
	#   # ["$DOTFILES/config/git/config"]="$XDG_CONFIG_HOME/.gitconfig"
	#   # ["$DOTFILES/config/git/ignore"]="$XDG_CONFIG_HOME/git/.gitignore"
	#   # ["$DOTFILES/config/git/gitattributes"]="$HOME/.gitattributes"
	#   # ["$DOTFILES/config/git/gitmessage"]="$HOME/.gitmessage"

	#   # ["$DOTFILES/config/starship.toml"]="$XDG_CONFIG_HOME/starship.toml"
	#   # ["$DOTFILES/config/ghostty/config"]="$XDG_CONFIG_HOME/ghostty"
	#   # ["$DOTFILES/config/atuin/config.toml"]="$XDG_CONFIG_HOME/atuin/config.toml"
	#   # ["$DOTFILES/config/lazygit/config.yml"]="$XDG_CONFIG_HOME/lazygit/config.yml"
	#   ["$DOTFILES/config/karabiner/karabiner.json"]="$XDG_CONFIG_HOME/karabiner/karabiner.json"

	#   # Editor configurations
	#   ["$DOTFILES/config/vscode/settings.json"]="$HOME/Library/Application Support/Code/User/settings.json"
	#   ["$DOTFILES/config/vscode/keybindings.json"]="$HOME/Library/Application Support/Code/User/keybindings.json"
	#   ["$DOTFILES/config/cursor/settings.json"]="$HOME/Library/Application Support/Cursor/User/settings.json"
	#   ["$DOTFILES/config/cursor/keybindings.json"]="$HOME/Library/Application Support/Cursor/User/keybindings.json"

	#   # ["$DOTFILES/config/yazi"]="$XDG_CONFIG_HOME/yazi"
	#   # ["$DOTFILES/config/nvim"]="$XDG_CONFIG_HOME/nvim"
	#   # ["$DOTFILES/config/bat"]="$XDG_CONFIG_HOME/bat"
	#   # ["$DOTFILES/config/zellij"]="$XDG_CONFIG_HOME/zellij"
	#   # ["$DOTFILES/config/zed"]="$XDG_CONFIG_HOME/zed"
	#   # ["$DOTFILES/config/espanso"]="$XDG_CONFIG_HOME/espanso"
	#   # ["$DOTFILES/config/warp/keybindings.yaml"]="$XDG_CONFIG_HOME/warp/keybindings.yaml"

	#   # ["$DOTFILES/config/hammerspoon"]="$HOME/.hammerspoon"

	#   # AI tools configurations

	#   # ["$DOTFILES/config/ai/claude/claude_desktop_config.json"]="$HOME/Library/Application Support/Claude/claude_desktop_config.json"
	#   # ["$DOTFILES/config/ai/cline/cline_mcp_settings.json"]="$HOME/Library/Application Support/Cursor/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json"
)

# # Export the map for use in other scripts
export LINKMAP

# # Initialize dotfiles - ensure essential symlinks exist
# # This is a lightweight version of setup_cli_tools from install.zsh
# # that won't disrupt the user's shell experience
# dotfiles_init() {
#   # Only run in interactive shells to avoid slowing down scripts
#   if [[ -o interactive ]]; then
#     # Create missing symlinks silently
#     for key in ${(k)DOTFILES_TO_SYMLINK_MAP}; do
#       local src="$key"
#       local dst="${DOTFILES_TO_SYMLINK_MAP[$key]}"

#       # Only create symlink if source exists and destination doesn't
#       if [[ -e "$src" ]] && [[ ! -e "$dst" ]]; then
#         local parent_dir=$(dirname "$dst")

#         # Create parent directory if needed
#         [[ ! -d "$parent_dir" ]] && mkdir -p "$parent_dir"

#         # Create the symlink
#         echo "Creating symlink: $dst -> $src"
#         ln -sf "$src" "$dst"
#       fi
#     done
#   fi
# }

# ========================================================================
# postgresql@17
# ========================================================================
# postgresql@17 is keg-only, which means it was not symlinked into /opt/homebrew,
# because this is an alternate version of another formula.
#
# If you need to have postgresql@17 first in your PATH, run:
#   echo 'export PATH="/opt/homebrew/opt/postgresql@17/bin:$PATH"' >> /Users/hank/.config/zsh/.zshrc
#
# For compilers to find postgresql@17 you may need to set:
#   export LDFLAGS="-L/opt/homebrew/opt/postgresql@17/lib"
#   export CPPFLAGS="-I/opt/homebrew/opt/postgresql@17/include"
#
# To start postgresql@17 now and restart at login:
#   brew services start postgresql@17
# Or, if you don't want/need a background service you can just run:
#   LC_ALL="C" /opt/homebrew/opt/postgresql@17/bin/postgres -D /opt/homebrew/var/postgresql@17

# export PATH="/opt/homebrew/opt/postgresql@17/bin:$PATH"
path_add "/opt/homebrew/opt/postgresql@17/bin"

export LDFLAGS="-L/opt/homebrew/opt/postgresql@17/lib"
export CPPFLAGS="-I/opt/homebrew/opt/postgresql@17/include"
