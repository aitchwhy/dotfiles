#!/usr/bin/env zsh

# Justfile integration for ZSH

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

# Aliases for common justfile commands
alias jl="j"                   # List all commands
