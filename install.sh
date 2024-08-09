#!/usr/bin/env bash

# Copy the default config file if not present already

############
# includes #
############

[ ! -f install_config ] && cp install_config.dist install_config

source ./install_config
source ./colors.sh
source ./install_functions.sh
source ./zsh/zshenv

################
# presentation #
################

echo -e "
${yellow}
          _ ._  _ , _ ._
        (_ ' ( \`  )_  .__)
      ( (  (    )   \`)  ) _)
     (__ (_   (_ . _) _) ,__)
           ~~\ ' . /~~
         ,::: ;   ; :::,
        ':::::::::::::::'
 ____________/_ __ \____________
|                               |
| Welcome to Phantas0s dotfiles |
|_______________________________|
"

echo -e "${yellow}!!! ${red}WARNING${yellow} !!!"
echo -e "${light_red}This script will delete all your configuration files!"
echo -e "${light_red}Use it at your own risks."

if [ $# -ne 1 ] || [ "$1" != "-y" ];
    then
        echo -e "${yellow}Press a key to continue...\n"
        read key;
fi

###########
# INSTALL #
###########

# Install
. "$DOTFILES/install/install-zsh.sh"
# . "$DOTFILES/install/install-from-cloud.sh"
# . "$DOTFILES/install/install-fonts.sh"
# . "$DOTFILES/install/install-X11.sh"

# dot_is_installed git && dot_install projects
# dot_is_installed lxappearance && dot_install theme
# dot_is_installed git && dot_install git
# dot_is_installed nvim && dot_install nvim
