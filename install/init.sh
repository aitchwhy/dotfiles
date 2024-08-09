#!/bin/bash

# TODO: getting hostname (scutil --get LocalHostName) :  https://github.com/LnL7/nix-darwin/blob/master/README.md#flakes
export GIT_USER="aitchwhyz"

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

install_nix() {
    # Installer -> https://github.com/DeterminateSystems/nix-installer?tab=readme-ov-file#usage
    # (generic) curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install macos
    # (pre-install) curl -sL -o nix-installer https://install.determinate.systems/nix/nix-installer-aarch64-darwin
    # ./nix-installer-aarch64-darwin-v0.19.0 install macos --no-confirm --verbose --force --diagnostic-endpoint "" --explain
    # echo "check installation by running (nix --version)"
}

uninstall_nix() {
    # Installer -> https://github.com/DeterminateSystems/nix-installer?tab=readme-ov-file#usage
    /nix/nix-installer uninstall
}

install_nix_darwin() {

    # dotfiles generated from flake template 'nix-darwin' initially (see https://nixcademy.com/2024/01/15/nix-on-macos/)
    # $ nix flake init -t nix-darwin

    # (local) nix-darwin flakes install (https://github.com/LnL7/nix-darwin?tab=readme-ov-file#flakes)
    # $ nix run nix-darwin -- switch -I darwin-config=./darwin/darwin.nix --flake .
    # $ darwin-rebuild switch ....(same as 1st time)
}

############################################
# Nix
############################################

install_nix

install_nix_darwin

# if ! command_exists nix; then
#     exit 1
# fi

exit 0

# ############################################
# # Core
# ############################################

# export BREW_PREFIX="/opt/homebrew"

# # Install homebrew (if not exist)
# if ! command_not_exists brew; then
#     curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh
# fi

# # - Run this command in your terminal to add Homebrew to your PATH:
#     # eval "$(/opt/homebrew/bin/brew shellenv)"

# ############################################
# # Zsh
# ############################################

# # change default shell to zsh
# chsh -s "/bin/zsh"
# # plugins
# # https://github.com/unixorn/awesome-zsh-plugins?tab=readme-ov-file#plugins

# # zplug
# # https://blog.woefe.com/posts/bootstrap_zsh.html
# # https://blog.woefe.com/posts/bootstrap_zsh.html

# ############################################3
# # pkgx.dev - install/run ANYTHING (https://docs.pkgx.sh/)
# # packages list : https://dist.pkgx.dev/
# ############################################3

# # install/run ANYTHING (https://docs.pkgx.sh/)-  packages list : https://dist.pkgx.dev/
# brew install pkgxdev/made/pkgx

# # tmux + termuxinator
# # https://github.com/tmuxinator/tmuxinator

# # install zplug (z plugin manager)
# if [[ ! -d ~/.zplug]]

# ############################################3
# # Zsh setup
# ############################################3

# # TODO: brew packages from brew bundle file
# # TODO: https://github.com/jamesob/desk

####################################
# # (May 2 2024) from dotfiles/README
# - (blank state)
# - webi (web installer scripts) : to get started installing basic setup
#   - install webi : `curl -sS https://webi.sh/webi | sh`
#   - core tools using webi
#     - git+curl (for asdf)
#     - brew
#     - pathman
#     - aliasman
# - asdf (tooling manager)
#   - (Git method) asdf download : `git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.0`
#   - (chezmoi should do this but just in case) setup asdf by appending to `.zshrc` the line `. "$HOME/.asdf/asdf.sh"`
#   - install asdf-chezmoi for dotfiles and pull from personal GH dotfiles Github Repo (this project hosted on cloud)
# - chezmoi (dotfiles manager) : keeps dotfiles synced between machines
#   - NOTE: uses "dotfiles/darwin" as chezmoi root when pulling from remote Github repo (configured by "dotfiles/.chezmoiroot" - `https://www.chezmoi.io/user-guide/advanced/customize-your-source-directory/`)
#   - on chezmoi init (from GH dotfiles repo) install and configure secrets+credentials using Password Manager Bitwarden + CLI
#     - (`https://www.chezmoi.io/user-guide/password-managers/bitwarden/`) + (`https://www.chezmoi.io/user-guide/advanced/install-your-password-manager-on-init/`)
#     - secrets (SSH, AWS, GH, etc) setup on local filesystem via from Bitwarden CLI
# - asdf (again but this time install ALL tools from chezmoi pulled dotfile `.asdfrc` + `$HOME/too-versions`)
#   - core tools like (iterm2 + nerdfont + dotenv + watchexec + bat + curlie + delta + eza + zoxide + vim + direnv + jq + atuin + rg + etc)
# - (TODO) Nix + Homebrew for rest of setup
#   - Nix
#     - nix-darwin (Mac configs)
#     - home-manager (`https://github.com/nix-community/home-manager`) + `https://home-manager-options.extranix.com/`
#       - `https://github.com/breuerfelix/dotfiles/tree/main/home-manager`
#       - `https://github.com/juspay/nix-dev-home`j
#       - `https://devenv.sh/`
#       - `https://flakehub.com/`
####################################

# # -------------------------------------------------
# # Install 'webi' installer (https://webinstall.dev/)
# # -------------------------------------------------
# curl -sS https://webi.sh/webi | sh

# # # Edit ~/.config/envman/PATH.env to add ~/.local/bin
# # echo -e "export PATH=\"$HOME/.local/bin:$PATH\"" >> ~/.config/envman/PATH.env

# # Reload PATH with envman
# source ~/.config/envman/PATH.env

# # -------------------------------------------------
# # Install core packages using webi installer
# # -------------------------------------------------
# # general
# webi aliasman
# webi pathman

# # asdf dependencies
# webi git
# webi curlie

# # -------------------------------------------------
# # Configure path aliases (aliasman + pathman)
# # -------------------------------------------------
# aliasman curl 'curlie'
# aliasman vim 'nvim'
# source ~/.config/envman/PATH.env

# # -------------------------------------------------
# # Install 'asdf' tool manager (https://asdf-vm.com/)
# # -------------------------------------------------
# git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.0

# echo -e ". \"$HOME/.asdf/asdf.sh\"" >> ~/.bashrc
# echo -e ". \"$HOME/.asdf/asdf.sh\"" >> ~/.zshrc

# # -------------------------------------------------
# # Install Chezmoi dotfile manager (https://www.chezmoi.io/)
# # -------------------------------------------------
# asdf plugin add chezmoi && asdf install chezmoi 2.48.0

# # -------------------------------------------------
# # Run dotfiles config with chezmoi
# # -------------------------------------------------
# # chezmoi init --apply --verbose https://github.com/$GITHUB_USERNAME/dotfiles.git
