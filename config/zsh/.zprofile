# ========================================================================
# ZSH Profile (.zprofile)
# ========================================================================
# Executed at login (after .zshenv)
# Used primarily for setting PATH and environment variables
# References:
# - https://wiki.archlinux.org/title/Zsh#Configuration_files
# - https://gist.github.com/Linerre/f11ad4a6a934dcf01ee8415c9457e7b2
# - https://mac.install.guide/terminal/zshrc-zprofile


# # ========================================================================
# # XDG Base Directory Specification
# # ========================================================================

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
# export XDG_BIN_HOME="${XDG_BIN_HOME:-$HOME/.local/bin}"

# # Ensure XDG directories exist
if [[ ! -d "$XDG_CONFIG_HOME" ]]; then mkdir -p "$XDG_CONFIG_HOME"; fi
if [[ ! -d "$XDG_CACHE_HOME" ]]; then mkdir -p "$XDG_CACHE_HOME"; fi
if [[ ! -d "$XDG_DATA_HOME" ]]; then mkdir -p "$XDG_DATA_HOME"; fi
if [[ ! -d "$XDG_STATE_HOME" ]]; then mkdir -p "$XDG_STATE_HOME"; fi

# Ensure ZSH config directory is set
export ZDOTDIR=${ZDOTDIR:-$XDG_CONFIG_HOME/zsh}

# # Dotfiles location
export DOTFILES="${DOTFILES:-$HOME/dotfiles}"



# ========================================================================
# XDG Base Directory Specification
# ========================================================================
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_BIN_HOME="${XDG_BIN_HOME:-$HOME/.local/bin}"

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

# Ensure ZSH config directory is set
# export ZDOTDIR=${ZDOTDIR:-$XDG_CONFIG_HOME/zsh}
# export ZDOTDIR=${ZDOTDIR:-$XDG_CONFIG_HOME/zsh}

# Dotfiles location
export DOTFILES="$HOME/dotfiles"
export ZDOTDIR="$DOTFILES/config/zsh"

# This file contains the main utility functions and environment variables
[[ -f "$ZDOTDIR/utils.zsh" ]] && source "$ZDOTDIR/utils.zsh"

# ========================================================================
# Editor & Terminal Settings
# ========================================================================

# Default editor
export EDITOR="vim"
export VISUAL="$EDITOR"
# export PAGER="less -FRX"


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



# Initialize dotfiles - ensure essential symlinks exist
# This is a lightweight version of setup_cli_tools from install.zsh
# that won't disrupt the user's shell experience
dotfiles_init() {
  # Only run in interactive shells to avoid slowing down scripts
  if [[ -o interactive ]]; then
    # Create missing symlinks silently
    for key in ${(k)DOTFILES_TO_SYMLINK_MAP}; do
      local src="$key"
      local dst="${DOTFILES_TO_SYMLINK_MAP[$key]}"

      # Only create symlink if source exists and destination doesn't
      if [[ -e "$src" ]] && [[ ! -e "$dst" ]]; then
        local parent_dir=$(dirname "$dst")

        # Create parent directory if needed
        [[ ! -d "$parent_dir" ]] && mkdir -p "$parent_dir"

        # Create the symlink
        echo "Creating symlink: $dst -> $src"
        ln -sf "$src" "$dst"
      fi
    done
  fi
}


# ========================================================================
# Homebrew Setup
# ========================================================================

# Setup Homebrew for the current architecture
if [[ -x /opt/homebrew/bin/brew ]]; then
  # Apple Silicon path
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  # Intel Mac path
  eval "$(/usr/local/bin/brew shellenv)"
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

# export PATH="$VOLTA_HOME/bin:$PATH"

# Remove duplicate entries from PATH
# typeset -U path PATH
typeset -U path PATH

# Add prioritized paths
path=(
  # Version managers (need to be before Homebrew)
  $HOME/.volta/bin # Node.js version manager

  # Other language-specific paths
  $HOME/.cargo/bin # Rust
  $HOME/go/bin     # Go

  # # System paths
  # "$HOME/.local/bin" # User local binaries
  # "$HOME/bin"        # User personal binaries

# # user compiled python as default python
# export PATH=$HOME/python/bin:$PATH
# export PYTHONPATH=$HOME/python/
#
# # user installed node as default node
# export PATH="$HOME/node/node-v16.0.0-${KERNEL_NAME}-x64"/bin:$PATH
# export NODE_MIRROR=https://mirrors.ustc.edu.cn/node/

# # Add prioritized paths
# path=(
#   # Version managers (need to be before Homebrew)
#   "$HOME/.volta/bin" # Node.js version manager
#
#   # Other language-specific paths
#   "$HOME/.cargo/bin" # Rust
#   "$HOME/go/bin"     # Go
#
#   # System paths
#   "$HOME/.local/bin" # User local binaries
#   "$HOME/bin"        # User personal binaries
#
#   # Keep existing PATH (includes Homebrew)
#   $path
# )
#
export PATH
