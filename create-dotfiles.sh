#!/usr/bin/env zsh
# create-dotfiles.zsh - Creates the initial dotfiles structure
# Create Missing Dotfiles Structure
# Run this script to create the required dotfiles structure if starting from scratch

set -euo pipefail

export DOTFILES="${DOTFILES:-$HOME/dotfiles}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

log() { printf "%b\n" "$*" >&2; }
info() { log "\033[34m[INFO]\033[0m $*"; }
warn() { log "\033[33m[WARN]\033[0m $*"; }
error() { log "\033[31m[ERROR]\033[0m $*"; }
success() { log "\033[32m[OK]\033[0m $*"; }

ensure_dir() {
  local dir="$1"
  if [[ ! -d "$dir" ]]; then
    info "Creating directory: $dir"
    mkdir -p "$dir"
  fi
}

# Main function to create dotfiles structure
create_dotfiles_structure() {
  info "Creating dotfiles structure at $DOTFILES"

  # Create main dotfiles directory
  ensure_dir "$DOTFILES"

  # Create config directory
  ensure_dir "$DOTFILES/config"
  ensure_dir "$DOTFILES/config/zsh"
  ensure_dir "$DOTFILES/config/nvim"
  ensure_dir "$DOTFILES/config/bat"
  ensure_dir "$DOTFILES/config/atuin"
  ensure_dir "$DOTFILES/config/zellij"
  ensure_dir "$DOTFILES/config/karabiner"
  ensure_dir "$DOTFILES/config/vscode"
  ensure_dir "$DOTFILES/config/cursor"
  ensure_dir "$DOTFILES/config/hammerspoon"
  ensure_dir "$DOTFILES/config/ai/claude"

  # Create basic utils.sh file if it doesn't exist
  if [[ ! -f "$DOTFILES/utils.sh" ]]; then
    info "Creating basic utils.sh file"
    cat > "$DOTFILES/utils.sh" << 'EOF'
#!/usr/bin/env bash
# Core shell utilities for dotfiles management

# Logging utilities
log() { printf "%b\n" "$*" >&2; }
info() { log "\033[34m[INFO]\033[0m $*"; }
warn() { log "\033[33m[WARN]\033[0m $*"; }
error() { log "\033[31m[ERROR]\033[0m $*"; }
success() { log "\033[32m[OK]\033[0m $*"; }

# System detection
is_macos() { [[ "$OSTYPE" == darwin* ]]; }
is_apple_silicon() { [[ "$(uname -m)" == "arm64" ]]; }
has_command() { command -v "$1" >/dev/null 2>&1; }

# File operations
backup_file() {
  local file="$1"
  local backup="${file}.backup-$(date +%Y%m%d_%H%M%S)"

  if [[ -e "$file" ]]; then
    info "Backing up $file to $backup"
    mv "$file" "$backup"
  fi
}

make_link() {
  local src_orig="$1"
  local dst_symlink="$2"

  if [[ ! -e "$src_orig" ]]; then
    error "Source does not exist: $src_orig"
    return 1
  fi

  info "Linking $src_orig → $dst_symlink"
  ln -sf "$src_orig" "$dst_symlink"
}

ensure_dir() {
  local dir="$1"
  if [[ ! -d "$dir" ]]; then
    info "Creating directory: $dir"
    mkdir -p "$dir"
  fi
}
EOF
    chmod +x "$DOTFILES/utils.sh"
  fi

  # Create basic ZSH configuration files
  if [[ ! -f "$DOTFILES/config/zsh/.zshenv" ]]; then
    info "Creating basic ZSH environment file"
    cat > "$DOTFILES/config/zsh/.zshenv" << 'EOF'
# ZSH Environment Variables
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export DOTFILES="${DOTFILES:-$HOME/dotfiles}"
export ZDOTDIR="${ZDOTDIR:-$DOTFILES/config/zsh}"

# Editor configuration
export EDITOR="vim"
export VISUAL="$EDITOR"

# History configuration
export HISTFILE="$HOME/.zsh_history"
export HISTSIZE=1000000
export SAVEHIST=1000000
EOF
  fi

  if [[ ! -f "$DOTFILES/config/zsh/.zshrc" ]]; then
    info "Creating basic ZSH rc file"
    cat > "$DOTFILES/config/zsh/.zshrc" << 'EOF'
# ZSH Configuration
source "$DOTFILES/utils.sh"

# Shell Options
setopt AUTO_CD              # Change directory without cd
setopt AUTO_PUSHD           # Push directory to stack on cd
setopt PUSHD_IGNORE_DUPS    # Don't store duplicates in stack
setopt PUSHD_SILENT         # Don't print stack after pushd/popd
setopt EXTENDED_GLOB        # Extended globbing
setopt INTERACTIVE_COMMENTS # Allow comments in interactive shells
setopt NO_CASE_GLOB         # Case insensitive globbing

# History Options
setopt EXTENDED_HISTORY       # Record timestamp
setopt HIST_EXPIRE_DUPS_FIRST # Delete duplicates first
setopt HIST_IGNORE_DUPS       # Don't record duplicates
setopt HIST_VERIFY            # Don't execute immediately upon history expansion
setopt SHARE_HISTORY          # Share history between sessions
setopt HIST_IGNORE_SPACE      # Don't record commands starting with space

# Vi Mode Configuration
bindkey -v

# Initialize tools if installed
has_command starship && eval "$(starship init zsh)"
has_command atuin && eval "$(atuin init zsh)"
has_command zoxide && eval "$(zoxide init zsh)"
has_command direnv && eval "$(direnv hook zsh)"

# Load plugins if available
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

# Load additional config files
if [[ -f "$ZDOTDIR/aliases.zsh" ]]; then
  source "$ZDOTDIR/aliases.zsh"
fi

if [[ -f "$ZDOTDIR/functions.zsh" ]]; then
  source "$ZDOTDIR/functions.zsh"
fi

if [[ -f "$ZDOTDIR/fzf.zsh" ]]; then
  source "$ZDOTDIR/fzf.zsh"
fi

# Local customizations, not tracked by git
if [[ -f "$ZDOTDIR/local.zsh" ]]; then
  source "$ZDOTDIR/local.zsh"
fi
EOF
  fi

  # Create Brewfile from your provided file
  if [[ ! -f "$DOTFILES/Brewfile" ]]; then
    info "Creating Brewfile from the provided data"
    cp -f "$(dirname "$0")/paste-3.txt" "$DOTFILES/Brewfile"
    success "Created Brewfile with all your desired applications"
  fi

  success "Dotfiles structure created successfully at $DOTFILES"
  info "You can now run the setup script to configure your system"
}

# Run the creation process
create_dotfiles_structure
