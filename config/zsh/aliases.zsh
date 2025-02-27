#!/usr/bin/env zsh

# ========================================================================
# ZSH aliases - Organized by category
# ========================================================================

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
alias cp="cp -i"       # Confirm before overwriting
alias mv="mv -i"       # Confirm before overwriting
alias rm="rm -i"       # Confirm before removal
alias mkdir="mkdir -p" # Create parent directories as needed

# ========================================================================
# Text Editors and Cat Replacement
# ========================================================================
alias vim="nvim"
alias vi="nvim"
alias cat="bat"

# ========================================================================
# Homebrew Shortcuts
# ========================================================================
alias brewup="brew update && brew upgrade && brew cleanup"
alias bi="brew install"
alias bs="brew search"
alias bci="brew cask install"

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
alias zdots='cd $ZDOTDIR'
alias zedit="fd --no-ignore --hidden --follow --type f -x $EDITOR $ZDOTDIR"
alias dots="cd $DOTFILES"
alias dotedit="fd --no-ignore --hidden --follow --type f -x $EDITOR $DOTFILES"
alias zreload="exec zsh"

# ========================================================================
# System Information
# ========================================================================
alias printpath='echo $PATH | tr ":" "\n"'
alias printfuncs='print -l ${(k)functions[(I)[^_]*]} | sort'
alias printfpath='for fp in $fpath; do echo $fp; done; unset fp'

# ========================================================================
# Misc Shortcuts
# ========================================================================
alias c="clear"
alias hf="huggingface-cli"
