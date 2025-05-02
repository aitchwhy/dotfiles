
# ========================================================================

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
# 1. Core Shell Options
# ========================================================================

# Navigation Options
# setopt AUTO_CD           # Change directory without cd
setopt AUTO_PUSHD        # Push directory to stack on cd
setopt PUSHD_IGNORE_DUPS # Don't store duplicates in stack
setopt PUSHD_SILENT      # Don't print stack after pushd/popd

# Globbing and Pattern Matching
unsetopt EXTENDED_GLOB # No Extended globbing (no need for double quotes for nix flakes pkg#target due to hashtag needing escape)
setopt NO_NOMATCH      # Don't error on no matches
setopt NO_CASE_GLOB    # Case insensitive globbing

# Misc Options
setopt INTERACTIVE_COMMENTS # Allow comments in interactive shells

# History Options
setopt EXTENDED_HISTORY # Record timestamp

setopt HIST_EXPIRE_DUPS_FIRST # Delete duplicates first
setopt HIST_IGNORE_DUPS       # Don't record duplicates
setopt HIST_VERIFY            # Don't execute immediately upon history expansion
setopt SHARE_HISTORY          # Share history between sessions
setopt HIST_IGNORE_SPACE      # Don't record commands starting with space

# Keep your zsh history file (can re-use in Nix shell)
export HISTFILE="$HOME/.zsh_history"
export HISTSIZE=100000
export SAVEHIST=${HISTSIZE}

# ========================================================================
# 2. XDG Base Directory Specification
# ========================================================================

export DOTFILES="${DOTFILES:-$HOME/dotfiles}"
# export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$DOTFILES/config}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# Ensure XDG directories exist
[[ ! -d "$XDG_CONFIG_HOME" ]] && mkdir -p "$XDG_CONFIG_HOME"
[[ ! -d "$XDG_CACHE_HOME" ]] && mkdir -p "$XDG_CACHE_HOME"
[[ ! -d "$XDG_DATA_HOME" ]] && mkdir -p "$XDG_DATA_HOME"
[[ ! -d "$XDG_STATE_HOME" ]] && mkdir -p "$XDG_STATE_HOME"

# Ensure ZSH config directory is set
export zdot=${ZDOTDIR:-$XDG_CONFIG_HOME/zsh}
export cf="$HOME/dotfiles/config"
export dot="$DOTFILES"
export cfz="$HOME/dotfiles/config/zsh"


# ========================================================================
# 3. Keyboard & Input Configuration
# ========================================================================

bindkey -v
export KEYTIMEOUT=1

# ========================================================================
# 4. Utility Functions
# ========================================================================

# Source our utility functions from utils.zsh
export UTILS="$DOTFILES/config/zsh/utils.zsh"
[[ -f "$UTILS" ]] && source "$UTILS"

# Check if a command exists
function has_command() {
	command -v "$1" &>/dev/null
}

# ========================================================================
# 5. Homebrew and PATH Setup
# ========================================================================

# Set up Homebrew
export HOMEBREW_PREFIX="${HOMEBREW_PREFIX:-$(brew --prefix 2>/dev/null)}"
export bpre="$HOMEBREW_PREFIX"


# ========================================================================
# 6. Core Tools Setup
# ========================================================================

# --- Editor ---
export EDITOR="nvim"
export VISUAL="$EDITOR"

if ! has_command nvim; then
	echo "nvim not found. Installing nvim..."
	brew install --quiet neovim
fi

# ========================================================================
# 7. Completions & Plugin Framework
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
		if [[ -f "$plugin_path" ]]; then
			source "$plugin_path"
		fi
	done
fi

# Completions setup
FPATH="$HOMEBREW_PREFIX/share/zsh/site-functions:$FPATH"

autoload -Uz compinit
compinit


# ========================================================================
# Nix
# ========================================================================
alias nix-zsh="nix develop --command zsh"
source "${cf:-$HOME/dotfiles/config}/zsh/anterior.zsh}" 2>/dev/null

# --- Nix ---
# export NIX_CONFIG_DIR="$cf/nix"

# ========================================================================
# Source Nix environment
# ========================================================================
if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
  source '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
fi

# Add Nix to path
export PATH=$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$PATH

# Nix completions for ZSH
if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
  # Add Nix ZSH completion if available
  if [ -e "${HOME}/.nix-profile/share/zsh/site-functions/_nix" ]; then
    fpath+=(~/.nix-profile/share/zsh/site-functions)
  elif [ -e '/nix/var/nix/profiles/default/share/zsh/site-functions/_nix' ]; then
    fpath+=(/nix/var/nix/profiles/default/share/zsh/site-functions)
  fi
  
  # Initialize ZSH completion system
  autoload -U compinit && compinit
fi


alias nixe="$EDITOR ~/.config/nix/nix.conf"
alias nixd="nix develop"
alias nixdn="nix develope .#npm"
alias antall="ant-all-services api user s3 prefect-worker prefect-agent prefect-server data-seeder"
alias antnoggin="ant-all-services noggin"
alias antnpm="npm ci --ignore-scripts && ant-npm-build-deptree noggin && npm run --workspace gateways/noggin build"

################
# Direnv
################
alias dotx="dotenvx"
alias dx="dotenvx"



################
# Direnv
################
if command -v direnv &> /dev/null; then
  eval "$(direnv hook zsh)"
fi

################
# Process compose (~ Docker Compose)
################
alias pc="process-compose"

# ========================================================================
# 8. Tool/Package Configurations
# ========================================================================

# --- Git ---
export GIT_CONFIG_GLOBAL="$cf/git/gitconfig"
export LG_CONFIG_FILE="$cf/lazygit/config.yml"

# --- Starship ---
export STARSHIP_CONFIG="$cf/starship/starship.toml"
has_command starship && eval "$(starship init zsh)"

# --- Ghostty ---
if ! has_command ghostty; then
	echo "ghostty not found. Installing ghostty..."
	brew install --quiet ghostty
fi

# --- Zoxide ---
has_command zoxide && eval "$(zoxide init zsh)"


# --- FZF ---
has_command fzf && source <(fzf --zsh)


# --- Atuin ---
export ATUIN_CONFIG_DIR="$cf/atuin"
local ATUIN_ENV_CMD="$HOME/.atuin/bin/env"
[[ -f $ATUIN_ENV_CMD ]] && . $ATUIN_ENV_CMD
has_command atuin && eval "$(atuin init zsh)"

# --- Zellij ---
export ZELLIJ_CONFIG_DIR="$cf/zellij"
# Uncomment to auto-start zellij
# has_command zellij && eval "$(zellij setup --generate-auto-start zsh)"

# --- Yazi ---
export YAZI_CONFIG_DIR="$cf/yazi"
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

# --- Bat ---
has_command bat && export PAGER="bat --pager always"

# --- Rust ---
export CARGO_HOME="${CARGO_HOME:-$HOME/.cargo}"
export RUSTUP_HOME="${RUSTUP_HOME:-$HOME/.rustup}"
path_add "$HOME/.cargo/bin"

# --- Node/Volta ---
export VOLTA_HOME="$HOME/.volta"
has_command volta && path_add "$VOLTA_HOME/bin"
has_command volta && eval "$(volta setup)"

# --- Go ---
export GOPATH="$HOME/go"
export GOBIN="$GOPATH/bin"
path_add "$GOBIN"

# --- Direnv ---
has_command direnv && eval "$(direnv hook zsh)"

# --- uv ---
has_command uv && eval "$(uv generate-shell-completion zsh)"

# --- TODO: aerospace (window tiling manager)

# has_command aerospace && 
alias aero=aerospace


# --- TODO: skhd (keyboard shortcuts hotkey daemon)

# ========================================================================
# 9. Aliases (grouped by tool)
# ========================================================================

# --- Nix ---
alias nixh='nix --help'
alias nixf="$EDITOR $cf/nix/nix.conf"
alias nixgc="nix-collect-garbage -d"
alias nixpkgs="nix search"
alias nixsh="nix-shell --run zsh"
alias nixdev="nix develop"
alias nixf="nix flake"
alias nixup="sudo nixos-rebuild switch"
alias nixdarwinup="darwin-rebuild switch --flake ~/dotfiles"

# --- Homebrew ---
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

# --- File System (eza, fd) ---
alias cf='cd ~/.config/'
alias dl='cd ~/Downloads'
alias ls='exa --git --icons'                             # system: List filenames on one line
alias l='exa --git --icons -lF'                          # system: List filenames with long format
alias ll='exa -lahF --git'                               # system: List all files
alias lll="exa -1F --git --icons"                        # system: List files with one line per file
alias llm='ll --sort=modified'                           # system: List files by last modified date
alias la='exa -lbhHigUmuSa --color-scale --git --icons'  # system: List files with attributes
alias lx='exa -lbhHigUmuSa@ --color-scale --git --icons' # system: List files with extended attributes
alias lt='exa --tree --level=2'                          # system: List files in a tree view
alias llt='exa -lahF --tree --level=2'                   # system: List files in a tree view with long format
alias ltt='exa -lahF | grep "$(date +"%d %b")"'          # system: List files modified today

# --- Text Editors (nvim) ---
alias v='$EDITOR'
alias vi='$EDITOR'
alias vim='$EDITOR'

# --- Zsh ---
alias zr="exec zsh"
alias ze="nvim '$ZDOTDIR'/{.zshrc,.zprofile,.zshenv}"
alias zeall="nvim '$ZDOTDIR'/{.zshrc,.zprofile,.zshenv,*.zsh}"
alias zcompreset="rm -f ~/.zcompdump; compinit"

# --- System Information & Utilities ---
alias ports="sudo lsof -i -P -n | grep LISTEN"
alias sudoports="sudo lsof -i -P -n | grep LISTEN"
alias printpath='echo $PATH | tr ":" "\n"'
alias printfuncs='print -l ${(k)functions[(I)[^_]*]} | sort'
alias printfpath='for fp in $fpath; do echo $fp; done; unset fp'

alias ip="ipconfig getifaddr en0"
alias localip="ipconfig getifaddr en0"
alias publicip="curl -s https://api.ipify.org"
alias flush="dscacheutil -flushcache && killall -HUP mDNSResponder"
alias flushdns="sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder"
alias showhidden="defaults write com.apple.finder AppleShowAllFiles YES; killall Finder"

# --- Git & Lazygit ---
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

# --- Modern CLI Alternatives ---
alias ps='procs'                # procs - process viewer
alias ping='gping'              # gping - ping with graph
alias diff='delta'              # delta - better diff
alias cat='bat --paging=always' # bat - better cat
alias miller='mlr'              # miller - CSV processor
alias grep='rg'                 # ripgrep - better grep
alias find='fd'                 # fd - better find
alias md='glow'                 # glow - markdown viewer
alias net='trippy'              # trippy - traceroute
alias netviz='netop'            # netop - network visualization
alias jwt='jet-ui'              # jet-ui - JWT debugger
alias sed='sd'                  # sd - better sed
alias du='dust'                 # dust - better du
alias csv='xsv'                 # xsv - CSV processor
alias jsonfilter='jsonf'        # jsonf - JSON filter
alias jsonviewer='jsonv'        # jsonv - JSON viewer

# --- Docker & Kubernetes ---
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
alias k='k9s'         # k9s - Kubernetes CLI
alias ld="lazydocker" # lazydocker - Docker TUI

# --- Just Task Runner ---
alias j="just"
alias jfmt="just --unstable --fmt"
alias .j='just --justfile $USER_JUSTFILE --working-directory .'
alias .jfmt='just --justfile $USER_JUSTFILE --working-directory . --unstable --fmt'

# --- FZF Enhanced Commands ---
alias flog='fzf --preview "bat --style=numbers --color=always --line-range=:500 {}"'
alias falias='alias | fzf'
alias fman='man -k . | fzf --preview "man {}"'
alias fls='man -k . | fzf --preview "man {}"'

# --- Terminal Multiplexers ---
# Ghostty
alias g='ghostty'

# Zellij
alias zj="zellij"
alias zjls="zellij list-sessions"
alias zja='zellij attach "$(zellij list-sessions -n | fzf --reverse --border --no-sort --height 40% | awk '\''{print $1}'\'')"'
alias zje="zellij edit"

# --- Other Tools ---
# TLDR/Cheat sheets
alias cheat="tldr"
alias ch="cheat"

# Claude
alias claude="/Users/hank/.claude/local/claude"

# Tailscale
alias ts="tailscale"

# Hugging Face
alias hf="huggingface-cli"

# Repomix
alias rx="repomix"

# Atuin
alias at="atuin"


# anterior
alias aall="ant-all-services"
alias aprune="ant-system-prune"

alias antnpmci="npm ci --ignore-scripts"
alias antnpmbuild="ant-npm-build-deptree SERVICE_NAME"
alias antnpmrun="npm run --workspace your/dir build"




# [[general commands]]
#
#   ant-check-1password - Check that your 1password CLI integration is set up correctly
#   menu                - prints this menu
#
# [build]
#
#   ant-build-docker    - Build and load Docker images for every Nix service
#   ant-build-host      - Build everything but don't start nor load into Docker
#   ant-lint            - Lint Go & Python code in your working directory
#   ant-sync-cache      - Synchronize your local cache with our CI cache.  Requires 1password.
#
# [maintenance]
#
#   system-prune        - Prune build cache for Docker & Nix
#
# [run]
#
#   ant-admin           - Anterior admin tool (/admin)
#   ant-all-services    - Run all services locally (pass --help for more)
#
# [anterior]$ ant-build-docker
# #

# ========================================================================
# 10. Source Custom Files
# ========================================================================

# Source aliases and functions
[[ -f "${ZDOTDIR}/aliases.zsh" ]] && source "${ZDOTDIR}/aliases.zsh"
[[ -f "${ZDOTDIR}/functions.zsh" ]] && source "${ZDOTDIR}/functions.zsh"


# ========================================================================
# COMMENTED SECTIONS (Future Reference)
# ========================================================================

# --- PostgreSQL Configuration ---
# path_add "/opt/homebrew/opt/postgresql@17/bin"
# export LDFLAGS="-L/opt/homebrew/opt/postgresql@17/lib"
# export CPPFLAGS="-I/opt/homebrew/opt/postgresql@17/include"

# --- NPM Global Configuration ---
# mkdir -p ~/.npm-global
# path_add "$HOME/.npm-global/bin"
# npm config set prefix ~/.npm-global
#

# --- Notes for Global Package Installation ---
# TODO: add github extensions list
# - gh extension install dlvhdr/gh-dash
# TODO: add nodejs global packages (bun + etc)
# TODO: add uv global packages
# gpt-repository-loader, llm, mitmproxy2swagger, poetry, prefect, etc.
# repomix

# --- Dotfiles Symlink Configuration ---
# Future work: Create a LINKMAP array to manage dotfile symlinks

[ -f "/Users/hank/.ghcup/env" ] && . "/Users/hank/.ghcup/env" # ghcup-env
