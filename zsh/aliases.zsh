alias dots='cd $DOTFILES'
alias brewedit='vim $DOTFILES/Brewfile'
alias brewls='ls -al $BREWFILE_GLOBAL'
alias brewinstall='brew bundle install --global'
alias brewcleanup='brew bundle cleanup --global'
alias brewdump='brew bundle dump --global'

#############################################
# zsh
#############
# oh-my-zsh NOTES
#
# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
#############################################

alias zshrc='vim ~/.zshrc'

# TODO: Zsh + iterm 2 setup (snazzy) - https://github.com/sindresorhus/iterm2-snazzy


#############################################
# vim + neovim
#############################################
alias vi=nvim
alias vim=nvim

# upgrade to modern
alias ps='procs'
alias ping='gping'
alias diff=''
alias ls='eza'
alias cheat='navi'
alias net='trippy'
alias netviz='netop'
alias jwt='jet-ui'
alias sed='sd'
alias du='dust'
alias ssh='sshs'
alias s3='stu'

alias jsonfilter='jnv'
alias jsonviewer='jnv'
alias dots='cd $DOTFILES'
alias brewedit='vim $DOTFILES/Brewfile'
alias brewls='ls -al $BREWFILE_GLOBAL'


alias brewsave='brew bundle install --global --all'
alias brewclean='brew bundle cleanup --global --all --force'
alias brewdiff='brew bundle cleanup --global --all'
alias brewsave='brew bundle dump --global --all --force --describe --debug'

alias zshrc='vim ~/.zshrc'

# TODO: Zsh + iterm 2 setup (snazzy) - https://github.com/sindresorhus/iterm2-snazzy


#############################################
# vim + neovim
#############################################
alias vi=nvim
alias vim=nvim

#############################################
# k8s kubernetes + docker + containers
#############################################
alias k=k9s

