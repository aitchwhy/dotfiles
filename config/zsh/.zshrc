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

export DOTFILES="$HOME/dotfiles"

# Ensure ZSH config directory is set
# export ZDOTDIR=${ZDOTDIR:-$XDG_CONFIG_HOME/zsh}
export ZDOTDIR="$DOTFILES/config/zsh"

export CLOUD="~/Library/CloudStorage"
export GDRIVE="~/Library/CloudStorage/GoogleDrive-hank.lee.qed@gmail.com"
export DROPBOX="~/Library/CloudStorage/Dropbox"

# Dotfiles location
# export DOTFILES="${DOTFILES:-$HOME/dotfiles}"

# Ensure XDG directories exist
# if [[ ! -d "$XDG_DATA_HOME" ]]; then mkdir -p "$XDG_DATA_HOME"; fi
# if [[ ! -d "$XDG_CONFIG_HOME" ]]; then mkdir -p "$XDG_CONFIG_HOME"; fi
# if [[ ! -d "$XDG_STATE_HOME" ]]; then mkdir -p "$XDG_STATE_HOME"; fi
# if [[ ! -d "$XDG_CACHE_HOME" ]]; then mkdir -p "$XDG_CACHE_HOME"; fi
# if [[ ! -d "$XDG_BIN_HOME" ]]; then mkdir -p "$XDG_BIN_HOME"; fi
[[ ! -d "$XDG_CONFIG_HOME" ]] && mkdir -p "$XDG_CONFIG_HOME"
[[ ! -d "$XDG_CACHE_HOME" ]] && mkdir -p "$XDG_CACHE_HOME"
[[ ! -d "$XDG_DATA_HOME" ]] && mkdir -p "$XDG_DATA_HOME"
[[ ! -d "$XDG_STATE_HOME" ]] && mkdir -p "$XDG_STATE_HOME"
# [[ ! -d "$XDG_BIN_HOME" ]] && mkdir -p "$XDG_BIN_HOME"

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

export GIT_EDITOR="nvim"
export GIT_PAGER="bat --pager"
export GIT_AUTHOR_NAME="Hank"
export GIT_AUTHOR_EMAIL="hank.lee.qed@gmail.com"
export GIT_COMMITTER_NAME="Hank"
export GIT_COMMITTER_EMAIL="hank.lee.qed@gmail.com"

# Backup existing config if needed
[[ -f ~/.gitconfig ]] && mv ~/.gitconfig ~/.gitconfig.backup
[[ -f ~/.gitignore ]] && mv ~/.gitignore ~/.gitignore.backup

# Create symbolic link
ln -s ~/dotfiles/config/git/gitconfig ~/.gitconfig
ln -s ~/dotfiles/config/git/gitignore ~/.gitignore

if ! has_command lazygit; then
  echo "lazygit not found. Installing lazygit..."
  brew install --quiet lazygit
fi

# Lazygit custom config file location (https://github.com/jesseduffield/lazygit/blob/master/docs/Config.md#overriding-default-config-file-location)
# Dir
CONFIG_DIR="$DOTFILES/config/lazygit"
# file path
LG_CONFIG_FILE="$DOTFILES/config/lazygit/config.yml"

# if [[ ! -f "$XDG_CONFIG_HOME/lazygit/config.yml" ]]; then
#   echo "Linking lazygit config..."
#   ln -sf "$DOTFILES/config/lazygit/config.yml" "$XDG_CONFIG_HOME/lazygit/config.yml"
# fi

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

# if [[ ! -f "$XDG_CONFIG_HOME/zoxide/config.toml" ]]; then
#   echo "Linking zoxide config..."
#   ln -sf "$DOTFILES/config/zoxide/config.toml" "$XDG_CONFIG_HOME/zoxide/config.toml"
# fi

# ========================================================================
# atuin
# ========================================================================

# https://docs.atuin.sh/configuration/config/
export ATUIN_CONFIG_DIR="$DOTFILES/config/atuin/"

path_add "$HOME/.atuin/bin"

if ! has_command atuin; then
  echo "atuin not found. Installing atuin..."
  curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh
  echo "sourcing $HOME/.atuin/bin/env to add it to PATH"
  source $HOME/.atuin/bin/env
fi

if [[ ! -f "$XDG_CONFIG_HOME/atuin/config.toml" ]]; then
  echo "Linking atuin config..."
  ln -sf "$DOTFILES/config/atuin/config.toml" "$XDG_CONFIG_HOME/atuin/config.toml"
fi

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
path_add "$HOME/.local/share/../bin"

# ========================================================================
# NodeJS
# ========================================================================
# Volta
export VOLTA_HOME="$HOME/.volta"
# export PATH="$VOLTA_HOME/bin:$PATH"
path_add "$VOLTA_HOME/bin"
if ! has_command volta; then
  echo "Volta not found. Installing ..."
  brew install volta
fi

# # NVM
# export NVM_DIR="$HOME/.nvm"
# [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"                                       # This loads nvm
# [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" # This loads nvm bash_completion
# if ! has_command bun; then
#   echo "Bun not found. Installing bun (nodejs)..."
#   curl -fsSL https://bun.sh/install | bash # for macOS, Linux, and WSL
#   brew install volta
# fi

# # Bun
# export BUN_INSTALL="$HOME/.bun"
# # export PATH="$BUN_INSTALL/bin:$PATH"
# path_add "$BUN_INSTALL/bin"
# if ! has_command bun; then
#   echo "Bun not found. Installing bun (nodejs)..."
#   curl -fsSL https://bun.sh/install | bash # for macOS, Linux, and WSL
# fi

# TODO: add github extensions list
# - gh extension install dlvhdr/gh-dash
# TODO: add nodejs global packages (bun + etc)
# TODO: add uv global packages

# mkdir -p ~/.npm-global
# npm config set prefix ~/.npm-global
# path_add "~/.npm-global/bin"
# npm install -g @anthropic-ai/claude-code

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
# delta
# ========================================================================

export PAGER="bat --pager always"

if ! has_command bat; then
  echo "bat not found. Installing bat..."
  brew install --quiet bat
fi

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
#   log_info "Installing Rust via rustup..."
#   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

#   # Source the cargo environment if installed
#   if [[ -f "$CARGO_HOME/env" ]]; then
#     source "$CARGO_HOME/env"
#     log_success "Rust installed and environment loaded"
#   else
#     log_warn "Rust installation may need manual configuration"
#   fi
# fi
#

# Rust Development Environment Setup
if ! has_command rustup; then
  echo "rustup not found. Installing rustup..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
  # echo "rustup installed"
  # echo "installing stable toolchain..."
  #rustup toolchain install stable
  # echo "installing rustfmt..."
  #rustup component add rustfmt
  # echo "rustfmt installed"
fi
#

# Add cargo bin to PATH if not already there
[[ -d "$CARGO_HOME/bin" ]] && path_add "$CARGO_HOME/bin"

# Optional: Add cargo completions
# if has_command rustup; then
#   mkdir -p "$ZDOTDIR/.zfunc"
#   rustup completions zsh > "$ZDOTDIR/.zfunc/_rustup"
#   rustup completions zsh cargo > "$ZDOTDIR/.zfunc/_cargo"
# fi

# Note: For Apple Silicon Macs, the Rust toolchain is installed with native arm64 support
#
# ========================================================================
# warp
# ========================================================================

# if ! has_command warp; then
#   echo "warp not found. Installing warp..."
#   brew install --quiet warp
# fi
#
# if [[ ! -f "$XDG_CONFIG_HOME/warp/keybindings.yaml" ]]; then
#   echo "Linking warp keybindings..."
#   ln -sf "$DOTFILES/config/warp/keybindings.yaml" "$XDG_CONFIG_HOME/warp/keybindings.yaml"
# fi

# ========================================================================
# claude
# ========================================================================

# if ! has_command claude; then
#   echo "claude not found. Installing claude..."
#   brew install --quiet claude
# fi
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
# export GOPATH="$HOME/go"
# export GOBIN="$GOPATH/bin"

# ========================================================================
#
# ========================================================================

# # Define installation commands for tools as an associative array
# declare -A TOOL_INSTALL_COMMANDS=(
#   [brew]="/bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
#   [starship]="curl -sS https://starship.rs/install.sh | sh"
#   [atuin]="curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh"
#   [volta]="curl https://get.volta.sh | bash"
#   [uv]="curl -LsSf https://astral.sh/uv/install.sh | sh"
#   [rustup]="curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
#   [fzf]="brew install fzf"
#   [eza]="brew install eza"
#   [go]="brew install go"
#   [nvim]="brew install neovim"
#   [zoxide]="brew install zoxide"
#   [fd]="brew install fd"
# )
#
# # Define which tools are essential (will always be installed if missing)
# declare -A TOOL_IS_ESSENTIAL=(
#   [brew]=true
#   [starship]=true
#   [git]=true
#   [atuin]=true
#   [volta]=true
#   [uv]=true
#   [rustup]=true
#   [fzf]=true
#   [eza]=rtrue
#   [go]=true
#   [nvim]=true
#   [zoxide]=true
# )
#
# # Install tools in order of importance
# local tool_names=(
#   brew
#   starship
#   git
#   atuin
#   volta
#   uv
#   rustup
#   fzf
#   eza
#   go
#   nvim
#   # zoxide
# )
# for tool_name in "${tool_names[@]}"; do
#   local install_cmd="${TOOL_INSTALL_COMMANDS[$tool_name]}"
#   local is_essential="${TOOL_IS_ESSENTIAL[$tool_name]}"
#   log_info "Ensuring $tool_name is installed"
#   ensure_tool_installed "$tool_name" "$install_cmd" "$is_essential"
# done

# # Load configuration files in specific order, installing required tools if needed
# local files=(
#   "$ZDOTDIR/brew.zsh" # Homebrew package management
#   # "$ZDOTDIR/starship.zsh" # starship prompt
#   "$ZDOTDIR/fzf.zsh"  # Fuzzy finder configuration
#   "$ZDOTDIR/nvim.zsh" # Neovim editor configuration
#   # "$ZDOTDIR/fd.zsh"  # starship prompt
#   # "$ZDOTDIR/bat.zsh" # starship prompt
#   # "$ZDOTDIR/git.zsh"      # Git utilities and configurations
#   # "$ZDOTDIR/python.zsh" # Python development
#   # "$ZDOTDIR/nodejs.zsh"   # Node.js development
#   # "$ZDOTDIR/go.zsh"     # Go development
#   # "$ZDOTDIR/rust.zsh"   # Rust development
#   # "$ZDOTDIR/atuin.zsh"    # Atuin shell history
# )
# # Source individual configuration modules
# for file in $files; do
#   [[ -f "$file" ]] && source "$file"
# done

## Special case for Homebrew PATH
#if has_command "brew"; then
#  if is_apple_silicon; then
#    eval "$(/opt/homebrew/bin/brew shellenv)"
#  else
#    eval "$(/usr/local/bin/brew shellenv)"
#  fi
#fi

# # Special cases for tools that need post-installation configuration
# if ! has_command "atuin" && [[ ! -f "$XDG_DATA_HOME/atuin/.initialized" ]]; then
#   # Only run first-time setup if atuin was just installed
#   log_info "First-time Atuin setup: importing shell history" atuin import auto
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

alias claude="/Users/hank/.claude/local/claude"

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

#!/usr/bin/env zsh

# ====== Aliases ======
# Modern replacements

# # Navigation
# alias ..='cd ..'
# alias ...='cd ../..'
# alias ....='cd ../../..'
# alias -- -='cd -'

# Aliases
# Modern CLI tool alternatives
if command -v eza >/dev/null; then
  alias ls='eza --icons --group-directories-first'
  alias ll='eza -l --git --icons --group-directories-first'
  alias la='eza -la --git --icons --group-directories-first'
  alias lt='eza --tree --icons --group-directories-first'
fi

# Editor
alias v='$EDITOR'
alias vi='$EDITOR'
alias vim='$EDITOR'
alias ls="ls --color=auto"
alias ll="ls -la"
alias cat="bat"

command -v bat >/dev/null && alias cat='bat --paging=never'
command -v rg >/dev/null && alias grep='rg'
command -v fd >/dev/null && alias find='fd'
command -v lazygit >/dev/null && alias lg='lazygit'

# Git shortcuts
alias g="git"
alias ga="git add"
alias gc="git commit"
alias gp="git push"
alias gs="git status"
alias gp='git push'
alias gl='git pull'

# Example: flush DNS
alias flushdns="sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder"
alias showhidden="defaults write com.apple.finder AppleShowAllFiles YES; killall Finder"

# Package management
alias brewup='brew update && brew upgrade && brew cleanup'

# Load Custom Functions
# [[ -f "${ZDOTDIR}/functions.zsh" ]] && source "${ZDOTDIR}/functions.zsh"

# ====== Local Configuration ======
# Source local customizations if they exist
# [[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
# [[ -f "$ZDOTDIR/local.zsh" ]] && source "$ZDOTDIR/local.zsh"

#------------------------------------------------------------------------------
# Useful Aliases
#------------------------------------------------------------------------------
alias ll="ls -lahG"
alias brewup="brew update && brew upgrade && brew cleanup"
alias vi="nvim"

#############################################
# vim + neovim
#############################################
alias vi=nvim
alias vim=nvim

# upgrade to modern
alias ps='procs'
alias ping='gping'

alias diff='delta'

## FZF enhanced commands
alias flog='fzf --preview "bat --style=numbers --color=always --line-range=:500 {}"'
alias falias='alias | fzf'
alias fman='man -k . | fzf --preview "man {}"'
alias fls='man -k . | fzf --preview "man {}"'

alias ls='eza -al'
# alias cheat='navi'
# alias tldr='navi'
alias net='trippy'
alias netviz='netop'
alias jwt='jet-ui'
alias sed='sd'
alias du='dust'
alias ssh='sshs'
alias s3='stu'
# alias http='xh'
alias http='posting'
alias csv='xsv'
# alias rm='rip'
alias tmux='zellij'

alias jsonfilter='jnv'
alias jsonviewer='jnv'

# k8s kubernetes + docker + containers
alias k='k9s'

## Modern CLI alternatives
alias cat='bat --paging=always'
alias miller='mlr'
alias grep='rg'
alias find='fd'
alias md='glow'
alias ls='eza --icons'
alias ll='eza -l --icons'
alias la='eza -al --icons'
#
## Git shortcuts
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias lg='lazygit'

## Ghostty
alias g='ghostty'

## Homebrew aliases + shortcuts
#
# https://github.com/Homebrew/homebrew-aliases

alias b="brew"
#alias bdr="brew doctor"
#alias boc="brew outdated --cask"
#alias bof="brew outdated --formula"
alias bupd="brew update"
alias bupg="brew upgrade"
alias bclean="brew cleanup --prune=all && brew autoremove"
alias bcleanall='brew cleanup --prune=all && rm -rf $(brew --cache) && brew autoremove'
alias bin="brew install"
alias brein="brew reinstall"
alias bi="brew info"
alias bs="brew search"
alias bl="brew leaves"

## Homebrew Cask/Bundle management
alias bcl="brew list --cask"
alias bcin="brew install --cask"
alias bb="brew bundle"
alias bbls="brew bundle dump --all --file=- --verbose"
alias bbsave="brew bundle dump --all --verbose --global"
alias bbcheck="brew bundle check --all --verbose --global"

## Directory navigation
alias gdl='cd ~/Downloads'
alias gcf='cd ~/.config/'
#
#
# Zsh configuration
alias ze="nvim ~/.zshrc"
alias zs="exec zsh"
alias zr="exec zsh"
alias zcompreset="rm -f ~/.zcompdump; compinit"

# Tailscale
alias ts="tailscale"

# # +--------+
# # | System |
# # +--------+
#
# alias shutdown='sudo shutdown now'
# alias restart='sudo reboot'
# alias suspend='sudo pm-suspend'
#
# alias bigf= 'find / -xdev -type f -size +500M'  # display "big" files > 500M
#
# # +-----+
# # | X11 |
# # +-----+
#
# alias xpropc='xprop | grep WM_CLASS' # display xprop class
#
# # +-----+
# # | Zsh |
# # +-----+
#
# alias d='dirs -v'
# for index ({1..9}) alias "$index"="cd +${index} > /dev/null"; unset index # directory stack
#
# alias kitty='kitty -o allow_remote_control=yes --single-instance --listen-on unix:@mykitty'
#
#
# # +------+
# # | wget |
# # +------+
# alias wget='wget --hsts-file="$HOME/wget-hsts'
#
# # +----+
# # | cp |
# # +----+
#
# alias cp='cp -iv'
# alias mv='mv -iv'
# alias rm='rm -iv'
#
# # +------+
# # | grep |
# # +------+
#
# alias grep="grep -P -i --color=auto"
#
# # +------+
# # | xlip |
# # +------+
#
# alias cb='xclip -sel clip'
#
# # +------+
# # | dust |
# # +------+
#
# alias dust='du -sh * | sort -hr'
#
# # +------+
# # | ping |
# # +------+
#
# alias pg='ping 8.8.8.8'
#
# # +------+
# # | time |
# # +------+
#
# alias time='/usr/bin/time'
#
# # +----+
# # | bc |
# # +----+
#
# alias calc="noglob calcul"
#
# # +-----+
# # | bat |
# # +-----+
#
# alias batl='bat --paging=never -l log'
#
# # +--------+
# # | pacman |
# # +--------+
#
# alias paci='sudo pacman -S'               # install
# alias pachi='sudo pacman -Ql'             # Pacman Has Installed - what files where installed in a package
# alias pacs='sudo pacman -Ss'              # search
# alias pacu='sudo pacman -Syu'             # update
# alias pacr='sudo pacman -R'               # remove package but not dependencies
# alias pacrr='sudo pacman -Rs'             # remove package with unused dependencies by other softwares
# alias pacrc='sudo pacman -Sc'             # remove pacman's cache
# alias pacro='pacman -Rns $(pacman -Qtdq)'
# alias pacrl='rm /var/lib/pacman/db.lck'   # pacman remove locks
# alias pacls="sudo pacman -Qe"
# alias pacc='sudo pacman -Sc'
# alias paccc='sudo pacman -Scc'            # empty the whole cache
#
# # +-------+
# # | fonts |
# # +-------+
#
# alias fonts='fc-cache -f -v'
#
# # +-----+
# # | yay |
# # +-----+
#
# alias yayi='yay -S'     # install
# alias yayhi='yay -Ql'   # Yay Has Installed - what files where installed in a package
# alias yays='yay -Ss'    # search
# alias yayu='yay -Syu'   # update
# alias yayr='yay -R'     # remove package but not dependencies
# alias yayrr='yay -Rs'   # remove package with unused dependencies by other softwares
# alias yayrc='yay -Sc'   # remove yay's cache
# alias yayls="yay -Qe"
#
# # +--------+
# # | netctl |
# # +--------+
#
# alias wifi='sudo wifi-menu -o'
#
# # +--------+
# # | Golang |
# # +--------+
#
# alias gob="go build"
# alias gor="go run"
# alias goc="go clean -i"
# alias gta="go test ./..."       # go test all
# alias gia="go install ./..."    # go install all
#
# # +------+
# # | Hugo |
# # +------+
#
# alias hugostart="hugo server -DEF --ignoreCache"
#
# # +--------+
# # | muffet |
# # +--------+
#
# alias deadlink="muffet -t 20"
#
# # +---------+
# # | netstat |
# # +---------+
#
# alias port="netstat -tulpn | grep"
#
# # +--------+
# # | Neovim |
# # +--------+
#
# alias vim='nvim'
# alias vi='nvim'
# alias svim='sudoedit'
# alias dvim="vim -u /usr/share/nvim/archlinux.vim" # nvim with default config
# alias nvimc='rm -I $VIMCONFIG/swap/*'             # clean nvim swap file
# alias nvimcu='rm -I $VIMCONFIG/undo/*'            # clean the vim undo
# alias nviml='nvim -w $VIMCONFIG/vimlog "$@"'      # log the keystrokes
# alias nvimd='nvim --noplugin -u NONE'             # launch nvim without any plugin or config (nvim debug)
# alias nvimfr='nvim +e /tmp/scratchpad.md -c "set spelllang=fr"'
# alias lvim='\vim -c "set nowrap|syntax off"'        # fast vim for big files / big oneliner
#
# # +-----+
# # | Git |
# # +-----+
#
# alias gs='git status'
# alias gss='git status -s'
# alias ga='git add'
# alias gp='git push'
# alias gpraise='git blame'
# alias gpo='git push origin'
# alias gpof='git push origin --force-with-lease'
# alias gpofn='git push origin --force-with-lease --no-verify'
# alias gpt='git push --tag'
# alias gtd='git tag --delete'
# alias gtdr='git tag --delete origin'
# alias grb='git branch -r'                                                                           # display remote branch
# alias gplo='git pull origin'
# alias gb='git branch '
# alias gc='git commit'
# alias gd='git diff'
# alias gco='git checkout '
# alias gl='git log --oneline'
# alias gr='git remote'
# alias grs='git remote show'
# alias glol='git log --graph --abbrev-commit --oneline --decorate'
# alias gclean="git branch --merged | grep  -v '\\*\\|master\\|develop' | xargs -n 1 git branch -d" # Delete local branch merged with master
# alias gblog="git for-each-ref --sort=committerdate refs/heads/ --format='%(HEAD) %(color:red)%(refname:short)%(color:reset) - %(color:yellow)%(objectname:short)%(color:reset) - %(contents:subject) - %(authorname) (%(color:blue)%(committerdate:relative)%(color:reset))'"                                                             # git log for each branches
# alias gsub="git submodule update --remote"                                                        # pull submodules
# alias gj="git-jump"                                                                               # Open in vim quickfix list files of interest (git diff, merged...)
#
# alias dif="git diff --no-index"                                                                   # Diff two files even if not in git repo! Can add -w (don't diff whitespaces)
#
# # +------+
# # | tmux |
# # +------+
#
# alias tmuxk='tmux kill-session -t'
# alias tmuxa='tmux attach -t'
# alias tmuxl='tmux list-sessions'
#
# # +-------+
# # | tmuxp |
# # +-------+
#
# alias mux='tmuxp load'
#
#
# # +------+
# # | lynx |
# # +------+
#
# alias lynx='lynx -vikeys -accept_all_cookies'
#
# # +----------------+
# # | udiskie-umount |
# # +----------------+
#
# alias ubackup='udiskie-umount $MEDIA/BACKUP'
# alias umedia='udiskie-umount $MEDIA/*'
#
# # +--------+
# # | docker |
# # +--------+
# alias dockls="docker container ls | awk 'NR > 1 {print \$NF}'"                  # display names of running containers
# alias dockRr='docker rm $(docker ps -a -q)'                                     # delete every containers / images
# alias dockRr='docker rm $(docker ps -a -q) && docker rmi $(docker images -q)'   # delete every containers / images
# alias dockstats='docker stats $(docker ps -q)'                                  # stats on images
# alias dockimg='docker images'                                                   # list images installed
# alias dockprune='docker system prune -a'                                        # prune everything
# alias dockceu='docker-compose run --rm -u $(id -u):$(id -g)'                    # run as the host user
# alias dockce='docker-compose run --rm'
#
# # +----------------+
# # | docker-compose |
# # +----------------+
#
# alias docker-compose-dev='docker-compose -f docker-compose-dev.yml' # run a different config file than the default one
#
# # +----------+
# # | Personal |
# # +----------+
#
# alias nvidia-settings='nvidia-settings --config="$XDG_CONFIG_HOME"/nvidia/settings'
#
# # Folders
# alias work="$HOME/workspace"
# alias doc="$HOME/Documents"
# alias dow="$HOME/Downloads"
# alias dot="$HOME/.dotfiles"
#
# # Mindmaps
# alias freebrain="freemind $CLOUD/knowledge_base/_BRAINSTORMING/*.mm &> /dev/null &"
# alias freelists="freemind $CLOUD/knowledge_base/_LISTS/*.mm &> /dev/null &"
# alias freepain="freemind $CLOUD/knowledge_base/_PROBLEMS/*.mm &> /dev/null &"
# alias freeproj="freemind $CLOUD/knowledge_base/_PROJECTS/*.mm &> /dev/null &"
#
# # Golang
# alias gosrc="$GOPATH/src/" # golang src
# alias gobin="$GOPATH/bin/" # golang bin
#
# # Clojure
# alias cljrepl='clojure -Sdeps "{:deps {com.bhauman/rebel-readline {:mvn/version \"0.1.4\"}}}" -m rebel-readline.main'
#
# # AWS
# alias awsa='aws --profile amboss-profile'
#
# # OBS
#
# alias obsn='prime-run obs&'
#
# # +--------+
# # | Custom |
# # +--------+
#
# alias mke='mkextract'
# alias ex='extract'
#
# # +---------+
# # | scripts |
# # +---------+
#
# alias ddg="duckduckgo"
# alias wiki="wikipedia"
#
#
# ## marta file manager symlink
# ## ln -s /Applications/Marta.app/Contents/Resources/launcher /usr/local/bin/marta
# #alias marta="/Applications/Marta.app/Contents/Resources/launcher"
# #
# ## -----------------------------------------------------
# ## Custom functions (example)
# ## -----------------------------------------------------
# #mkcd () {
# #  mkdir -p "$1" && cd "$1"
# #}
# #
#
# # custom functions
# # symlink
# slink() {
#     local src_orig=$1
#     local dst_link=$2
#     local dst_dir=$(dirname "$dst_link")
#
#     # Create the directory if it does not exist
#     mkdir -p "$dst_dir"
#
#     # Create the symlink
#     ln -nfs "$src_orig" "$dst_link"
# }
#
# slink_init() {
#     slink $DOTFILES/.Brewfile $HOME/.Brewfile
#     slink $DOTFILES/.zshrc $HOME/.zshrc
#
#     slink $DOTFILES_EXPORTS $OMZ_CUSTOM/exports.zsh
#     slink $DOTFILES_ALIASES $OMZ_CUSTOM/aliases.zsh
#     slink $DOTFILES_FUNCTIONS $OMZ_CUSTOM/functions.zsh
#
#     slink $DOTFILES/nvm/default-packages $NVM_DIR/default-packages
#     slink $DOTFILES/.config/git/.gitignore $HOME/.gitignore
#
#
#     slink $DOTFILES/.config/zellij/main-layout.kdl $HOME/.config/config.kdl
# }
#

# ========================================================================
# Misc Shortcuts
# ========================================================================
alias c="clear"
alias hf="huggingface-cli"
alias lg="lazygit"
alias j="just"
alias zj="zellij"

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

# bun completions
[ -s "/Users/hank/.bun/_bun" ] && source "/Users/hank/.bun/_bun"
