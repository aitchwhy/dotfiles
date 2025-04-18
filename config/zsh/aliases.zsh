#!/usr/bin/env zsh

local DOTFILES="${DOTFILES:-$HOME/dotfiles}"

# justfile
alias j="just"
# alias .j='just -g'
# alias j="just -f ~/dotfiles/user.justfile"
alias .j='just --justfile ~/.user.justfile --working-directory .'

# for recipe in $(just --justfile $DOTFILES/config/just/user.justfile --summary); do
#   alias $recipe="just --justfile '$DOTFILES/config/just/user.justfile' --working-directory . $recipe"
# done

# === Aliases from .zshrc ===
alias claude="/Users/hank/.claude/local/claude"
# List Files - Prioritize eza/exa with fallback to ls
if has_command eza; then # Conditional logic moved with aliases, might need adjustment
  alias ls="eza --icons --group-directories-first"
  alias ll="eza --icons --group-directories-first -la"
  alias la="eza --icons --group-directories-first -a"
  alias lt="eza --icons --group-directories-first --tree"
  alias lt2="eza --icons --group-directories-first --tree --level=2"
# else
#   alias ls="ls -G"
#   alias ll="ls -la"
#   alias la="ls -a"
fi

# Networking Utilities
alias ip="ipconfig getifaddr en0"
alias localip="ipconfig getifaddr en0"
alias publicip="curl -s https://api.ipify.org"
alias ports="sudo lsof -i -P -n | grep LISTEN"
alias flush="dscacheutil -flushcache && killall -HUP mDNSResponder" # Flush DNS
# Dotfiles Management
# alias zdot='cd $ZDOTDIR'
alias zr="exec zsh"
alias ze="fd -t file --hidden . "$ZDOTDIR" | xargs nvim"
alias .e="fd --hidden . $DOTFILES | xargs nvim"
# System Information
alias ppath='echo $PATH | tr ":" "\n"'
alias pfuncs='print -l ${(k)functions[(I)[^_]*]} | sort'
alias pfpath='for fp in $fpath; do echo $fp; done; unset fp'
alias printpath='ppath'
alias printfuncs='pfuncs'
alias printfpath='pfpath'
# Keep commonly used aliases for convenience
alias penv='sys env'
alias ql='sys ql'
alias batman='sys man'
# Aliases
alias v='$EDITOR'
alias vi='$EDITOR'
alias vim='$EDITOR'
# Example: flush DNS
alias flushdns="sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder"
alias showhidden="defaults write com.apple.finder AppleShowAllFiles YES; killall Finder"
# Package management
alias brewup='brew update && brew upgrade && brew cleanup'
# upgrade to modern
alias ps='procs'
alias ping='gping'
alias diff='delta'
# FZF enhanced commands
alias flog='fzf --preview "bat --style=numbers --color=always --line-range=:500 {}"'
alias falias='alias | fzf'
alias fman='man -k . | fzf --preview "man {}"'
alias fls='man -k . | fzf --preview "man {}"'
alias ls='eza -al' # Note: Overwrites previous ls alias
# alias cheat='navi'
# alias tldr='navi'
alias net='trippy'
alias netviz='netop'
alias jwt='jet-ui'
# alias sed='sd'
# alias du='dust'
# alias ssh='sshs'
# alias s3='stu'
# alias http='xh'
# alias http='posting'
alias csv='xsv'
# alias rm='rip'
alias tmux='zellij'
alias jsonfilter='jnv'
alias jsonviewer='jnv'
# k8s kubernetes + docker + containers
alias d='docker' # Note: Overwrites previous d alias
alias dstart='docker start'
alias dstop='docker stop'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias dimg='docker images'
alias dx='docker exec -it'
alias drm='docker rm'
alias drmi='docker rmi'
alias dbuild='docker build'
alias dc='docker-compose'
alias k='k9s'
# Modern CLI alternatives
# alias cat='bat --paging=always'
alias miller='mlr'
# alias grep='rg'
# alias find='fd'
# alias md='glow'
alias ls='eza --icons'     # Note: Overwrites previous ls alias
alias ll='eza -l --icons'  # Note: Overwrites previous ll alias
alias la='eza -al --icons' # Note: Overwrites previous la alias
# Git shortcuts
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias lg='lazygit' # Note: Overwrites previous lg alias
# Ghostty
alias g='ghostty'
# Homebrew aliases + shortcuts
alias b="brew"
#alias bdr="brew doctor"
alias bupd="brew update"
alias bupg="brew upgrade"
alias bclean="brew cleanup --prune=all && brew autoremove"
alias bcleanall='brew cleanup --prune=all && rm -rf $(brew --cache) && brew autoremove'
alias bi="brew info"
alias bin="brew install"
alias brein="brew reinstall"
alias bi="brew info"
alias bs="brew search"
alias bsa="brew search --eval-all --desc"
alias bl="brew leaves"
# Homebrew Cask/Bundle management
alias bcin="brew install --cask"
alias bb="brew bundle -g"
alias bbe="brew bundle edit -g"
alias bba="brew bundle add -g"
alias bbrm="brew bundle remove -g"
alias bbls="brew bundle dump -g --all --file=- --verbose"
alias bbsave="brew bundle dump -g --all --verbose --global"
alias bbcheck="brew bundle check -g --all --verbose --global"
# Directory navigation
alias dl='cd ~/Downloads'
alias cf='cd ~/.config/'
alias zcompreset="rm -f ~/.zcompdump; compinit"
# Tailscale
alias ts="tailscale"
# atuin
alias at="atuin"

# Misc Shortcuts
alias hf="huggingface-cli"
alias lg="lazygit"    # Note: Overwrites previous lg alias
alias ld="lazydocker" # Note: Overwrites previous lg alias

alias rx="repomix" # Note: Overwrites previous lg alias

# alias jfmt="just --unstable --fmt"
alias zj="zellij"
alias zjls="zellij list-sessions"
alias zja='zellij attach "$(zellij list-sessions -n | fzf --reverse --border --no-sort --height 40% | awk '\''{print $1}'\'')"'
alias zje="zellij edit"

# === End Aliases from .zshrc ===

# === Aliases from fzf.zsh ===
# File navigation
# alias ff='f find'         # Find files
# alias fe='f edit'         # Find and edit files
# alias fdir='f dir'          # Find directories
# alias fz='f z'            # Jump with zoxide
# # Git operations
# alias fco='f checkout'    # Git checkout
# alias fga='f add'         # Git add files
# alias fgl='f log'         # Git log
# alias fgs='f status'      # Git status
# alias fgd='f diff'        # Git diff
# # Search
# alias fgr='f grep'        # Grep with fzf
# alias frg='f rgopen'      # Ripgrep and open
# # System
# alias fk='f kill'         # Kill process
# alias fp='f port'         # Kill process on port
# alias fh='f history'      # History search
# alias fm='f man'          # Man pages
# alias fa='f alias'        # Aliases
# # Package management
alias fb='f brew' # Brew operations
# alias fbi='f brew install' # Brew install
# alias fbu='f brew uninstall' # Brew uninstall
# === End Aliases from fzf.zsh ===
