# ~/.dotfiles/config/zsh/aliases.zsh
# ZSH aliases for common commands

# Navigation
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias ~="cd ~"

# List files
if [[ -n "$(command -v eza)" ]]; then
  alias ls="eza --icons --group-directories-first"
  alias ll="eza --icons --group-directories-first -la"
  alias la="eza --icons --group-directories-first -a"
  alias lt="eza --icons --group-directories-first --tree"
  alias ltl="eza --icons --group-directories-first --tree --level=2"
elif [[ -n "$(command -v exa)" ]]; then
  alias ls="exa --icons --group-directories-first"
  alias ll="exa --icons --group-directories-first -la"
  alias la="exa --icons --group-directories-first -a"
  alias lt="exa --icons --group-directories-first --tree"
  alias ltl="exa --icons --group-directories-first --tree --level=2"
else
  alias ls="ls -G"
  alias ll="ls -la"
  alias la="ls -a"
fi

# File operations
alias cp="cp -i"         # Confirm before overwriting
alias mv="mv -i"         # Confirm before overwriting
alias rm="rm -i"         # Confirm before removal
alias mkdir="mkdir -p"   # Create parent directories as needed

# Git shortcuts
alias g="git"
alias ga="git add"
alias gc="git commit"
alias gco="git checkout"
alias gd="git diff"
alias gl="git log"
alias gs="git status"
alias gp="git push"
alias gpl="git pull"
alias gb="git branch"

# Homebrew
alias brewup="brew update && brew upgrade && brew cleanup"
alias bi="brew install"
alias bs="brew search"
alias bci="brew cask install"

# General shortcuts
alias c="clear"
alias h="history"
alias j="jobs"
alias o="open"
alias vim="nvim"
alias vi="nvim"
alias cat="bat"

# Networking
alias ip="ipconfig getifaddr en0"
alias localip="ipconfig getifaddr en0"
alias publicip="curl -s https://api.ipify.org"
alias ports="sudo lsof -i -P -n | grep LISTEN"

# System
alias flush="dscacheutil -flushcache && killall -HUP mDNSResponder"  # Flush DNS
alias cleanup="find . -type f -name '*.DS_Store' -ls -delete"        # Delete .DS_Store files

# dotfiles management
alias dotfiles="cd $DOTFILES"
alias dotupdate="$DOTFILES/update.zsh"
alias dotinstall="$DOTFILES/install.zsh"
alias zshrc="$EDITOR $ZDOTDIR/.zshrc"
alias zshenv="$EDITOR $ZDOTDIR/.zshenv"
alias reload="source $ZDOTDIR/.zshrc"

# Python
alias python="python3"
alias pip="pip3"
alias venv="python -m venv .venv && source .venv/bin/activate"
alias activate="source .venv/bin/activate || source venv/bin/activate"

# Utilities
alias myip="curl -s http://ifconfig.me/ip"
alias weather="curl -s wttr.in"
alias path="echo $PATH | tr ':' '\n'"

