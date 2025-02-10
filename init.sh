#!/usr/bin/env bash
# init.sh - Initialize or update a macOS (Apple Silicon) development environment with Zsh.
#           Incorporates ZDOTDIR => ~/.config/zsh by symlinking dotfiles/home/config/zsh.
#
# Usage: init.sh [--full] <init|update>
#   --full  : (optional) When specified with 'init' or 'update',
#             install all Homebrew packages from Brewfile.
#   init    : Perform first-time setup (install Homebrew, base packages,
#             dotfiles, shell config, macOS tweaks).
#   update  : Update dotfiles and Homebrew packages, re-apply config changes (maintenance).

set -euo pipefail # strict error handling

################################################################################
# GLOBAL CONFIG
################################################################################

DOTFILES_REPO="${DOTFILES_REPO:-"https://github.com/<your-username>/dotfiles.git"}"
DOTFILES_DIR="$HOME/dotfiles"

BACKUP_SUFFIX=".bak.$(date +'%Y%m%d%H%M%S')"
ZDOTDIR_TARGET="$HOME/.config/zsh" # We'll symlink dotfiles/home/config/zsh to here
BREWFILE_PATH="$DOTFILES_DIR/home/Brewfile"

################################################################################
# LOGGING & USAGE
################################################################################

log() {
  echo "$(date +'%Y-%m-%d %H:%M:%S') $*"
}

usage() {
  cat <<EOF
Usage: $0 [--full] <init|update>
  --full     Install all packages from Brewfile (~/dotfiles/home/Brewfile)
  init       First-time setup: Homebrew, dotfiles, shell, macOS tweaks
  update     Maintenance updates: pull dotfiles, upgrade brew, re-apply config
EOF
  exit 1
}

################################################################################
# ARG PARSING
################################################################################

MODE=""
FULL_BREW=false

[[ $# -eq 0 ]] && usage

for arg in "$@"; do
  case "$arg" in
  --full) FULL_BREW=true ;;
  init) MODE="init" ;;
  update) MODE="update" ;;
  -h | --help) usage ;;
  *)
    usage
    ;;
  esac
done

if [[ -z "$MODE" ]]; then
  usage
fi

################################################################################
# HELPER FUNCTIONS
################################################################################

# Backup an existing file or directory by renaming it with a timestamp suffix.
backup_item() {
  local item="$1"
  if [[ -e "$item" || -L "$item" ]]; then
    local backup_item="$item$BACKUP_SUFFIX"
    mv -f "$item" "$backup_item"
    log "Backed up $item -> $backup_item"
  fi
}

# 1) Check for Homebrew and install if missing.
install_homebrew() {
  if command -v brew &>/dev/null; then
    log "Homebrew is already installed."
  else
    log "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    log "Homebrew installed successfully."

    # Add brew to PATH for the rest of the script
    if [[ -x "/opt/homebrew/bin/brew" ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x "/usr/local/bin/brew" ]]; then
      eval "$(/usr/local/bin/brew shellenv)"
    fi
  fi
}

# 2) Update/upgrade Homebrew packages
update_homebrew() {
  log "Updating Homebrew formulae..."
  brew update
  log "Upgrading installed Homebrew packages..."
  brew upgrade
  brew cleanup
}

# 3) Perform Brewfile installation if --full is requested
brew_full_install() {
  if [[ -f "$BREWFILE_PATH" ]]; then
    log "Installing all packages from Brewfile: $BREWFILE_PATH"
    brew bundle --file="$BREWFILE_PATH"
  else
    log "Brewfile not found at $BREWFILE_PATH. Skipping full install."
  fi
}

# 4) Clone or update the dotfiles repo
sync_dotfiles_repo() {
  if [[ -d "$DOTFILES_DIR" ]]; then
    # If it's a git repo, pull updates
    if [[ -d "$DOTFILES_DIR/.git" ]]; then
      log "Updating dotfiles repo at $DOTFILES_DIR..."
      git -C "$DOTFILES_DIR" pull --ff-only || log "Warning: could not pull latest changes."
    else
      log "Directory $DOTFILES_DIR exists but is not a git repo. Skipping git pull."
    fi
  else
    log "Cloning dotfiles repo from $DOTFILES_REPO to $DOTFILES_DIR..."
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
  fi
}

# 5) Symlink non-Zsh dotfiles in ~/dotfiles/home/* into $HOME (except 'config')
#    Because Zsh config is handled separately.
link_home_dotfiles() {
  local home_dir="$DOTFILES_DIR/home"
  [[ ! -d "$home_dir" ]] && log "No ~/dotfiles/home directory found. Skipping home dotfiles symlink." && return

  log "Linking standard dotfiles from $home_dir into \$HOME..."
  shopt -s nullglob dotglob
  for item in "$home_dir"/*; do
    local base="$(basename "$item")"
    # Skip the "config" directory, as we'll handle that separately for zsh
    [[ "$base" == "config" ]] && continue
    [[ "$base" == "Brewfile" ]] && continue # handled separately
    [[ "$base" == *.nix ]] && continue  # match all nix files(Without quotes around pattern)
    local dest="$HOME/$base"

    if [[ -L "$dest" ]]; then
      # Already a symlink
      if [[ "$(readlink "$dest")" == "$item" ]]; then
        log "~/$base is already symlinked. Skipping."
        continue
      else
        backup_item "$dest"
      fi
    elif [[ -e "$dest" ]]; then
      backup_item "$dest"
    fi

    ln -s "$item" "$dest"
    log "Symlinked $dest -> $item"
  done
  shopt -u nullglob dotglob
}

# 6) Symlink zsh config directory (dotfiles/home/config/zsh) to ~/.config/zsh
#    Then ensure we set ZDOTDIR via ~/.zshenv
setup_zdotdir() {
  local zsh_dir="$DOTFILES_DIR/home/config/zsh"
  if [[ ! -d "$zsh_dir" ]]; then
    log "Zsh config directory not found at $zsh_dir. Skipping."
    return
  fi

  # Ensure ~/.config directory
  mkdir -p "$HOME/.config"

  # Backup existing ~/.config/zsh (if it exists) and symlink
  if [[ -L "$ZDOTDIR_TARGET" ]]; then
    if [[ "$(readlink "$ZDOTDIR_TARGET")" == "$zsh_dir" ]]; then
      log "~/.config/zsh is already symlinked to dotfiles. Skipping."
    else
      backup_item "$ZDOTDIR_TARGET"
      ln -s "$zsh_dir" "$ZDOTDIR_TARGET"
      log "Symlinked ~/.config/zsh -> $zsh_dir"
    fi
  elif [[ -e "$ZDOTDIR_TARGET" ]]; then
    backup_item "$ZDOTDIR_TARGET"
    ln -s "$zsh_dir" "$ZDOTDIR_TARGET"
    log "Symlinked ~/.config/zsh -> $zsh_dir"
  else
    ln -s "$zsh_dir" "$ZDOTDIR_TARGET"
    log "Symlinked ~/.config/zsh -> $zsh_dir"
  fi

  # Now ensure ~/.zshenv sets ZDOTDIR. We'll append if it's not present.
  local main_zshenv="$HOME/.zshenv"
  if [[ -f "$main_zshenv" ]]; then
    if grep -q "ZDOTDIR=" "$main_zshenv"; then
      log "Detected ZDOTDIR in ~/.zshenv. No update needed."
    else
      echo "export ZDOTDIR=\"$ZDOTDIR_TARGET\"" >>"$main_zshenv"
      echo "[[ -f \$ZDOTDIR/.zshenv ]] && source \$ZDOTDIR/.zshenv" >>"$main_zshenv"
      log "Appended ZDOTDIR config to ~/.zshenv."
    fi
  else
    cat <<EOF >"$main_zshenv"
# Minimal stub for Zsh to load configs from ~/.config/zsh
export ZDOTDIR="$ZDOTDIR_TARGET"
[[ -f "\$ZDOTDIR/.zshenv" ]] && source "\$ZDOTDIR/.zshenv"
EOF
    log "Created ~/.zshenv that sets ZDOTDIR -> $ZDOTDIR_TARGET"
  fi
}

# 7) Change default shell to Homebrew Zsh if not already set
setup_shell() {
  local brew_zsh
  brew_zsh="$(brew --prefix)/bin/zsh"
  if [[ ! -x "$brew_zsh" ]]; then
    log "Homebrew zsh not found at $brew_zsh. Skipping shell change."
    return
  fi

  # Add brew zsh to /etc/shells if missing
  if ! grep -Fxq "$brew_zsh" /etc/shells; then
    log "Adding $brew_zsh to /etc/shells (requires sudo)..."
    echo "$brew_zsh" | sudo tee -a /etc/shells >/dev/null
  fi

  # If current shell is not brew zsh, chsh
  if [[ "$SHELL" != "$brew_zsh" ]]; then
    log "Changing default shell to $brew_zsh. You may be prompted for your password."
    chsh -s "$brew_zsh" "$USER" || log "Could not change shell. Try manually: chsh -s $brew_zsh"
  else
    log "Default shell is already set to $brew_zsh."
  fi
}

# 8) Apply macOS preference tweaks
apply_macos_tweaks() {
  log "Applying macOS preference tweaks (Finder, Dock, keyboard)..."
  # Finder
  defaults write com.apple.finder AppleShowAllFiles -bool true
  defaults write NSGlobalDomain AppleShowAllExtensions -bool true
  defaults write com.apple.finder ShowPathbar -bool true
  defaults write com.apple.finder ShowStatusBar -bool true
  # Dock
  defaults write com.apple.dock autohide -bool true
  defaults write com.apple.dock autohide-delay -float 0
  defaults write com.apple.dock autohide-time-modifier -float 0.5
  defaults write com.apple.dock show-recents -bool false
  # Keyboard
  defaults write NSGlobalDomain KeyRepeat -int 1
  defaults write NSGlobalDomain InitialKeyRepeat -int 10
  defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
  defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
  defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

  # Restart Finder and Dock if running
  if pgrep Finder >/dev/null; then
    killall Finder || true
  fi
  if pgrep Dock >/dev/null; then
    killall Dock || true
  fi
  log "macOS tweaks applied."
}

################################################################################
# MAIN LOGIC
################################################################################

if [[ "$MODE" == "init" ]]; then
  log "===== INIT MODE: First-time setup ====="
  install_homebrew

  if $FULL_BREW; then
    brew_full_install
  else
    log "--full not specified; skipping Brewfile-based install."
  fi

  # Sync the repo (either clone or pull)
  sync_dotfiles_repo
  # Link standard dotfiles from ~/dotfiles/home (except 'config')
  link_home_dotfiles
  # Set up ~/.config/zsh with $ZDOTDIR
  setup_zdotdir
  # Change default shell to brew zsh
  setup_shell
  # Apply macOS tweaks
  apply_macos_tweaks

  log "===== INIT COMPLETE ====="

elif [[ "$MODE" == "update" ]]; then
  log "===== UPDATE MODE: Maintenance ====="
  install_homebrew
  # Pull changes in repo
  sync_dotfiles_repo
  # Re-link any new/modified dotfiles
  link_home_dotfiles
  # Make sure ZDOTDIR is correct
  setup_zdotdir
  # Update & upgrade Homebrew
  update_homebrew
  # Full Brewfile install if needed
  if $FULL_BREW; then
    brew_full_install
  fi
  # Re-apply macOS tweaks (idempotent)
  apply_macos_tweaks

  log "===== UPDATE COMPLETE ====="
else
  usage
fi
jk
