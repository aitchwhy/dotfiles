#!/usr/bin/env bash

# Justfile integration for Bash
# This provides similar functionality to the ZSH version

# Ensure the USER_JUSTFILE is defined
export USER_JUSTFILE="${USER_JUSTFILE:-$HOME/dotfiles/config/just/justfile}"

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

# Fuzzy find and execute just commands (requires fzf)
function jf() {
  local justfile=$(_just_find_file)
  
  if [[ -z "$justfile" ]]; then
    echo "No justfile found in parent directories or user directory"
    return 1
  fi
  
  if ! command -v fzf >/dev/null; then
    echo "fzf is required for this command"
    return 1
  fi
  
  local cmd=$(just --justfile "$justfile" --list | tail -n +3 | fzf --height=40% --reverse --border | awk '{print $1}')
  
  if [[ -n "$cmd" ]]; then
    echo "Running: just $cmd"
    just --justfile "$justfile" $cmd
  fi
}

# Aliases for common justfile commands
alias jl="j"                   # List all commands
alias jc="just choose"         # Fuzzy choose command