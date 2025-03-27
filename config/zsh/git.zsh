#!/usr/bin/env zsh
# ========================================================================
# Git Configuration & Utilities
# ========================================================================

# Source common utilities if not already loaded
[[ -f "$ZDOTDIR/utils.zsh" ]] && source "$ZDOTDIR/utils.zsh"

# ========================================================================
# Git Aliases & Wrappers
# ========================================================================

# Conditional git aliases - only if git is installed
if has_command git; then
  alias gs='git status'
  alias ga='git add'
  alias gaa='git add --all'
  alias gc='git commit'
  alias gcm='git commit -m'
  alias gca='git commit --amend --no-edit'
  # alias gco='git checkout'
  alias gcp='git cherry-pick'
  alias gp='git push'
  alias gll='git pull'
  alias gd='git diff'
  alias gb='git branch'
  alias gst='git stash'
  alias gstp='git stash pop'

fi

# Lazygit terminal UI
has_command lazygit && alias lg='lazygit'

# # Git branch management
# function gclean() {
#   # Clean merged branches (excluding main branches)
#   local branches_to_delete

#   if ! has_command git; then
#     log_error "Git is not installed."
#     return 1
#   fi

#   branches_to_delete=$(git branch --merged | grep -v "^\*" | grep -v "master\|main\|develop")

#   if [[ -z "$branches_to_delete" ]]; then
#     log_info "No merged branches to delete."
#     return 0
#   fi

#   echo "The following branches will be deleted:"
#   echo "$branches_to_delete"
#   read -q "REPLY?Are you sure you want to delete these branches? [y/N] "
#   echo

#   if [[ $REPLY =~ ^[Yy]$ ]]; then
#     git branch --merged | grep -v "^\*" | grep -v "master\|main\|develop" | xargs git branch -d
#     log_success "Branches deleted successfully!"
#   else
#     log_info "Operation canceled."
#   fi
# }
