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
unsetopt EXTENDED_GLOB # No Extended globbing (no need for double quotes for nix flakes pkg#target due to hashtag needing escape)
setopt NO_NOMATCH
setopt NO_CASE_GLOB # Case insensitive globbing

# Misc Options
setopt INTERACTIVE_COMMENTS # Allow comments in interactive shells

# History Options
setopt EXTENDED_HISTORY       # Record timestamp
setopt HIST_EXPIRE_DUPS_FIRST # Delete duplicates first
setopt HIST_IGNORE_DUPS       # Don't record duplicates
setopt HIST_VERIFY            # Don't execute immediately upon history expansion
setopt SHARE_HISTORY          # Share history between sessions
setopt HIST_IGNORE_SPACE      # Don't record commands starting with space
# setopt

# Keep your zsh history file (can re-use in Nix shell)
export HISTFILE="$HOME/.zsh_history"

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

export NIX_CONFIG_DIR="$cf/nix"

# ========================================================================
# secrets
# ========================================================================

# ========================================================================
# Keyboard & Input Configuration
# ========================================================================

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

##################################
# Nix
##################################

alias nix='nix'
alias nixh='nix --help'
alias nixf="$EDITOR $cf/nix/nix.conf"
alias nixgc="nix-collect-garbage -d"
alias nixpkgs="nix search"
alias nixsh="nix-shell --run zsh"
alias nixdev="nix develop"
alias nixf="nix flake"
alias nixup="sudo nixos-rebuild switch"
alias nixdarwinup="darwin-rebuild switch --flake ~/dotfiles"

##################################
# Homebrew
##################################
alias b="brew"
alias bupd="brew update"
alias bupg="brew upgrade"
alias bclean="brew cleanup --prune=all && brew autoremove"
alias bcleanall='brew cleanup --prune=all && rm -rf $(brew --cache) && brew autoremove'
alias bi="brew info"
alias bin="brew install"
alias brein="brew reinstall"
alias bs="brew search"
alias bsa="brew search --eval-all --desc"
alias bl="brew leaves"
alias bcin="brew install --cask"
alias bb="brew bundle -g"
alias bbe="brew bundle edit -g"
alias bba="brew bundle add -g"
alias bbrm="brew bundle remove -g"
alias bbls="brew bundle dump -g --all --file=- --verbose"
alias bbsave="brew bundle dump -g --all --verbose --global"
alias bbcheck="brew bundle check -g --all --verbose --global"
alias bup='brew update && brew upgrade && brew cleanup'
alias brewup='bup'

##################################
# File System Navigation & Management
# eza
# fd
##################################
alias ls="eza --icons --group-directories-first"
alias ll="eza --icons --group-directories-first -la"
alias la="eza --icons --group-directories-first -a"
alias lt="eza --icons --group-directories-first --tree"
alias lt2="eza --icons --group-directories-first --tree --level=2"
alias dl='cd ~/Downloads'
alias cf='cd ~/.config/'

##################################
# Text Editors
##################################
alias v='$EDITOR'
alias vi='$EDITOR'
alias vim='$EDITOR'

##################################
# Zsh
##################################
alias zr="exec zsh"
alias ze="nvim '$ZDOTDIR'/{.zshrc,.zprofile,.zshenv}"
alias zeall="nvim '$ZDOTDIR'/{.zshrc,.zprofile,.zshenv,*.zsh}"
alias zcompreset="rm -f ~/.zcompdump; compinit"

##################################
# System Information & Utilities
##################################
alias ip="ipconfig getifaddr en0"
alias localip="ipconfig getifaddr en0"
alias publicip="curl -s https://api.ipify.org"
alias ports="sudo lsof -i -P -n | grep LISTEN"
alias listening="sudo lsof -i -P -n | grep LISTEN"
alias flush="dscacheutil -flushcache && killall -HUP mDNSResponder"
alias printpath='echo $PATH | tr ":" "\n"'
alias printfuncs='print -l ${(k)functions[(I)[^_]*]} | sort'
alias printfpath='for fp in $fpath; do echo $fp; done; unset fp'
alias flushdns="sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder"
alias showhidden="defaults write com.apple.finder AppleShowAllFiles YES; killall Finder"

##################################
# Git
##################################
alias gs='git status'
alias ga='git add'
alias gai='git add -i'
alias gaa='git add --all'
alias gcm='git commit -m'
alias gca='git commit --amend --no-edit'
alias gc='git commit'
alias gp='git push'
alias gll='git pull'
alias lg='lazygit'
alias lgdot='lazygit --path $DOTFILES'

##################################
# Modern CLI Alternatives
##################################
alias ps='procs'
alias ping='gping'
alias diff='delta'
alias cat='bat --paging=always'
alias miller='mlr'
alias grep='rg'
alias find='fd'
alias md='glow'
alias net='trippy'
alias netviz='netop'
alias jwt='jet-ui'
alias sed='sd'
alias du='dust'
alias csv='xsv'
alias jsonfilter='jsonf'
alias jsonviewer='jsonv'

##################################
# Docker & Kubernetes
##################################
alias d='docker'
alias dstart='docker start'
alias dstop='docker stop'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias dimg='docker images'
alias dx='docker exec -it'
alias drm='docker rm'
alias drmi='docker rmi'
alias dbuild='docker build'
alias dc='docker-compose'
alias k='k9s'
alias ld="lazydocker"

##################################
# Just Task Runner
##################################
alias j="just"
alias jfmt="just --unstable --fmt"
alias .j='just --justfile $USER_JUSTFILE --working-directory .'
alias .jfmt='just --justfile $USER_JUSTFILE --working-directory . --unstable --fmt'

##################################
# FZF Enhanced Commands
##################################
alias flog='fzf --preview "bat --style=numbers --color=always --line-range=:500 {}"'
alias falias='alias | fzf'
alias fman='man -k . | fzf --preview "man {}"'
alias fls='man -k . | fzf --preview "man {}"'

##################################
# Terminal Multiplexers & Tools
##################################
alias g='ghostty'
alias zj="zellij"
alias zjls="zellij list-sessions"
alias zja='zellij attach "$(zellij list-sessions -n | fzf --reverse --border --no-sort --height 40% | awk '\''{print $1}'\'')"'
alias zje="zellij edit"

##################################
# Utilities & Other Tools
##################################
alias cheat="tldr"
alias ch="cheat"
alias claude="/Users/hank/.claude/local/claude"
alias ts="tailscale"
alias hf="huggingface-cli"
alias rx="repomix"

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

# completions (AFTER compinit)
eval "$(zoxide init zsh)"

# if [[ ! -f "$XDG_CONFIG_HOME/zoxide/config.toml" ]]; then
#   echo "Linking zoxide config..."
#   ln -sf "$DOTFILES/config/zoxide/config.toml" "$XDG_CONFIG_HOME/zoxide/config.toml"
# fi

# ========================================================================
# atuin
# ========================================================================

# https://docs.atuin.sh/configuration/config/
export ATUIN_CONFIG_DIR="$cf/atuin"
alias at="atuin"

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
# zellij
# ========================================================================

export ZELLIJ_CONFIG_DIR="$cf/zellij"

# Zellij (auto-start on startup)
# has_command zellij && eval "$(zellij setup --generate-auto-start zsh)"

# zellij issue with Yazi (image preview) - https://yazi-rs.github.io/docs/image-preview#zellij
TERM=xterm-kitty yazi

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
# Set up fzf key bindings and fuzzy completion
source <(fzf --zsh)
# TODO
# has_command fzf && source <(fzf --zsh)
# Load FZF completions
# [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

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

# # Installation check and setup
# if ! has_command rustup; then
# 	log_info "Installing Rust via rustup..."
# 	curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
# 	[[ -f "$CARGO_HOME/env" ]] && source "$CARGO_HOME/env"
# fi

#

# # Add cargo bin to PATH if not already there
# if [[ -d "$CARGO_HOME/bin" ]]; then
# 	path_add "$CARGO_HOME/bin"
# fi

# ========================================================================
# claude
# ========================================================================

#
# if [[ ! -f "$XDG_CONFIG_HOME/claude/config.json" ]]; then
#   echo "Linking claude config..."
#   ln -sf "$DOTFILES/config/claude/config.json" "$XDG_CONFIG_HOME/claude/config.json"
# fi
#

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
# Tool Initialization
# ========================================================================

# Initialize tools only if they are installed
has_command starship && eval "$(starship init zsh)"
has_command direnv && eval "$(direnv hook zsh)"
# has_command fnm && eval "$(fnm env --use-on-cd)"
has_command volta && eval "$(volta setup)"
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

# # ========================================================================
# # Dotfiles Symlink Map Configuration
# # ========================================================================
#
# # This defines the mapping between dotfiles source locations and their
# # target locations in the user's home directory. It's used by the installation
# # script and other dotfiles management tools.
#
# declare -gA LINKMAP=(
# 	#   # Git configurations
# 	#   # ["$DOTFILES/config/git/config"]="$XDG_CONFIG_HOME/.gitconfig"
# 	#   # ["$DOTFILES/config/git/ignore"]="$XDG_CONFIG_HOME/git/.gitignore"
# 	#   # ["$DOTFILES/config/git/gitattributes"]="$HOME/.gitattributes"
# 	#   # ["$DOTFILES/config/git/gitmessage"]="$HOME/.gitmessage"
#
# 	#   # ["$DOTFILES/config/starship.toml"]="$XDG_CONFIG_HOME/starship.toml"
# 	#   # ["$DOTFILES/config/ghostty/config"]="$XDG_CONFIG_HOME/ghostty"
# 	#   # ["$DOTFILES/config/atuin/config.toml"]="$XDG_CONFIG_HOME/atuin/config.toml"
# 	#   # ["$DOTFILES/config/lazygit/config.yml"]="$XDG_CONFIG_HOME/lazygit/config.yml"
# 	#   ["$DOTFILES/config/karabiner/karabiner.json"]="$XDG_CONFIG_HOME/karabiner/karabiner.json"
#
# 	#   # Editor configurations
# 	#   ["$DOTFILES/config/vscode/settings.json"]="$HOME/Library/Application Support/Code/User/settings.json"
# 	#   ["$DOTFILES/config/vscode/keybindings.json"]="$HOME/Library/Application Support/Code/User/keybindings.json"
# 	#   ["$DOTFILES/config/cursor/settings.json"]="$HOME/Library/Application Support/Cursor/User/settings.json"
# 	#   ["$DOTFILES/config/cursor/keybindings.json"]="$HOME/Library/Application Support/Cursor/User/keybindings.json"
#
# 	#   # ["$DOTFILES/config/yazi"]="$XDG_CONFIG_HOME/yazi"
# 	#   # ["$DOTFILES/config/nvim"]="$XDG_CONFIG_HOME/nvim"
# 	#   # ["$DOTFILES/config/bat"]="$XDG_CONFIG_HOME/bat"
# 	#   # ["$DOTFILES/config/zellij"]="$XDG_CONFIG_HOME/zellij"
# 	#   # ["$DOTFILES/config/zed"]="$XDG_CONFIG_HOME/zed"
# 	#   # ["$DOTFILES/config/espanso"]="$XDG_CONFIG_HOME/espanso"
# 	#   # ["$DOTFILES/config/warp/keybindings.yaml"]="$XDG_CONFIG_HOME/warp/keybindings.yaml"
#
# 	#   # ["$DOTFILES/config/hammerspoon"]="$HOME/.hammerspoon"
#
# 	#   # AI tools configurations
#
# 	#   # ["$DOTFILES/config/ai/claude/claude_desktop_config.json"]="$HOME/Library/Application Support/Claude/claude_desktop_config.json"
# 	#   # ["$DOTFILES/config/ai/cline/cline_mcp_settings.json"]="$HOME/Library/Application Support/Cursor/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json"
# )
#
# # # Export the map for use in other scripts
# export LINKMAP
#
# # # Initialize dotfiles - ensure essential symlinks exist
# # # This is a lightweight version of setup_cli_tools from install.zsh
# # # that won't disrupt the user's shell experience
# # dotfiles_init() {
# #   # Only run in interactive shells to avoid slowing down scripts
# #   if [[ -o interactive ]]; then
# #     # Create missing symlinks silently
# #     for key in ${(k)DOTFILES_TO_SYMLINK_MAP}; do
# #       local src="$key"
# #       local dst="${DOTFILES_TO_SYMLINK_MAP[$key]}"
#
# #       # Only create symlink if source exists and destination doesn't
# #       if [[ -e "$src" ]] && [[ ! -e "$dst" ]]; then
# #         local parent_dir=$(dirname "$dst")
#
# #         # Create parent directory if needed
# #         [[ ! -d "$parent_dir" ]] && mkdir -p "$parent_dir"
#
# #         # Create the symlink
# #         echo "Creating symlink: $dst -> $src"
# #         ln -sf "$src" "$dst"
# #       fi
# #     done
# #   fi
# # }
#
# # ========================================================================
# # postgresql@17
# # ========================================================================
# # postgresql@17 is keg-only, which means it was not symlinked into /opt/homebrew,
# # because this is an alternate version of another formula.
# #
# # If you need to have postgresql@17 first in your PATH, run:
# #   echo 'export PATH="/opt/homebrew/opt/postgresql@17/bin:$PATH"' >> /Users/hank/.config/zsh/.zshrc
# #
# # For compilers to find postgresql@17 you may need to set:
# #   export LDFLAGS="-L/opt/homebrew/opt/postgresql@17/lib"
# #   export CPPFLAGS="-I/opt/homebrew/opt/postgresql@17/include"
# #
# # To start postgresql@17 now and restart at login:
# #   brew services start postgresql@17
# # Or, if you don't want/need a background service you can just run:
# #   LC_ALL="C" /opt/homebrew/opt/postgresql@17/bin/postgres -D /opt/homebrew/var/postgresql@17
#
# # export PATH="/opt/homebrew/opt/postgresql@17/bin:$PATH"
# path_add "/opt/homebrew/opt/postgresql@17/bin"
#
# export LDFLAGS="-L/opt/homebrew/opt/postgresql@17/lib"
# export CPPFLAGS="-I/opt/homebrew/opt/postgresql@17/include"
#
# # [ -f "/Users/hank/.ghcup/env" ] && . "/Users/hank/.ghcup/env" # ghcup-env
