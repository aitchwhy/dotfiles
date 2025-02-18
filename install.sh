#!/usr/bin/env bash
# install.sh - Main installation script

set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/dotfiles}"

source "$DOTFILES/utils.sh"

main() {
  info "Starting dotfiles installation..."

  # Create XDG directories
  ensure_dir "$XDG_CONFIG_HOME"
  ensure_dir "$XDG_CACHE_HOME"
  ensure_dir "$XDG_DATA_HOME"

  # Install Homebrew and packages
  # ensure_homebrew
  # brew_bundle "$@"

  # Setup ZSH
  setup_zsh

  # Link configuration file
  make_link "$DOTFILES_DIR/config/git/config" "$XDG_CONFIG_HOME/git/config"
  make_link "$DOTFILES_DIR/config/git/ignore" "$XDG_CONFIG_HOME/git/ignore"
  make_link "$DOTFILES_DIR/config/nvim" "$XDG_CONFIG_HOME/nvim"

  create_symlink "$DOTFILES/config/zsh" "$XDG_CONFIG_HOME/zsh"

  # Development tools
  create_symlink "$DOTFILES/config/nvim" "$XDG_CONFIG_HOME/nvim"
  # create_symlink "$DOTFILES/config/git" "$XDG_CONFIG_HOME/git"
  create_symlink "$DOTFILES/Brewfile" "$HOME/.Brewfile"

  # Terminal tools
  create_symlink "$DOTFILES/config/starship/starship.toml" "$XDG_CONFIG_HOME/starship.toml"
  create_symlink "$DOTFILES/config/atuin" "$XDG_CONFIG_HOME/atuin"
  create_symlink "$DOTFILES/config/bat" "$XDG_CONFIG_HOME/bat"
  create_symlink "$DOTFILES/config/zellij" "$XDG_CONFIG_HOME/zellij"

  # macOS apps
  if is_macos; then
    create_symlink "$DOTFILES/config/karabiner" "$XDG_CONFIG_HOME/karabiner"
    create_symlink "$DOTFILES/config/hammerspoon" "$HOME/.hammerspoon"

    # Handle paths with spaces
    # create_symlink "$DOTFILES/config/vscode/settings.json" "$HOME/Library/Application Support/Code/User/settings.json"
    # create_symlink "$DOTFILES/config/vscode/keybindings.json" "$HOME/Library/Application Support/Code/User/keybindings.json"
    create_symlink "$DOTFILES/config/vscode/settings.json" "$HOME/Library/Application Support/Code/User/settings.json"
    create_symlink "$DOTFILES/config/vscode/keybindings.json" "$HOME/$HOME/Library/Application Support/Code/User/keybindings.json"
    create_symlink "$DOTFILES/config/cursor/settings.json" "$HOME/Library/Application Support/Cursor/User/settings.json"
    create_symlink "$DOTFILES/config/cursor/keybindings.json" "$HOME/$HOME/Library/Application Support/Cursor/User/keybindings.json"
  fi

  success "Dotfiles installation complete!"
}

main "$@"

################

# #!/usr/bin/env bash
# # install.sh - Initial system setup and dotfiles installation
# set -euo pipefail
#
# # Load utilities
# DOTFILES="${DOTFILES:-$HOME/dotfiles}"
# source "$DOTFILES/utils.sh"
#
# # Script options
# FORCE=false
# DRY_RUN=false
# INSTALL_BREW=true
# CONFIGURE_MACOS=true
#
# # Process arguments
# while [[ $# -gt 0 ]]; do
#   case "$1" in
#   --force) FORCE=true ;;
#   --dry-run) DRY_RUN=true ;;
#   --no-brew) INSTALL_BREW=false ;;
#   --no-macos) CONFIGURE_MACOS=false ;;
#   --help)
#     echo "Usage: $0 [--force] [--dry-run] [--no-brew] [--no-macos]"
#     exit 0
#     ;;
#   *)
#     error "Unknown option: $1"
#     exit 1
#     ;;
#   esac
#   shift
# done
#
# # Setup Xcode Command Line Tools
# setup_xcode_tools() {
#   header "Checking Xcode Command Line Tools"
#   if ! xcode-select -p &>/dev/null; then
#     log "Installing Xcode Command Line Tools..."
#     xcode-select --install
#     log "Please complete the installation and run this script again."
#     exit 1
#   fi
#   success "Xcode Command Line Tools are installed"
# }
#
# # Setup Homebrew
# setup_homebrew() {
#   [[ "$INSTALL_BREW" != true ]] && return 0
#   header "Setting up Homebrew"
#
#   if ! command_exists brew; then
#     log "Installing Homebrew..."
#     /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
#
#     if is_apple_silicon; then
#       eval "$(/opt/homebrew/bin/brew shellenv)"
#     fi
#   fi
#
#   if [[ "$DRY_RUN" != true ]]; then
#     log "Updating Homebrew..."
#     brew update
#
#     log "Installing packages from Brewfile..."
#     brew bundle --file="$DOTFILES/Brewfile" || true
#   fi
# }
#
# # Setup Zsh environment
# setup_zsh() {
#   header "Setting up Zsh environment"
#   local zshenv="$HOME/.zshenv"
#
#   # Backup existing .zshenv
#   [[ -f "$zshenv" ]] && backup_file "$zshenv"
#
#   # Create minimal .zshenv
#   if [[ "$DRY_RUN" != true ]]; then
#     cat >"$zshenv" <<EOL
# # Minimal zsh configuration loader
# export ZDOTDIR="\$HOME/.config/zsh"
# [[ -f "\$ZDOTDIR/.zshenv" ]] && source "\$ZDOTDIR/.zshenv"
# EOL
#     success "Created $zshenv"
#   fi
# }
#
# # Core symlink setup
# setup_symlinks() {
#   header "Setting up symlinks"
#
#   # Shell configuration
#   create_symlink "$DOTFILES/config/zsh" "$XDG_CONFIG_HOME/zsh" "$FORCE"
#
#   # Core tools
#   create_symlink "$DOTFILES/config/git" "$XDG_CONFIG_HOME/git" "$FORCE"
#   create_symlink "$DOTFILES/config/nvim" "$XDG_CONFIG_HOME/nvim" "$FORCE"
#   create_symlink "$DOTFILES/config/starship/starship.toml" "$XDG_CONFIG_HOME/starship.toml" "$FORCE"
#   create_symlink "$DOTFILES/Brewfile" "$HOME/.Brewfile" "$FORCE"
#
#   # Terminal tools
#   create_symlink "$DOTFILES/config/bat" "$XDG_CONFIG_HOME/bat" "$FORCE"
#   create_symlink "$DOTFILES/config/atuin" "$XDG_CONFIG_HOME/atuin" "$FORCE"
#   create_symlink "$DOTFILES/config/zellij" "$XDG_CONFIG_HOME/zellij" "$FORCE"
#
#   # macOS-specific
#   if is_macos; then
#     create_symlink "$DOTFILES/config/karabiner" "$XDG_CONFIG_HOME/karabiner" "$FORCE"
#     create_symlink "$DOTFILES/config/hammerspoon" "$HOME/.hammerspoon" "$FORCE"
#
#     # VS Code
#     local vscode_dir="$HOME/Library/Application Support/Code/User"
#     ensure_dir "$vscode_dir"
#     create_symlink "$DOTFILES/config/vscode/settings.json" "$vscode_dir/settings.json" "$FORCE"
#     create_symlink "$DOTFILES/config/vscode/keybindings.json" "$vscode_dir/keybindings.json" "$FORCE"
#   fi
# }
#
# # Configure macOS defaults
# setup_macos() {
#   [[ "$CONFIGURE_MACOS" != true ]] && return 0
#   if ! is_macos; then
#     warn "Skipping macOS configuration on non-macOS system"
#     return 0
#   fi
#
#   header "Configuring macOS defaults"
#   if [[ "$DRY_RUN" != true ]]; then
#     # Import macOS settings
#     source "$DOTFILES/scripts/install/macos.sh"
#
#     # Restart affected applications
#     for app in "Finder" "Dock" "SystemUIServer"; do
#       killall "$app" &>/dev/null || true
#     done
#   fi
# }
#
# # Main installation
# main() {
#   header "Starting dotfiles installation"
#
#   # Initialize environment
#   init_env
#
#   # Run installation steps
#   setup_xcode_tools
#   setup_homebrew
#   setup_zsh
#   setup_symlinks
#   setup_macos
#
#   # Clean up
#   for dir in "$XDG_CONFIG_HOME" "$HOME"; do
#     clean_broken_links "$dir"
#   done
#
#   if [[ "$DRY_RUN" == true ]]; then
#     success "Dry run completed"
#   else
#     success "Installation completed!"
#     [[ -d "$BACKUP_DIR" ]] && log "Backups stored in: $BACKUP_DIR"
#     log "Please restart your shell for changes to take effect"
#   fi
# }
#
# main "$@"
