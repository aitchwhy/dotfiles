# ========================================================================
# Homebrew Package Management
# ========================================================================
# A comprehensive set of utilities for managing Homebrew packages
# https://brew.sh

# ========================================================================
# Core Homebrew Setup & Detection
# ========================================================================

# Check if Homebrew is available
function has_brew() {
    command -v brew >/dev/null 2>&1
}

# Install Homebrew if not already installed
if ! command -v brew &>/dev/null; then
    log_info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add to PATH for current session if installed
    if [[ "$(uname -m)" == "arm64" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        eval "$(/usr/local/bin/brew shellenv)"
    fi
fi

# Set environment variables for Homebrew
export HOMEBREW_NO_ANALYTICS=1  # Disable Homebrew analytics
export HOMEBREW_BAT=1           # Use bat for man pages
export HOMEBREW_CASK_OPTS="--appdir=${HOME}/Applications --fontdir=/Library/Fonts"

# ========================================================================
# Basic Brew Management Functions
# ========================================================================

# Update all Homebrew packages
function update_brew() {
    if has_brew; then
        log_info "Updating Homebrew..."
        brew update
        brew upgrade
        brew cleanup
    fi
}

# ========================================================================
# Advanced Brew Management (bb function)
# ========================================================================
function bb() {
  # Function to display help text
  _bb_help() {
    local cmd_list=$(grep -E '^\s+[a-z|,-]+\)' <<< "$(declare -f bb)" |
      sed 's/)//' | sed 's/|/, /g' | sort)

    echo "Usage: bb [command]"
    echo ""
    echo "Regular Brew Commands:"
    grep -E '^\s+[a-z|,-]+\) # Regular:' <<< "$(declare -f bb)" |
      sed 's/)//' | sed 's/|/, /g' |
      sed -E 's/^\s+([a-z, -]+) # Regular: (.*)/  \1\t- \2/' |
      sort

    echo ""
    echo "Interactive Commands:"
    grep -E '^\s+[a-z|,-]+\) # Interactive:' <<< "$(declare -f bb)" |
      sed 's/)//' | sed 's/|/, /g' |
      sed -E 's/^\s+([a-z, -]+) # Interactive: (.*)/  \1\t- \2/' |
      sort

    echo ""
    echo "Brewfile Commands:"
    grep -E '^\s+[a-z|,-]+\) # Brewfile:' <<< "$(declare -f bb)" |
      sed 's/)//' | sed 's/|/, /g' |
      sed -E 's/^\s+([a-z, -]+) # Brewfile: (.*)/  \1\t- \2/' |
      sort
  }

  # Function for interactive package operations
  _bb_interactive() {
    local mode="$1"
    local header="$2"
    local preview_cmd="$3"
    local install_cmd="$4"
    local brewfile_prefix="$5"
    local search_cmd="$6"

    local selected
    local brewfile="${BREWFILE:-$HOME/.Brewfile}"

    selected=$(eval "$search_cmd" | fzf -m --header="$header" --preview="$preview_cmd" --preview-window=:hidden --bind=space:toggle-preview)

    if [[ -n "$selected" ]]; then
      echo "The following will be ${mode}ed:"
      echo "$selected"
      echo ""
      echo "Proceed? (y/n)"
      read -q proceed

      if [[ "$proceed" == "y" ]]; then
        echo "\n${mode^}ing..."
        eval "$install_cmd $selected"

        # Add to Brewfile if installing
        if [[ "$mode" == "install" && -n "$brewfile_prefix" ]]; then
          # Create Brewfile if it doesn't exist
          if [[ ! -f "$brewfile" ]]; then
            touch "$brewfile"
          fi

          # Add each package to Brewfile if not already there
          for pkg in ${(f)selected}; do
            if ! grep -q "^$brewfile_prefix \"$pkg\"$" "$brewfile"; then
              echo "$brewfile_prefix \"$pkg\"" >> "$brewfile"
              echo "Added $pkg to Brewfile"
            fi
          done

          echo "${mode^}ed and Brewfile updated."
        else
          echo "${mode^}ed successfully."
        fi
      else
        echo "\nOperation cancelled."
      fi
    else
      echo "Nothing selected."
    fi
  }

  if [[ "$1" == "help" || -z "$1" ]]; then
    _bb_help
    return 0
  fi

  case "$1" in
    # Regular brew commands
    up|update) # Regular: Update and upgrade all packages
      brew update && brew upgrade && brew cleanup --scrub
      ;;
    in|install) # Regular: Install a package
      brew install "$2"
      ;;
    s|search) # Regular: Search for a package
      brew search "$2"
      ;;
    ini|cask) # Regular: Install a cask
      brew install --cask "$2"
      ;;
    info) # Regular: Show info about a package
      brew info "$2"
      ;;
    rm|remove) # Regular: Remove a package
      brew uninstall "$2"
      ;;
    ls|list) # Regular: List installed packages
      brew list
      ;;
    doc|doctor) # Regular: Run brew diagnostics
      brew doctor && brew missing
      ;;
    deps) # Regular: Show dependency tree for a package
      brew deps --tree --installed "${2:-}"
      ;;
    leaves) # Regular: List installed formulae that aren't dependencies
      brew leaves
      ;;

    # Interactive commands with fzf
    rmi) # Interactive: Remove packages interactively
      _bb_interactive "remove" "Select packages to remove (use TAB to select multiple)" "brew info {}" "brew remove" "" "brew list"
      ;;
    insi) # Interactive: Install packages interactively
      _bb_interactive "install" "Select packages to install (use TAB to select multiple)" "brew info {}" "brew install" "brew" "brew search"
      ;;
    caski) # Interactive: Install casks interactively
      _bb_interactive "install" "Select casks to install (use TAB to select multiple)" "brew info --cask {}" "brew install --cask" "cask" "brew search --casks"
      ;;

    # Brewfile commands
    bundle-install|bi) # Brewfile: Install Brewfile bundles
      brew bundle install --verbose --global --all --cleanup
      ;;
    bundle-sudo|bs) # Brewfile: Install Brewfile bundles with sudo
      sudo brew bundle install --verbose --global --all --no-lock --cleanup --force
      ;;
    bundle-check|bc) # Brewfile: Check if all dependencies are installed
      brew bundle check --verbose --global --all
      ;;
    bundle-dump|bd) # Brewfile: Save current packages to Brewfile
      brew bundle dump --verbose --global --all --force
      ;;
    bundle-list|bl) # Brewfile: Show packages not in Brewfile
      brew bundle cleanup --verbose --global --all --zap
      ;;
    bundle-clean|bclean) # Brewfile: Remove packages not in Brewfile
      brew bundle cleanup --verbose --global --all --zap --force
      ;;
    bundle-edit|be) # Brewfile: Edit global Brewfile
      brew bundle edit --global
      ;;
    bundle-outdated|bo) # Brewfile: Show outdated packages in Brewfile
      brew bundle outdated --verbose --global
      ;;

    # Unknown command
    *)
      echo "Unknown command: $1"
      _bb_help
      return 1
      ;;
  esac
}

# ========================================================================
# Homebrew Convenience Aliases
# ========================================================================
# Uncomment the ones you want to use

# alias brewup='bb up'      # Update and upgrade packages
# alias brewi='bb insi'     # Interactive install
# alias caski='bb caski'    # Interactive cask install
# alias bi='bb bi'          # Install from Brewfile
# alias be='bb be'          # Edit Brewfile

# Completions setup
# if type brew &>/dev/null; then
# 	FPATH=$(brew --prefix)/share/zsh-abbr:$FPATH
# 	autoload -Uz compinit
# 	compinit
# fi
