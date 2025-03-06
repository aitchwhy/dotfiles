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
setopt AUTO_CD              # Change directory without cd
setopt AUTO_PUSHD           # Push directory to stack on cd
setopt PUSHD_IGNORE_DUPS    # Don't store duplicates in stack
setopt PUSHD_SILENT         # Don't print stack after pushd/popd

# Globbing and Pattern Matching
setopt EXTENDED_GLOB        # Extended globbing
setopt NO_CASE_GLOB         # Case insensitive globbing

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
# Keyboard & Input Configuration
# ========================================================================

# Vi Mode
bindkey -v
export KEYTIMEOUT=1

# Basic key bindings
bindkey '^P' up-line-or-history
bindkey '^N' down-line-or-history
bindkey '^E' end-of-line
bindkey '^A' beginning-of-line
# bindkey '^K' up-line-or-history
# bindkey '^J' down-line-or-history
# bindkey '^L' end-of-line
# bindkey '^H' beginning-of-line
# bindkey '^R' history-incremental-search-backward
# bindkey '^?' backward-delete-char # Backspace working after vi mode

# ========================================================================
# Helper Functions
# ========================================================================

# Check if a command exists
has_command() {
  command -v "$1" &>/dev/null
}

# Display an info message
log_info() {
  printf '\033[0;34m[INFO]\033[0m %s\n' "$*"
}

# Install a tool if it's missing
install_tool() {
  local tool="$1"
  local install_cmd="$2"

  if ! has_command "$tool"; then
    log_info "Installing $tool..."
    eval "$install_cmd"
  fi
}

# Editor preference - use nvim if available
has_command nvim && export EDITOR="nvim" && export VISUAL="nvim"

# ========================================================================
# Module Loading
# ========================================================================

# Load configuration files in specific order
local files=(
  "$ZDOTDIR/system.zsh"   # Core system functions and utilities
  "$ZDOTDIR/brew.zsh"     # Homebrew package management
  "$ZDOTDIR/git.zsh"      # Git utilities and configurations
  "$ZDOTDIR/fzf.zsh"      # Fuzzy finder configuration
  "$ZDOTDIR/nvim.zsh"     # Neovim editor configuration
  "$ZDOTDIR/atuin.zsh"    # Atuin shell history
  "$ZDOTDIR/nodejs.zsh"   # Node.js development
  "$ZDOTDIR/python.zsh"   # Python development
  "$ZDOTDIR/rust.zsh"     # Rust development
  # "$ZDOTDIR/functions.zsh" # Additional custom functions
  # "$ZDOTDIR/local.zsh"     # Local machine-specific config (load last)
)

# Source configuration modules and handle tool installation
for file in $files; do
  # Get the base name without path and extension
  base_name="${file##*/}"
  tool_name="${base_name%.zsh}"

  # Install missing tools before sourcing their config
  case "$tool_name" in
  fzf)
    install_tool "fzf" "brew install fzf"
    ;;
  nvim)
    install_tool "nvim" "brew install neovim"
    ;;
  atuin)
    install_tool "atuin" "curl https://setup.atuin.sh | bash"
    ;;
  nodejs)
    install_tool "volta" "curl https://get.volta.sh | bash"
    ;;
  python)
    install_tool "uv" "curl -LsSf https://astral.sh/uv/install.sh | sh"
    ;;
  rust)
    install_tool "rustup" "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
    ;;
  esac

  # Source the configuration file (silently)
  [[ -f "$file" ]] && source "$file"
done

# ========================================================================
# Completions
# ========================================================================

# Initialize the completion system
autoload -Uz compinit
compinit

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
has_command volta && eval "$(volta setup)"
has_command uv && eval "$(uv generate-shell-completion zsh)"
has_command uvx && eval "$(uvx --generate-shell-completion zsh)"
# has_command pyenv && eval "$(pyenv init -)"
# has_command abbr && eval "$(abbr init zsh)"

# Load FZF completions
has_command fzf && source <(fzf --zsh)

# ========================================================================
# Local Environment
# ========================================================================

# Load local environment variables if they exist
[[ -f "$HOME/.local/state/env" ]] && . "$HOME/.local/state/env"

# TODO: Clean up this remaining hardcoded path for atuin
# Consider moving to atuin.zsh or handling installation better
[[ -f "$HOME/.atuin/bin/env" ]] && . "$HOME/.atuin/bin/env"
