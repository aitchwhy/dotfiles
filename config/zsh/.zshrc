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
setopt AUTO_CD           # Change directory without cd
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
# Editor & Terminal Settings
# ========================================================================

# Default editor
export EDITOR="nvim"
export VISUAL="$EDITOR"
# export PAGER="less -FRX"

# Terminal settings
export COLORTERM=truecolor
export TERM_PROGRAM="${TERM_PROGRAM:-Apple_Terminal}"

# ========================================================================
# Keyboard & Input Configuration
# ========================================================================

# Vi Mode
# bindkey -v
export KEYTIMEOUT=1

# Basic key bindings
# bindkey '^P' up-line-or-history
# bindkey '^N' down-line-or-history
# bindkey '^E' end-of-line
# bindkey '^A' beginning-of-line
# bindkey '^K' up-line-or-history
# bindkey '^J' down-line-or-history
# bindkey '^L' end-of-line
# bindkey '^H' beginning-of-line
# bindkey '^R' history-incremental-search-backward
# bindkey '^?' backward-delete-char # Backspace working after vi mode

# ========================================================================
# Source Utility Functions
# ========================================================================

# This file contains the main utility functions and environment variables
[[ -f "$ZDOTDIR/utils.zsh" ]] && source "$ZDOTDIR/utils.zsh"

# Run the initialization
dotfiles_init
# ========================================================================
# Module Loading
# ========================================================================

# Load configuration files in specific order, installing required tools if needed
local files=(
  "$ZDOTDIR/brew.zsh" # Homebrew package management
  # "$ZDOTDIR/git.zsh"      # Git utilities and configurations
  # "$ZDOTDIR/nodejs.zsh"   # Node.js development
  "$ZDOTDIR/go.zsh"     # Go development
  "$ZDOTDIR/python.zsh" # Python development
  "$ZDOTDIR/rust.zsh"   # Rust development
  # "$ZDOTDIR/atuin.zsh"    # Atuin shell history
  "$ZDOTDIR/fzf.zsh"      # Fuzzy finder configuration
  "$ZDOTDIR/nvim.zsh"     # Neovim editor configuration
  "$ZDOTDIR/starship.zsh" # starship prompt
  "$ZDOTDIR/fd.zsh"       # starship prompt
)

# Define installation commands for tools as an associative array
declare -A TOOL_INSTALL_COMMANDS=(
  [brew]="/bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
  [starship]="curl -sS https://starship.rs/install.sh | sh"
  [atuin]="curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh"
  [volta]="curl https://get.volta.sh | bash"
  [uv]="curl -LsSf https://astral.sh/uv/install.sh | sh"
  [rustup]="curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
  [fzf]="brew install fzf"
  [eza]="brew install eza"
  [go]="brew install go"
  [nvim]="brew install neovim"
  [zoxide]="brew install zoxide"
  [fd]="brew install fd"
)

# Define which tools are essential (will always be installed if missing)
declare -A TOOL_IS_ESSENTIAL=(
  [brew]=true
  [starship]=true
  [git]=true
  [atuin]=true
  [volta]=true
  [uv]=true
  [rustup]=true
  [fzf]=true
  [eza]=rtrue
  [go]=true
  [nvim]=true
  [zoxide]=true
)

# Install tools in order of importance
local tool_names=(brew starship git atuin volta uv rustup fzf eza go nvim zoxide)
for tool_name in "${tool_names[@]}"; do
  local install_cmd="${TOOL_INSTALL_COMMANDS[$tool_name]}"
  local is_essential="${TOOL_IS_ESSENTIAL[$tool_name]}"
  ensure_tool_installed "$tool_name" "$install_cmd" "$is_essential"
done

# Source individual configuration modules
for file in $files; do
  [[ -f "$file" ]] && source "$file"
done

# Special case for Homebrew PATH
if has_command "brew"; then
  if is_apple_silicon; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  else
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

# # Special cases for tools that need post-installation configuration
# if ! has_command "atuin" && [[ ! -f "$XDG_DATA_HOME/atuin/.initialized" ]]; then
#   # Only run first-time setup if atuin was just installed
#   log_info "First-time Atuin setup: importing shell history"
#   atuin import auto
#   atuin sync -f
#   touch "$XDG_DATA_HOME/atuin/.initialized"
# fi

# if has_command "volta" && [[ ! -d "$HOME/.volta/bin/node" ]]; then
#   log_info "Installing Node.js via Volta"
#   volta install node
# fi

# ========================================================================
# Completions
# ========================================================================

# Completions setup
# if type brew &>/dev/null; then
# 	FPATH=$(brew --prefix)/share/zsh-abbr:$FPATH
# 	autoload -Uz compinit
# 	compinit
# fi

# Initialize the completion system
# Completions setup
# if type brew &>/dev/null; then
#   FPATH=$(brew --prefix)/share/zsh-abbr:$FPATH
#   autoload -Uz compinit
#   compinit
# else
autoload -Uz compinit
compinit
# fi

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

# ========================================================================
# Tool Initialization
# ========================================================================

# Initialize tools only if they are installed
has_command starship && eval "$(starship init zsh)"
has_command atuin && eval "$(atuin init zsh)"
has_command zoxide && eval "$(zoxide init zsh)"
has_command direnv && eval "$(direnv hook zsh)"
has_command fnm && eval "$(fnm env --use-on-cd)"
# has_command volta && eval "$(volta setup)"
has_command uv && eval "$(uv generate-shell-completion zsh)"
has_command uvx && eval "$(uvx --generate-shell-completion zsh)"
# has_command pyenv && eval "$(pyenv init -)"
# has_command abbr && eval "$(abbr init zsh)"

# Load FZF completions
has_command fzf && source <(fzf --zsh)

# ========================================================================
# ZSH aliases - Organized by category
# ========================================================================

# Navigation Shortcuts
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias home="cd ~"

# List Files - Prioritize eza/exa with fallback to ls
if has_command eza; then
  alias ls="eza --icons --group-directories-first"
  alias ll="eza --icons --group-directories-first -la"
  alias la="eza --icons --group-directories-first -a"
  alias lt="eza --icons --group-directories-first --tree"
  alias lt2="eza --icons --group-directories-first --tree --level=2"
else
  alias ls="ls -G"
  alias ll="ls -la"
  alias la="ls -a"
fi

# ========================================================================
# Networking Utilities
# ========================================================================
alias ip="ipconfig getifaddr en0"
alias localip="ipconfig getifaddr en0"
alias publicip="curl -s https://api.ipify.org"
alias ports="sudo lsof -i -P -n | grep LISTEN"
alias flush="dscacheutil -flushcache && killall -HUP mDNSResponder" # Flush DNS

# ========================================================================
# Dotfiles Management
# ========================================================================
alias cdz='cd $ZDOTDIR'
alias cdd="cd $DOTFILES"
alias zr="exec zsh"
alias ze="fd --hidden . $ZDOTDIR | xargs nvim"
alias dot="fd --hidden . $DOTFILES | xargs nvim"

# ========================================================================
# System Information
# ========================================================================
alias ppath='echo $PATH | tr ":" "\n"'
alias pfuncs='print -l ${(k)functions[(I)[^_]*]} | sort'
alias pfpath='for fp in $fpath; do echo $fp; done; unset fp'
alias printpath='ppath'
alias printfuncs='pfuncs'
alias printfpath='pfpath'

# Keep commonly used aliases for convenience
alias penv='sys env'
alias ql='sys ql'
alias batman='sys man'

# ========================================================================
# Misc Shortcuts
# ========================================================================
alias c="clear"
alias hf="huggingface-cli"
alias lg="lazygit"

# ========================================================================
# Local Environment
# ========================================================================

# Load local environment variables if they exist
# [[ -f "$HOME/.local/state/env" ]] && . "$HOME/.local/state/env"

# # Configure Atuin path if it exists
# # Note: This should eventually be moved to atuin.zsh
# if [[ -f "$HOME/.atuin/bin/env" ]]; then
#   # Define the path variable to be used by other scripts
#   export ATUIN_BIN_PATH="$HOME/.atuin/bin"

#   # Only source if not already initialized
#   if ! has_command atuin; then
#     . "$HOME/.atuin/bin/env"
#   fi
# fi

# The actual initialization happens in .zshrc via:
# has_command atuin && eval "$(atuin init zsh)"
. "$HOME/.local/bin/env"

. "$HOME/.local/share/../bin/env"
