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
# Dotfiles Symlink Map Configuration
# ========================================================================

# This defines the mapping between dotfiles source locations and their
# target locations in the user's home directory. It's used by the installation
# script and other dotfiles management tools.

declare -gA DOTFILES_TO_SYMLINK_MAP=(
  # Git configurations
  ["$DOTFILES/config/git/gitconfig"]="$HOME/.gitconfig"
  ["$DOTFILES/config/git/gitignore"]="$HOME/.gitignore"
  ["$DOTFILES/config/git/gitattributes"]="$HOME/.gitattributes"
  ["$DOTFILES/config/git/gitmessage"]="$HOME/.gitmessage"

  # XDG configurations
  ["$DOTFILES/config/starship.toml"]="$XDG_CONFIG_HOME/starship.toml"
  ["$DOTFILES/config/karabiner/karabiner.json"]="$XDG_CONFIG_HOME/karabiner/karabiner.json"
  ["$DOTFILES/config/nvim"]="$XDG_CONFIG_HOME/nvim"
  ["$DOTFILES/config/ghostty"]="$XDG_CONFIG_HOME/ghostty"
  ["$DOTFILES/config/atuin"]="$XDG_CONFIG_HOME/atuin"
  ["$DOTFILES/config/bat"]="$XDG_CONFIG_HOME/bat"
  ["$DOTFILES/config/lazygit"]="$XDG_CONFIG_HOME/lazygit"
  ["$DOTFILES/config/zellij"]="$XDG_CONFIG_HOME/zellij"
  ["$DOTFILES/config/zed"]="$XDG_CONFIG_HOME/zed"
  ["$DOTFILES/config/espanso"]="$XDG_CONFIG_HOME/espanso"
  ["$DOTFILES/config/yazi"]="$XDG_CONFIG_HOME/yazi"
  ["$DOTFILES/config/warp/keybindings.yaml"]="$XDG_CONFIG_HOME/warp/keybindings.yaml"

  # Editor configurations
  ["$DOTFILES/config/vscode/settings.json"]="$HOME/Library/Application Support/Code/User/settings.json"
  ["$DOTFILES/config/vscode/keybindings.json"]="$HOME/Library/Application Support/Code/User/keybindings.json"
  ["$DOTFILES/config/cursor/settings.json"]="$HOME/Library/Application Support/Cursor/User/settings.json"
  ["$DOTFILES/config/cursor/keybindings.json"]="$HOME/Library/Application Support/Cursor/User/keybindings.json"

  # macOS-specific configurations
  ["$DOTFILES/config/hammerspoon"]="$HOME/.hammerspoon"

  # AI tools configurations
  ["$DOTFILES/config/ai/claude/claude_desktop_config.json"]="$HOME/Library/Application Support/Claude/claude_desktop_config.json"
  ["$DOTFILES/config/ai/cline/cline_mcp_settings.json"]="$HOME/Library/Application Support/Cursor/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json"
)

# Export the map for use in other scripts
export DOTFILES_TO_SYMLINK_MAP

# ========================================================================
# Editor & Terminal Settings
# ========================================================================

# Default editor
export EDITOR="vim"
export VISUAL="$EDITOR"
# export PAGER="less -FRX"

# Terminal settings
export COLORTERM=truecolor
export TERM_PROGRAM="${TERM_PROGRAM:-Apple_Terminal}"

# ========================================================================
# Source Utility Functions
# ========================================================================

[[ -f "$ZDOTDIR/utils.zsh" ]] && source "$ZDOTDIR/utils.zsh"

# ========================================================================
# Module Loading
# ========================================================================

# Install a tool if it's missing
function install_tool() {
  local tool="$1"
  local install_cmd="$2"

  if ! has_command "$tool"; then
    log_info "Installing $tool..."
    eval "$install_cmd"
  fi
}
# Load configuration files in specific order
local files=(
  "$ZDOTDIR/brew.zsh"     # Homebrew package management
  "$ZDOTDIR/eza.zsh"      # eza file system explorer
  "$ZDOTDIR/git.zsh"      # Git utilities and configurations
  "$ZDOTDIR/nodejs.zsh"   # Node.js development
  "$ZDOTDIR/go.zsh"       # Node.js development
  "$ZDOTDIR/python.zsh"   # Python development
  "$ZDOTDIR/rust.zsh"     # Rust development
  "$ZDOTDIR/atuin.zsh"    # Atuin shell history
  "$ZDOTDIR/fzf.zsh"      # Fuzzy finder configuration
  "$ZDOTDIR/nvim.zsh"     # Neovim editor configuration
  "$ZDOTDIR/starship.zsh" # starship prompt
)

# Source configuration modules and handle tool installation
for file in $files; do
  # Get the base name without path and extension
  base_name="${file##*/}"
  tool_name="${base_name%.zsh}"

  # Install missing tools before sourcing their config
  case "$tool_name" in
  brew)
    if ! has_command "brew"; then
      echo "Installing missing brew..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    # Add to PATH for current session if installed
    if is_apple_silicon; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    else
      eval "$(/usr/local/bin/brew shellenv)"
    fi
    ;;
  starship)
    if ! has_command "starship"; then
      echo "Installing missing starship..."
      curl -sS https://starship.rs/install.sh | sh
    fi
    ;;
  atuin)
    if ! has_command "atuin"; then
      echo "Installing missing atuin..."
      curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh
      log_info "First-time Atuin setup: importing shell history"
      log_info "Sync with Atuin server if network is available"
      atuin import auto
      atuin sync -f
    fi
    ;;
  nodejs)
    if ! has_command "volta"; then
      echo "Installing missing volta..."
      curl https://get.volta.sh | bash
      volta install node
    fi
    ;;
  python)
    if ! has_command "uv"; then
      echo "Installing missing uv..."
      curl -LsSf https://astral.sh/uv/install.sh | sh
    fi
    ;;
  rust)
    if ! has_command "rustup"; then
      echo "Installing missing rustup..."
      curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    fi
    ;;
  fzf)
    if ! has_command "fzf"; then
      echo "Installing missing fzf..."
      brew install fzf
    fi
    ;;
  git)
    if ! has_command "git"; then
      echo "Installing missing git..."
      brew install git
    fi
    ;;
  eza)
    if ! has_command "eza"; then
      echo "Installing missing eza..."
      brew install eza
    fi
    ;;
  go)
    if ! has_command "go"; then
      echo "Installing missing go..."
      brew install go
    fi
    ;;
  nvim)
    if ! has_command "nvim"; then
      echo "Installing missing nvim..."
      brew install neovim
    fi
    ;;
  zoxide)
    if ! has_command "zoxide"; then
      echo "Installing missing zoxide..."
      brew install zoxide
    fi
    ;;
  esac

  # Source the configuration file (silently)
  [[ -f "$file" ]] && source "$file"
done

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
has_command volta && eval "$(volta setup)"
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
[[ -f "$HOME/.local/state/env" ]] && . "$HOME/.local/state/env"

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
