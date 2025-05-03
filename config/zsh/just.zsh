#!/usr/bin/env zsh

# Justfile integration for ZSH

# Ensure the USER_JUSTFILE is defined
export USER_JUSTFILE="${USER_JUSTFILE:-$HOME/.config/just/justfile}"

# Use the project justfile if available, otherwise fallback to user justfile
function _just_find_file() {
  local dir=$PWD
  while [[ "$dir" != "/" ]]; do
    if [[ -f "$dir/justfile" ]]; then
      echo "$dir/justfile"
      return 0
    fi
    dir=$(dirname "$dir")
  done
  
  # Fallback to user justfile
  if [[ -f "$USER_JUSTFILE" ]]; then
    echo "$USER_JUSTFILE"
    return 0
  fi
  
  # Fallback to dotfiles justfile
  if [[ -f "$HOME/dotfiles/justfile" ]]; then
    echo "$HOME/dotfiles/justfile"
    return 0
  fi
  
  return 1
}

# Just command with auto-detection of justfile
function j() {
  local justfile=$(_just_find_file)
  
  if [[ -z "$justfile" ]]; then
    echo "No justfile found in parent directories or user directory"
    return 1
  fi
  
  if [[ $# -eq 0 ]]; then
    just --justfile "$justfile" --list
  else
    just --justfile "$justfile" "$@"
  fi
}

# Fuzzy find and execute just commands
function jf() {
  local justfile=$(_just_find_file)
  
  if [[ -z "$justfile" ]]; then
    echo "No justfile found in parent directories or user directory"
    return 1
  fi
  
  local cmd=$(just --justfile "$justfile" --list | tail -n +3 | fzf --height=40% --reverse --border | awk '{print $1}')
  
  if [[ -n "$cmd" ]]; then
    echo "Running: just $cmd"
    just --justfile "$justfile" $cmd
  fi
}

# Fuzzy find and execute just commands for a specific app/tool
function ja() {
  local justfile=$(_just_find_file)
  local app=$1
  
  if [[ -z "$justfile" ]]; then
    echo "No justfile found in parent directories or user directory"
    return 1
  fi
  
  if [[ -z "$app" ]]; then
    echo "Please specify an app/tool prefix"
    return 1
  fi
  
  local cmd=$(just --justfile "$justfile" --list | grep "^$app" | tail -n +1 | fzf --height=40% --reverse --border | awk '{print $1}')
  
  if [[ -n "$cmd" ]]; then
    echo "Running: just $cmd"
    just --justfile "$justfile" $cmd
  fi
}

# Basic completion for just
_just_completion() {
  local justfile=$(_just_find_file)
  
  if [[ -z "$justfile" ]]; then
    return 1
  fi
  
  local commands=($(just --justfile "$justfile" --list | tail -n +3 | awk '{print $1}'))
  _describe 'command' commands
}

# Register the completion
compdef _just_completion j

# Aliases for common justfile commands
alias jl="j"                   # List all commands
alias jc="just choose"         # Fuzzy choose command
alias jn="ja nvim"             # Fuzzy choose Neovim commands
alias jz="ja zsh"              # Fuzzy choose ZSH commands
alias jy="ja yazi"             # Fuzzy choose Yazi commands
alias ja="ja aero"             # Fuzzy choose Aerospace commands
alias js="ja star"             # Fuzzy choose Starship commands