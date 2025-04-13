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

export cloud="~/Library/CloudStorage"
export gdrive="~/Library/CloudStorage/GoogleDrive-hank.lee.qed@gmail.com"
export dropbox="~/Library/CloudStorage/Dropbox"

# Dotfiles location
# export DOTFILES="${DOTFILES:-$HOME/dotfiles}"

# Ensure XDG directories exist
[[ ! -d "$XDG_CONFIG_HOME" ]] && mkdir -p "$XDG_CONFIG_HOME"
[[ ! -d "$XDG_CACHE_HOME" ]] && mkdir -p "$XDG_CACHE_HOME"
[[ ! -d "$XDG_DATA_HOME" ]] && mkdir -p "$XDG_DATA_HOME"
[[ ! -d "$XDG_STATE_HOME" ]] && mkdir -p "$XDG_STATE_HOME"

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
export UTILS_PATH="${DOTFILES}/config/zsh/utils.zsh"

if [[ -f "${UTILS_PATH}" ]]; then
  source "${UTILS_PATH}"
  # log_success "Successfully loaded utils.zsh with $(functions | grep -c '^[a-z].*() {') utility functions"

  # List some key utility functions that should be available
  # log_info "Available utility functions include: has_command, is_macos, path_add, sys, etc."
else
  echo "Error: ${UTILS_PATH} not found. Some functionality will be unavailable."
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
# git
# ========================================================================

if ! has_command git; then
  echo "git not found. Installing git..."
  brew install --quiet git
fi

export GIT_EDITOR="nvim"
export GIT_PAGER="bat --pager always"
export GIT_AUTHOR_NAME="Hank"
export GIT_AUTHOR_EMAIL="hank.lee.qed@gmail.com"
export GIT_COMMITTER_NAME="Hank"
export GIT_COMMITTER_EMAIL="hank.lee.qed@gmail.com"

# Backup existing config if needed
# [[ -f ~/.gitconfig ]] || mv ~/.gitconfig ~/.gitconfig.backup
# [[ -f ~/.gitignore ]] || mv ~/.gitignore ~/.gitignore.backup

# Create symbolic link
ln -sf ~/dotfiles/config/git/gitconfig ~/.gitconfig
ln -sf ~/dotfiles/config/git/gitignore ~/.gitignore

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
# export VOLTA_HOME="$HOME/.volta"
# # export PATH="$VOLTA_HOME/bin:$PATH"
# path_add "$VOLTA_HOME/bin"
# if ! has_command volta; then
#   echo "Volta not found. Installing ..."
#   brew install volta
# fi

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

# FNM (https://github.com/Schniz/fnm)

# if ! has_command fnm; then
#   echo "FNM not found. Installing ..."
#   brew install --quiet nvim
# fi
#
# eval "$(fnm env --use-on-cd --shell zsh)"
# path_add "$HOME/.fnm"

# TODO: add github extensions list
# - gh extension install dlvhdr/gh-dash
# TODO: add nodejs global packages (bun + etc)
# TODO: add uv global packages

# mkdir -p ~/.npm-global
# npm config set prefix ~/.npm-global
# path_add "~/.npm-global/bin"
# TODO: npm install -g @anthropic-ai/claude-code
# TODO: npm install --save-dev commitizen commitlint husky

path_add "$HOME/.npm-global/bin"

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
if [[ -d "$CARGO_HOME/bin" ]]; then
  path_add "$CARGO_HOME/bin"
fi

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
export GOPATH="$HOME/go"
export GOBIN="$GOPATH/bin"

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
if type brew &>/dev/null; then
  FPATH=$(brew --prefix)/share/zsh-abbr:$FPATH
fi

fpath=($HOMEBREW_PREFIX/share/zsh/site-functions $fpath)
autoload -Uz compinit
compinit

# Initialize the completion system
# Completions setup
# if type brew &>/dev/null; then
#   FPATH=$(brew --prefix)/share/zsh-abbr:$FPATH
#   autoload -Uz compinit
#   compinit
# else
#autoload -Uz compinit
#compinit
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
# has_command fnm && eval "$(fnm env --use-on-cd)"
# has_command volta && eval "$(volta setup)"
has_command uv && eval "$(uv generate-shell-completion zsh)"
# has_command uvx && eval "$(uvx --generate-shell-completion zsh)"
# has_command pyenv && eval "$(pyenv init -)"
# has_command abbr && eval "$(abbr init zsh)"

# Load FZF completions
if has_command fzf; then
  source <(fzf --zsh)
fi

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Source aliases and functions
[[ -f "${ZDOTDIR}/aliases.zsh" ]] && source "${ZDOTDIR}/aliases.zsh"
[[ -f "${ZDOTDIR}/functions.zsh" ]] && source "${ZDOTDIR}/functions.zsh"
