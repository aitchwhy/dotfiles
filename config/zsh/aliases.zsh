#!/usr/bin/env zsh

source "$DOTFILES/utils.zsh"

# ========================================================================
# ZSH aliases - Organized by category
# ========================================================================

# alias optbrew="/opt/homebrew/bin/brew"

# ========================================================================
# Git Utilities
# ========================================================================

# Lazygit alias
has_command alias lg='lazygit'

# ========================================================================
# System utils
# ========================================================================
# Color with built-in ANSI codes, no external dependencies
alias penv='printenv | sort | awk -F= '\''{
  printf "\033[36m%-30s\033[0m \033[37m%s\033[0m\n", $1, $2
}'\'''

# ========================================================================
# Navigation Shortcuts
# ========================================================================
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias home="cd ~"

# ========================================================================
# List Files - Prioritize eza/exa with fallback to ls
# ========================================================================
if command -v eza &>/dev/null; then
  alias ls="eza --icons --group-directories-first"
  alias ll="eza --icons --group-directories-first -la"
  alias la="eza --icons --group-directories-first -a"
  alias lt="eza --icons --group-directories-first --tree"
  alias ltl="eza --icons --group-directories-first --tree --level=2"
elif command -v exa &>/dev/null; then
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

# ========================================================================
# File Operations - Safety Guards
# ========================================================================
# alias cp="cp -i"       # Confirm before overwriting
# alias mv="mv -i"       # Confirm before overwriting
# alias rm="rm -i"       # Confirm before removal
# alias mkdir="mkdir -p" # Create parent directories as needed

# ========================================================================
# Text Editors and Cat Replacement
# ========================================================================
has_command nvim && alias vim="nvim"
has_command nvim && alias vi="nvim"
has_command bat && alias cat="bat"

# ========================================================================
# Homebrew Shortcuts
# ========================================================================
# alias brewup="brew update && brew upgrade && brew cleanup"
# alias bi="brew install"
# alias bs="brew search"
# alias bci="brew cask install"

# ========================================================================
# Networking Utilities
# ========================================================================
alias ip="ipconfig getifaddr en0"
alias localip="ipconfig getifaddr en0"
alias publicip="curl -s https://api.ipify.org"
alias ports="sudo lsof -i -P -n | grep LISTEN"
alias flush="dscacheutil -flushcache && killall -HUP mDNSResponder" # Flush DNS

# ========================================================================
# Dotfiles Management
# ========================================================================

# Keep individual aliases for quick access (see functions.zsh for util func "dot()")
# alias zdir='cd $ZDOTDIR'
# alias dots="cd $DOTFILES"
alias zr="exec zsh"

# alias zdir='cd $ZDOTDIR'
# alias ze="fd --no-ignore --hidden --follow --type f -x $EDITOR $ZDOTDIR"
# alias ze="fd --hidden . $ZDOTDIR | xargs nvim"
# alias dots="cd $DOTFILES"
# alias dotedit="fd --no-ignore --hidden --follow --type f -x $EDITOR $DOTFILES"
# alias zr="exec zsh"
# alias zreload="exec zsh"

# ========================================================================
# System Information
# ========================================================================
alias ppath='echo $PATH | tr ":" "\n"'
alias pfuncs='print -l ${(k)functions[(I)[^_]*]} | sort'
alias pfpath='for fp in $fpath; do echo $fp; done; unset fp'
alias printpath='ppath'
alias printfuncs='pfuncs'
alias printfpath='pfpath'

# ========================================================================
# Misc Shortcuts
# ========================================================================
# alias c="clear"
alias hf="huggingface-cli"
