# -----------------------------------------------------------------------------
# ~/.zprofile (Invoked once at login on macOS)
# -----------------------------------------------------------------------------

# ============================================================================ #
# XDG
# ============================================================================ #
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"



# Reusable Function
_add_to_path_if_exists() {
  local dir="$1"
  local position="${2:-append}"  # default is 'append'

  # Skip if the directory doesn’t exist
  [[ -d "$dir" ]] || return

  # Skip if already in PATH
  [[ ":$PATH:" == *":$dir:"* ]] && return

  if [[ "$position" == "prepend" ]]; then
    path=("$dir" $path)
  else
    path+=("$dir")
  fi
}

# 1. Homebrew (Apple Silicon) init (Homebrew docs recommend adding directly)
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi


# PATH Configuration
typeset -U path PATH  # Ensure unique entries


# Node.js (Volta)
export VOLTA_HOME="$HOME/.volta"
_add_to_path_if_exists "$VOLTA_HOME/bin" "prepend"

# Bun JavaScript runtime
export BUN_INSTALL="$HOME/.bun"
_add_to_path_if_exists "$BUN_INSTALL/bin" "prepend"

# Additional Cloud CLIs (Outside Brew)
_add_to_path_if_exists "$HOME/google-cloud-sdk/bin" "append"

# Ruby
if [ -d "/opt/homebrew/opt/ruby/bin" ]; then
  _add_to_path_if_exists "/opt/homebrew/opt/ruby/bin" "prepend"
  _add_to_path_if_exists "`gem environment gemdir`/bin" "Prepend"
  # export PATH=/opt/homebrew/opt/ruby/bin:$PATH
  # export PATH=`gem environment gemdir`/bin:$PATH
fi
# _add_to_path_if_exists "$HOMEBREW_PREFIX/opt/ruby/bin"
# _add_to_path_if_exists "$(gem environment gemdir)/bin"
# if command -v gem &>/dev/null; then
#   gem_bin="$(gem environment gemdir)/bin"
#   _add_to_path_if_exists "$gem_bin"
# fi

###############################
# 6. Personal Scripts
###############################
_add_to_path_if_exists "$HOME/.local/bin"
# _add_to_path_if_exists "$HOME/bin"

###############################
# Final pass to remove duplicates
###############################
typeset -U PATH path

