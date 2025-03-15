
# Mac App Store operations command
function fmas() {
  # In the context of shell scripting, particularly in Unix-like operating systems, [[ $# -gt 0 ]] is a test condition used to check if one or more arguments have been passed to a script or function.
  # Here's a breakdown of the components:
  # > [[ ... ]]: a conditional expression for testing conditions. It is more flexible and safer than the older [ ... ] test command.
  # > $#: a special variable for number of positional parameters (arguments) passed to the script or function.
  # > -gt: This is a binary comparison operator that stands for "greater than."
  # Therefore, [[ $# -gt 0 ]] checks if the number of arguments ($#) is greater than 0, meaning it verifies whether any arguments were provided to the script or function. If true, it indicates that at least one argument has been passed.
  if [[ $# -gt 0 ]]; then
    # Direct execution if args provided
    case "$1" in
      install|in)      shift; mas_install "$@" ;;
      uninstall|rm)         shift; mas_uninstall "$@" ;;
      info|i)          shift; mas_info "$@" ;;
      cleanup|clean)          shift; mas_clean "$@" ;;
      edit|e)          shift; mas_edit "$@" ;;

      # Help and default case
      help|--help|-h)  _show_mas_help ;;
      *)
        log_error "Unknown Mac App Store command: $1"
        _show_mas_help
        return 1
        ;;
    esac
    return $?
  fi

  # Interactive selection with fzf if no args
  if has_command fzf; then
    _select_mas_command
  else
    _show_mas_help
  fi
}

# Interactive command selection for Mac App Store operations
_select_mas_command() {
  _fzf_check || { _show_mas_help; return 1; }

  local commands=(
    "install:Install app from Mac App Store:mas_install"
    "uninstall:Uninstall app from Mac App Store:mas_uninstall"
    "info:Show app information:mas_info"
    "cleanup:Clean up and remove unused apps:mas_clean"
    "edit:Edit Mac App Store apps list:mas_edit"
  )

  local selected
  selected=$(printf "%s\n" "${commands[@]}" |
    awk -F: '{printf "%-15s %s\n", $1, $2}' |
    fzf --header="Select a Mac App Store command" \
        --preview="echo; echo Description: {2..}; echo" \
        --preview-window=bottom:3:wrap)

  if [[ -n "$selected" ]]; then
    local cmd=$(echo "$selected" | awk '{print $1}')
    local idx=0
    local function_name=""

    # Find the matching command
    for c in "${commands[@]}"; do
      local cmd_name=$(echo "$c" | cut -d: -f1)
      if [[ "$cmd_name" == "$cmd" ]]; then
        function_name=$(echo "$c" | cut -d: -f3)
        break
      fi
    done

    if [[ -n "$function_name" ]]; then
      log_info "Executing: $function_name"
      $function_name
    fi
  fi
}

# Display Mac App Store commands help
_show_mas_help() {
  echo "MAS (Mac App Store) apps management util"
  echo ""
  echo "Usage: fmas <command> [arguments]"
  echo ""
  echo "Basic Commands:"
  echo "  install, in      Install an app from Mac App Store"
  echo "  uninstall, rm    Uninstall an app from Mac App Store"
  echo "  info, i          Show app information"
  echo "  cleanup, clean   Clean up and remove unused apps"
  echo "  edit, e          Edit Mac App Store apps list"
  echo ""
  echo "Running without arguments will enter interactive selection mode (requires fzf)"
}

# Check if fzf is available
_fzf_check() {
  if ! has_command fzf; then
    log_error "fzf is not installed. Install with 'brew install fzf'"
    return 1
  fi
  return 0
}

# Interactive app selection using fzf
_select_mas_app() {
  local query="$1"
  local selection=$(mas list | fzf --query="$query" --header="Select Mac App Store app")
  if [[ -n "$selection" ]]; then
    echo "$selection" | awk '{print $1}'
  else
    return 1
  fi
}

# Install app from Mac App Store
mas_install() {
  if [[ $# -eq 0 ]]; then
    local id=$(_select_mas_app)
    [[ -z "$id" ]] && return 1
    log_info "Installing Mac App Store app: $id"
    mas install "$id"
  else
    log_info "Installing Mac App Store app: $1"
    mas install "$@"
  fi
}

# Uninstall app from Mac App Store
mas_uninstall() {
  if [[ $# -eq 0 ]]; then
    local id=$(_select_mas_app)
    [[ -z "$id" ]] && return 1
    local app_name=$(mas list | grep "^$id" | awk '{$1=""; print $0}' | xargs)
    log_info "Uninstalling Mac App Store app: $app_name"
    # Note: mas doesn't have a direct uninstall command, so we use finder
    osascript -e "tell application \"Finder\" to move application \"$app_name\" to trash"
  else
    log_error "Please provide the app name to uninstall"
    return 1
  fi
}

# Show app information
mas_info() {
  if [[ $# -eq 0 ]]; then
    local id=$(_select_mas_app)
    [[ -z "$id" ]] && return 1
    log_info "Showing info for Mac App Store app: $id"
    mas info "$id"
  else
    log_info "Showing info for Mac App Store app: $1"
    mas info "$@"
  fi
}

# Clean up Mac App Store apps (placeholder - mas doesn't have cleanup)
mas_clean() {
  log_info "The Mac App Store CLI doesn't have a direct cleanup option"
  log_info "Use 'mas outdated' to see apps that need updating"
  mas outdated
  echo ""
  log_info "Use 'mas upgrade' to update all apps"
}

# Edit Mac App Store apps list (opens a list of installed apps)
mas_edit() {
  local temp_file=$(mktemp)
  mas list > "$temp_file"
  ${EDITOR:-vi} "$temp_file"
  log_info "Mac App Store apps list saved to $temp_file"
}

# Simple function to list apps with fzf and return the app ID
function fmas_select() {
  mas list | fzf | awk '{print $1}'
}
