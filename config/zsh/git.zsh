
# Clean merged branches
function gclean() {
  local branches_to_delete

  branches_to_delete=$(git branch --merged | grep -v "^\*" | grep -v "master\|main\|develop")

  if [[ -z "$branches_to_delete" ]]; then
    log_info "No merged branches to delete."
    return 0
  fi

  echo "The following branches will be deleted:"
  echo "$branches_to_delete"
  read -q "REPLY?Are you sure you want to delete these branches? [y/N] "
  echo

  if [[ $REPLY =~ ^[Yy]$ ]]; then
    git branch --merged | grep -v "^\*" | grep -v "master\|main\|develop" | xargs git branch -d
    log_success "Branches deleted successfully!"
  else
    log_info "Operation canceled."
  fi
}
