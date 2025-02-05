#!/bin/bash

#------------------------------------------------------------------------------
# Mac Bootstrap Script (Apple Silicon)
# Sequence: XCode CLT → System Updates → Homebrew → Chezmoi → GitHub/Bitwarden → Dotfiles
#------------------------------------------------------------------------------

set -e

# Colors and Logging
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

#------------------------------------------------------------------------------
# Install Xcode Command Line Tools
#------------------------------------------------------------------------------
install_xcode_clt() {
    log "Checking for Xcode Command Line Tools..."
    if ! xcode-select -p &> /dev/null; then
        log "Installing Xcode Command Line Tools..."
        xcode-select --install
        echo "Please complete the installation prompt and press any key to continue..."
        read -n 1
        success "Xcode Command Line Tools installed"
    else
        success "Xcode Command Line Tools already installed"
    fi
}

#------------------------------------------------------------------------------
# Run System Updates
#------------------------------------------------------------------------------
run_system_updates() {
    log "Checking for system updates..."
    softwareupdate --install --all --agree-to-license
    success "System updates completed"
}

#------------------------------------------------------------------------------
# Install Homebrew
#------------------------------------------------------------------------------
install_homebrew() {
    if ! command -v brew &> /dev/null; then
        log "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        eval "$(/opt/homebrew/bin/brew shellenv)"
        success "Homebrew installed and configured"
    else
        success "Homebrew already installed"
    fi
}

#------------------------------------------------------------------------------
# Install Brewfile Packages
#------------------------------------------------------------------------------
install_packages() {
    if [ -f "$HOME/.Brewfile" ]; then
        log "Installing packages from Brewfile..."
        brew bundle install --global --verbose
        success "Packages installed"
    else
        error "Brewfile not found at ~/.Brewfile"
    fi
}

#------------------------------------------------------------------------------
# Install Core Tools
#------------------------------------------------------------------------------
install_core_tools() {
    log "Installing core tools..."
    brew install \
        chezmoi \
        gh \
        bitwarden-cli
    success "Core tools installed"
}

#------------------------------------------------------------------------------
# Setup GitHub CLI
#------------------------------------------------------------------------------
setup_github() {
    log "Setting up GitHub CLI..."
    if ! gh auth status &> /dev/null; then
        gh auth login --web
        success "GitHub CLI authenticated"
    else
        success "GitHub CLI already authenticated"
    fi
}

#------------------------------------------------------------------------------
# Setup Bitwarden
#------------------------------------------------------------------------------
setup_bitwarden() {
    log "Setting up Bitwarden CLI..."
    if ! bw login --check &> /dev/null; then
        echo "Please enter your Bitwarden email:"
        read BW_EMAIL
        
        bw login "$BW_EMAIL"
        export BW_SESSION=$(bw unlock --raw)
        
        success "Bitwarden CLI authenticated"
    else
        success "Bitwarden CLI already authenticated"
    fi
}

#------------------------------------------------------------------------------
# Initialize Dotfiles
#------------------------------------------------------------------------------
setup_dotfiles() {
    log "Initializing dotfiles with Chezmoi..."
    DOTFILES_REPO="github.com/$GH_USER/dotfiles"
    if [ ! -d "$HOME/.local/share/chezmoi" ]; then
        chezmoi init --apply "https://$DOTFILES_REPO.git"
        success "Dotfiles initialized and applied"
    else
        success "Dotfiles already initialized"
    fi
}

#------------------------------------------------------------------------------
# Tool Initialization
# TODO: source ~/.zshrc
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Main Installation Flow
#------------------------------------------------------------------------------
main() {
    log "Starting Mac bootstrap process..."

    install_xcode_clt
    run_system_updates
    install_homebrew
    install_core_tools
    setup_github
    setup_bitwarden
    setup_dotfiles
    install_packages

    success "Bootstrap complete!"
    echo
    echo "Next steps:"
    echo "1. Log out and back in to ensure all changes take effect"
    echo "2. Run 'source ~/.zprofile' to load new environment"
    echo "3. Check 'chezmoi status' to verify dotfiles state"
}
#
# # Execute
# main











############################################
# TODO: extract useful parts but mostly delete in future
############################################
#
# set -e
#
# log() { echo -e "\033[0;34m[INFO]\033[0m $1"; }
# success() { echo -e "\033[0;32m[SUCCESS]\033[0m $1"; }
# error() { echo -e "\033[0;31m[ERROR]\033[0m $1"; }
#
# #------------------------------------------------------------------------------
# # Install Xcode CLI Tools
# #------------------------------------------------------------------------------
# install_xcode() {
#     if ! xcode-select -p &> /dev/null; then
#         log "Installing Command Line Tools for Xcode..."
#         xcode-select --install
#         echo "Complete the installation and press any key to continue."
#         read -n 1
#     fi
#     success "Xcode CLI tools are installed"
# }
#
# #------------------------------------------------------------------------------
# # Install Homebrew
# #------------------------------------------------------------------------------
# install_homebrew() {
#     if ! command -v brew &> /dev/null; then
#         log "Installing Homebrew..."
#         /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
#         eval "$(/opt/homebrew/bin/brew shellenv)"
#     else
#         success "Homebrew is already installed"
#     fi
# }
#
# #------------------------------------------------------------------------------
# # Brewfile Install
# #------------------------------------------------------------------------------
# install_brewfile() {
#     log "Installing packages from Brewfile..."
#     brew bundle --file="$HOME/.local/share/chezmoi/Brewfile"
# }
#
#
# #------------------------------------------------------------------------------
# # Main Installation Flow
# #------------------------------------------------------------------------------
# main() {
#     install_xcode
#     install_homebrew
#     setup_chezmoi
#     install_brewfile
#     success "Mac setup complete!"
# }
#
# main
# #!/bin/bash
#
# #------------------------------------------------------------------------------
# # Comprehensive Mac Setup Script
# # - Xcode CLI tools
# # - Homebrew
# # - Bitwarden CLI
# # - Chezmoi with Bitwarden integration
# # - Development tools & apps
# # - Dotfiles management
# #------------------------------------------------------------------------------
#
# set -e # Exit on error
#
# # Colors for output
# RED='\033[0;31m'
# GREEN='\033[0;32m'
# BLUE='\033[0;34m'
# NC='\033[0m' # No Color
#
# log() { echo -e "${BLUE}[INFO]${NC} $1"; }
# success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
# error() { echo -e "${RED}[ERROR]${NC} $1"; }
#
# #------------------------------------------------------------------------------
# # Install Command Line Tools for Xcode
# #------------------------------------------------------------------------------
# install_xcode_clt() {
#     if ! xcode-select -p &> /dev/null; then
#         log "Installing Command Line Tools for Xcode..."
#         xcode-select --install
#
#         echo "Please complete the Command Line Tools installation and press any key to continue..."
#         read -n 1
#     else
#         success "Command Line Tools already installed"
#     fi
# }
#
# #------------------------------------------------------------------------------
# # Install Homebrew
# #------------------------------------------------------------------------------
# install_homebrew() {
#     if ! command -v brew &> /dev/null; then
#         log "Installing Homebrew..."
#         /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
#
#         if [[ "$(uname -m)" == "arm64" ]]; then
#             echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
#             eval "$(/opt/homebrew/bin/brew shellenv)"
#         else
#             echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile
#             eval "$(/usr/local/bin/brew shellenv)"
#         fi
#     else
#         success "Homebrew already installed"
#     fi
# }
#
# #------------------------------------------------------------------------------
# # Create Brewfile
# #------------------------------------------------------------------------------
# create_brewfile() {
#     cat > ~/.Brewfile << 'EOL'
# # Taps
# tap "homebrew/bundle"
# tap "homebrew/cask"
# tap "homebrew/core"
# tap "homebrew/services"
#
# # CLI Tools
# brew "antidote"          # ZSH plugin manager
# brew "bitwarden-cli"     # Password management
# brew "chezmoi"          # Dotfiles manager
# brew "eza"              # Modern ls
# brew "bat"              # Modern cat
# brew "ripgrep"          # Modern grep
# brew "fd"               # Modern find
# brew "fzf"              # Fuzzy finder
# brew "zoxide"           # Smart directory navigation
# brew "atuin"            # Shell history
# brew "starship"         # Shell prompt
# brew "git"              # Version control
# brew "gh"               # GitHub CLI
# brew "jq"               # JSON processor
# brew "mas"              # Mac App Store CLI
# brew "nvm"              # Node version manager
# brew "pyenv"            # Python version manager
# brew "tree"             # Directory tree view
# brew "wget"             # File downloader
#
# # Development
# brew "golang"
# brew "node"
# brew "python"
# brew "rust"
#
# # Applications
# cask "warp"             # Modern terminal
# cask "cursor"           # IDE
# cask "visual-studio-code"
# cask "docker"
# cask "google-chrome"
# cask "rectangle"        # Window management
# cask "alfred"           # Spotlight replacement
# cask "1password"        # Password manager
# cask "raycast"          # Productivity tool
#
# # Mac App Store
# mas "Xcode", id: 497799835
# EOL
#     success "Created Brewfile at ~/.Brewfile"
# }
#
# #------------------------------------------------------------------------------
# # Install Applications & Tools
# #------------------------------------------------------------------------------
# install_packages() {
#     log "Installing packages from Brewfile..."
#     brew bundle install --global --verbose
# }
#
# #------------------------------------------------------------------------------
# # Setup Bitwarden
# #------------------------------------------------------------------------------
# setup_bitwarden() {
#     log "Setting up Bitwarden CLI..."
#     if ! command -v bw &> /dev/null; then
#         brew install bitwarden-cli
#     fi
#
#     echo "Please enter your Bitwarden email:"
#     read BW_EMAIL
#
#     # Login to Bitwarden
#     bw login $BW_EMAIL
#
#     # Unlock vault and export session
#     export BW_SESSION=$(bw unlock --raw)
#
#     success "Bitwarden CLI setup complete"
# }
#
# #------------------------------------------------------------------------------
# # Setup Chezmoi with Bitwarden
# #------------------------------------------------------------------------------
# setup_chezmoi() {
#     log "Setting up Chezmoi..."
#     DOTFILES_REPO="github.com/yourusername/dotfiles"
#
#     if [ ! -d "$HOME/.local/share/chezmoi" ]; then
#         chezmoi init https://$DOTFILES_REPO.git
#
#         # Create chezmoi config with Bitwarden integration
#         cat > ~/.config/chezmoi/chezmoi.toml << EOL
# [bitwarden]
#     command = "bw"
# [data]
#     email = "${BW_EMAIL}"
# EOL
#
#         chezmoi apply
#     fi
# }
#
# #------------------------------------------------------------------------------
# # Create ZSH Configuration
# #------------------------------------------------------------------------------
# setup_zsh() {
#     log "Setting up ZSH configuration..."
#
#     # Create .zsh_plugins.txt
#     cat > ~/.zsh_plugins.txt << 'EOL'
# # Essential plugins
# zsh-users/zsh-autosuggestions
# zsh-users/zsh-syntax-highlighting
# zsh-users/zsh-completions
#
# # Oh-My-Zsh plugins
# ohmyzsh/ohmyzsh path:plugins/git
# ohmyzsh/ohmyzsh path:plugins/brew
# ohmyzsh/ohmyzsh path:plugins/docker
# ohmyzsh/ohmyzsh path:plugins/golang
# ohmyzsh/ohmyzsh path:plugins/node
# ohmyzsh/ohmyzsh path:plugins/python
#
# # Additional utilities
# jeffreytse/zsh-vi-mode
# Aloxaf/fzf-tab
# romkatv/powerlevel10k
# MichaelAquilina/zsh-you-should-use
# zdharma-continuum/fast-syntax-highlighting kind:defer
# EOL
# }
#
# #------------------------------------------------------------------------------
# # Setup Development Environment
# #------------------------------------------------------------------------------
# setup_dev_env() {
#     log "Setting up development environment..."
#
#     # Setup Node.js
#     mkdir -p ~/.nvm
#     nvm install --lts
#     nvm use --lts
#
#     # Setup Python
#     pyenv install 3.11
#     pyenv global 3.11
#
#     # Setup VS Code extensions
#     code --install-extension github.copilot
#     code --install-extension ms-python.python
#     code --install-extension golang.go
#     code --install-extension dbaeumer.vscode-eslint
#
#     success "Development environment setup complete"
# }
#
# #------------------------------------------------------------------------------
# # Main Installation Flow
# #------------------------------------------------------------------------------
# main() {
#     log "Starting Mac setup..."
#
#     install_xcode_clt
#     install_homebrew
#     create_brewfile
#     install_packages
#     setup_bitwarden
#     setup_chezmoi
#     setup_zsh
#     setup_dev_env
#
#     success "Installation complete!"
#
#     echo "Next steps:"
#     echo "1. Run 'source ~/.zprofile'"
#     echo "2. Run 'source ~/.zshrc'"
#     echo "3. Configure git:"
#     echo "   git config --global user.name 'Your Name'"
#     echo "   git config --global user.email 'your.email@example.com'"
#     echo "4. Set up SSH keys for GitHub"
#     echo "5. Configure Warp and Cursor IDE preferences"
# }
#
# # Run the script
# main
#
#
