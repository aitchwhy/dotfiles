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
# XDG Base Directory Specification
# ========================================================================

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
# export XDG_BIN_HOME="${XDG_BIN_HOME:-$HOME/.local/bin}"

# Ensure ZSH config directory is set
# export ZDOTDIR=${ZDOTDIR:-$XDG_CONFIG_HOME/zsh}
export ZDOTDIR=:"$XDG_CONFIG_HOME/zsh"

# Dotfiles location
# export DOTFILES="${DOTFILES:-$HOME/dotfiles}"
export DOTFILES="$HOME/dotfiles"

# Ensure XDG directories exist
# if [[ ! -d "$XDG_DATA_HOME" ]]; then mkdir -p "$XDG_DATA_HOME"; fi
# if [[ ! -d "$XDG_CONFIG_HOME" ]]; then mkdir -p "$XDG_CONFIG_HOME"; fi
# if [[ ! -d "$XDG_STATE_HOME" ]]; then mkdir -p "$XDG_STATE_HOME"; fi
# if [[ ! -d "$XDG_CACHE_HOME" ]]; then mkdir -p "$XDG_CACHE_HOME"; fi
# if [[ ! -d "$XDG_BIN_HOME" ]]; then mkdir -p "$XDG_BIN_HOME"; fi
[[ ! -d "$XDG_DATA_HOME" ]] && mkdir -p "$XDG_DATA_HOME"
[[ ! -d "$XDG_CONFIG_HOME" ]] && mkdir -p "$XDG_CONFIG_HOME"
[[ ! -d "$XDG_STATE_HOME" ]] && mkdir -p "$XDG_STATE_HOME"
[[ ! -d "$XDG_CACHE_HOME" ]] && mkdir -p "$XDG_CACHE_HOME"
[[ ! -d "$XDG_BIN_HOME" ]] && mkdir -p "$XDG_BIN_HOME"

# ========================================================================
# Keyboard & Input Configuration
# ========================================================================

# Vi Mode
# bindkey -v
export KEYTIMEOUT=1

# Basic key bindings
bindkey '^P' up-line-or-history
bindkey '^N' down-line-or-history
bindkey '^E' end-of-line
bindkey '^A' beginning-of-line

# ========================================================================
# Source Utility Functions
# ========================================================================

# Source our utility functions from utils.zsh
export UTILS_PATH="$DOTFILES/config/zsh/utils.zsh"
if [[ -f "$UTILS_PATH" ]]; then
  source "$UTILS_PATH"
  log_success "Successfully loaded utils.zsh with $(functions | grep -c "^[a-z].*() {") utility functions"

  # List some key utility functions that should be available
  log_info "Available utility functions include: has_command, is_macos, path_add, sys, etc."
else
  echo "Error: $UTILS_PATH not found. Some functionality will be unavailable."
fi

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

# # Add prioritized paths
# path=(
#   # Version managers (need to be before Homebrew)
#   $HOME/.volta/bin # Node.js version manager

#   # Other language-specific paths
#   $HOME/.cargo/bin # Rust
#   $HOME/go/bin     # Go

#   # # System paths
#   # "$HOME/.local/bin" # User local binaries
#   # "$HOME/bin"        # User personal binaries
# )
# export PATH

# # user compiled python as default python
# export PATH=$HOME/python/bin:$PATH
# export PYTHONPATH=$HOME/python/
#
# # user installed node as default node
# export PATH="$HOME/node/node-v16.0.0-${KERNEL_NAME}-x64"/bin:$PATH
# export NODE_MIRROR=https://mirrors.ustc.edu.cn/node/

# ========================================================================
# Dotfiles Symlink Map Configuration
# ========================================================================

# This defines the mapping between dotfiles source locations and their
# target locations in the user's home directory. It's used by the installation
# script and other dotfiles management tools.

# declare -gA DOTFILES_TO_SYMLINK_MAP=(
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
# )

# # Export the map for use in other scripts
# export DOTFILES_TO_SYMLINK_MAP

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
# git
# ========================================================================

if ! has_command git; then
  echo "git not found. Installing git..."
  brew install --quiet git
fi

if ! has_command lazygit; then
  echo "lazygit not found. Installing lazygit..."
  brew install --quiet lazygit
fi

export GIT_EDITOR="nvim"
export GIT_PAGER="bat --pager"
export GIT_AUTHOR_NAME="Hank"
export GIT_AUTHOR_EMAIL="hank.lee.qed@gmail.com"
export GIT_COMMITTER_NAME="Hank"
export GIT_COMMITTER_EMAIL="hank.lee.qed@gmail.com"

if [[ ! -f "$XDG_CONFIG_HOME/.gitconfig" ]]; then
  echo "Linking gitconfig..."
  ln -sf "$DOTFILES/config/git/config" "$XDG_CONFIG_HOME/.gitconfig"
fi

if [[ ! -f "$XDG_CONFIG_HOME/.gitignore" ]]; then
  echo "Linking gitignore..."
  ln -sf "$DOTFILES/config/git/ignore" "$XDG_CONFIG_HOME/.gitignore"
fi

# lazygit config link
if [[ ! -f "$XDG_CONFIG_HOME/lazygit/config.yml" ]]; then
  echo "Linking lazygit config..."
  ln -sf "$DOTFILES/config/lazygit/config.yml" "$XDG_CONFIG_HOME/lazygit/config.yml"
fi

# ========================================================================
# starship
# ========================================================================

if ! has_command starship; then
  echo "starship not found. Installing starship..."
  curl -sS https://starship.rs/install.sh | sh
fi

if [[ ! -f "$XDG_CONFIG_HOME/starship.toml" ]]; then
  echo "Linking starship.toml..."
  ln -sf "$DOTFILES/config/starship.toml" "$XDG_CONFIG_HOME/starship.toml"
fi

# ========================================================================
# ghostty
# ========================================================================
if ! has_command ghostty; then
  echo "ghostty not found. Installing ghostty..."
  brew install --quiet ghostty
fi

if [[ ! -f "$XDG_CONFIG_HOME/ghostty/config" ]]; then
  echo "Linking ghostty config..."
  ln -sf "$DOTFILES/config/ghostty/config" "$XDG_CONFIG_HOME/ghostty/config"
fi

# ========================================================================
# zoxide
# ========================================================================
if ! has_command zoxide; then
  echo "zoxide not found. Installing zoxide..."
  brew install --quiet zoxide
fi

if [[ ! -f "$XDG_CONFIG_HOME/zoxide/config.toml" ]]; then
  echo "Linking zoxide config..."
  ln -sf "$DOTFILES/config/zoxide/config.toml" "$XDG_CONFIG_HOME/zoxide/config.toml"
fi

# ========================================================================
# atuin
# ========================================================================

if ! has_command atuin; then
  echo "atuin not found. Installing atuin..."
  curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh
fi

if [[ ! -f "$XDG_CONFIG_HOME/atuin/config.toml" ]]; then
  echo "Linking atuin config..."
  ln -sf "$DOTFILES/config/atuin/config.toml" "$XDG_CONFIG_HOME/atuin/config.toml"
fi

# ========================================================================
# warp
# ========================================================================

if ! has_command warp; then
  echo "warp not found. Installing warp..."
  brew install --quiet warp
fi

if [[ ! -f "$XDG_CONFIG_HOME/warp/keybindings.yaml" ]]; then
  echo "Linking warp keybindings..."
  ln -sf "$DOTFILES/config/warp/keybindings.yaml" "$XDG_CONFIG_HOME/warp/keybindings.yaml"
fi

# ========================================================================
# claude
# ========================================================================

if ! has_command claude; then
  echo "claude not found. Installing claude..."
  brew install --quiet claude
fi

if [[ ! -f "$XDG_CONFIG_HOME/claude/config.json" ]]; then
  echo "Linking claude config..."
  ln -sf "$DOTFILES/config/claude/config.json" "$XDG_CONFIG_HOME/claude/config.json"
fi

# ========================================================================
# chatgpt
# ========================================================================

if ! has_command chatgpt; then
  echo "chatgpt not found. Installing chatgpt..."
  brew install --quiet chatgpt
fi

# ========================================================================
# bun (nodejs)
# ========================================================================

if ! has_command bun; then
  echo "Bun not found. Installing bun (nodejs)..."
  curl -fsSL https://bun.sh/install | bash # for macOS, Linux, and WSL
fi

# add to ~/.zshrc
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# ========================================================================
# nvim
# ========================================================================

if ! has_command nvim; then
  echo "nvim not found. Installing nvim..."
  brew install --quiet neovim
fi

export EDITOR="nvim"
export VISUAL="$EDITOR"

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
if ! has_command bat; then
  echo "bat not found. Installing bat..."
  brew install --quiet bat
fi

export PAGER="bat --pager"

# ========================================================================
# rust (rustup)
# ========================================================================

if ! has_command rustup; then
  echo "rustup not found. Installing rustup..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -y | sh
  echo "rustup installed"
  echo "installing stable toolchain"
  rustup toolchain install stable
  echo "installing rustfmt"
  rustup component add rustfmt
  echo "rustfmt installed"
fi

# ========================================================================
# Go
# ========================================================================
# export GOPATH="$HOME/go"
# export GOBIN="$GOPATH/bin"

# ========================================================================
#
# ========================================================================

# Load configuration files in specific order, installing required tools if needed
local files=(
  "$ZDOTDIR/brew.zsh" # Homebrew package management
  # "$ZDOTDIR/starship.zsh" # starship prompt
  "$ZDOTDIR/fzf.zsh"  # Fuzzy finder configuration
  "$ZDOTDIR/nvim.zsh" # Neovim editor configuration
  # "$ZDOTDIR/fd.zsh"  # starship prompt
  # "$ZDOTDIR/bat.zsh" # starship prompt
  # "$ZDOTDIR/git.zsh"      # Git utilities and configurations
  # "$ZDOTDIR/python.zsh" # Python development
  # "$ZDOTDIR/nodejs.zsh"   # Node.js development
  # "$ZDOTDIR/go.zsh"     # Go development
  # "$ZDOTDIR/rust.zsh"   # Rust development
  # "$ZDOTDIR/atuin.zsh"    # Atuin shell history
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
# . "$HOME/.local/bin/env"

# . "$HOME/.local/share/../bin/env"
