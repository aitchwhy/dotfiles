#!/usr/bin/env bash
set -euo pipefail

# TODO: https://randomgeekery.org/config/shell/zsh/

#######################################
# Logging Helpers
#######################################
log_info() {
  echo -e "[\033[34mINFO\033[0m]  $*"
}

log_success() {
  echo -e "[\033[32mSUCCESS\033[0m]  $*"
}

log_error() {
  echo -e "[\033[31mERROR\033[0m]  $*" >&2
}

#######################################
# Ensures a directory exists; if not, creates it
#######################################
ensure_dir() {
  if [[ ! -d "$1" ]]; then
    mkdir -p "$1"
    log_info "Created directory $1"
  fi
}

#######################################
# Backs up file if it exists, appends .backup timestamp
#######################################
backup_if_exists() {
  local file="$1"
  if [[ -L "$file" || -f "$file" ]]; then
    local backup="${file}.$(date +%s).backup"
    mv "$file" "$backup"
    log_info "Backed up $file to $backup"
  fi
}

#######################################
# Setup XDG base directories
#######################################
setup_xdg() {
  log_info "Ensuring XDG directories exist..."
  ensure_dir "${HOME}/.config"
  ensure_dir "${HOME}/.cache"
  ensure_dir "${HOME}/.local/share"
  ensure_dir "${HOME}/.local/state"
}

#######################################
# Install/update Homebrew, then run Brewfile if present
#######################################
setup_brew() {
  if ! command -v /opt/homebrew/bin/brew &>/dev/null; then
    log_info "Homebrew not found. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  else
    log_info "Homebrew found at: $(command -v brew)"
  fi

  if [[ -f "${HOME}/dotfiles/Brewfile" ]]; then
    log_info "Installing packages from Brewfile..."
    brew bundle --file="${HOME}/dotfiles/Brewfile" || {
      log_error "Brewfile install failed."
      exit 1
    }
  else
    log_info "No Brewfile found in ~/dotfiles; skipping brew bundle."
  fi
}

#######################################
# Configure Zsh using XDG paths and dotfiles structure
#######################################
setup_zsh() {
  log_info "Setting up Zsh..."

  local dotfiles_dir="${HOME}/dotfiles"
  local dotfiles_zsh="${dotfiles_dir}/home/config/zsh"
  local zsh_config="${HOME}/.config/zsh"
  local state_dir="${HOME}/.local/state/zsh"
  local cache_dir="${HOME}/.cache/zsh"

  # Create necessary directories
  ensure_dir "$zsh_config"
  ensure_dir "$state_dir"
  ensure_dir "$cache_dir"
  ensure_dir "${zsh_config}/completions.d"

  # Backup existing ~/.zshenv, create a fresh one
  backup_if_exists "${HOME}/.zshenv"
  cat >"${HOME}/.zshenv" <<EOF
# Set XDG base dirs
export XDG_CONFIG_HOME="\${HOME}/.config"
export XDG_CACHE_HOME="\${HOME}/.cache"
export XDG_DATA_HOME="\${HOME}/.local/share"
export XDG_STATE_HOME="\${HOME}/.local/state"

# Direct zsh to look in ~/.config/zsh for config
export ZDOTDIR="\${XDG_CONFIG_HOME}/zsh"
. \$ZDOTDIR/.zshenv
EOF

  # ln -sf "${dotfiles_dir}/home/zshenv" "${HOME}/.zshenv"
  # log_info "Symlinked ${dotfiles_dir}/home/zshenv to ${HOME}/.zshenv"

  # Install/Update Antidote
  local antidote_dir="${zsh_config}/.antidote"
  if [[ ! -d "$antidote_dir" ]]; then
    log_info "Installing Antidote..."
    git clone --depth=1 https://github.com/mattmc3/antidote.git "$antidote_dir"
  else
    log_info "Updating Antidote..."
    (cd "$antidote_dir" && git pull --rebase --autostash)
  fi

  # Symlink all Zsh config files
  local zsh_files=(
    ".zprofile"
    ".zshrc"
    "aliases.zsh"
    "env.zsh"
    "functions.zsh"
    "macos.zsh"
    "plugins.txt"
  )

  for fname in "${zsh_files[@]}"; do
    local source_file="${dotfiles_zsh}/${fname}"
    local target_file="${zsh_config}/${fname}"

    if [[ -f "$source_file" ]]; then
      backup_if_exists "$target_file"
      ln -sf "$source_file" "$target_file"
      log_info "Symlinked ${fname}"
    else
      log_error "File not found: $source_file. Skipping."
    fi
  done

  # Generate static plugins file
  if [[ -f "${zsh_config}/plugins.txt" ]]; then
    if command -v antidote &>/dev/null; then
      log_info "Generating .plugins.zsh from plugins.txt..."
      antidote bundle <"${zsh_config}/plugins.txt" >"${zsh_config}/.plugins.zsh"
    else
      log_info "Generating .plugins.zsh using local antidote..."
      sudo "${antidote_dir}/antidote.zsh" bundle <"${zsh_config}/plugins.txt" >"${zsh_config}/.plugins.zsh"
    fi
  fi

  log_success "Zsh configuration complete"
}

#######################################
# Main entry point
#######################################
main() {
  log_info "Starting dotfiles initialization..."

  setup_xdg
  setup_brew
  setup_zsh

  log_success "Dotfiles initialization complete!"
  log_info "Open a new terminal or run 'exec zsh' to load the new config."
}

main "$@"
