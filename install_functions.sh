#!/usr/bin/env bash

function dot_mes_red() {
    echo -e "${red} ${1}"
}

function dot_mes() {
    echo -e "${1} ${2}"
}

function dot_mes_install() {
    dot_mes ${green} "--> Installing ${1}"
}

function dot_mes_update() {
    dot_mes ${yellow} "--> Updating ${1}"
}

function dot_mes_warn() {
    echo -e "${red}/!\  ${1} /!\ "
}

function dot_install() {
    echo -e "${blue}-> Installing ${yellow}${1} ${blue}config"
    . "$DOTFILES/install/install-${1}.sh"
}

function dot_install_func() {
    echo -e "${blue}-> Installing ${yellow}${1} ${blue}config"
    . $DOTFILES/install/install-${1}.sh
    ${2}
}

function dot_sub_install() {
    echo -e "${green}--> Installing ${1}"
}


function dot_is_installed() {
    command -v $1 >/dev/null
}

# custom functions
# symlink
slink() {
    local src_orig=$1
    local dst_link=$2
    local dst_dir=$(dirname "$dst_link")

    # Create the directory if it does not exist
    mkdir -p "$dst_dir"

    # Create the symlink
    ln -nfs "$src_orig" "$dst_link"
}

# slink_init() {
#     slink $DOTFILES/.Brewfile $HOME/.Brewfile
#     slink $DOTFILES/.zshrc $HOME/.zshrc

#     slink $DOTFILES_EXPORTS $OMZ_CUSTOM/exports.zsh
#     slink $DOTFILES_ALIASES $OMZ_CUSTOM/aliases.zsh
#     slink $DOTFILES_FUNCTIONS $OMZ_CUSTOM/functions.zsh

#     slink $DOTFILES/nvm/default-packages $NVM_DIR/default-packages
#     slink $DOTFILES/config/git/.gitignore $HOME/.gitignore
# }


# yazi
function yy() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}
