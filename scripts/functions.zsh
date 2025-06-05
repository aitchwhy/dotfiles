#!/usr/bin/env zsh

################################
# IDE (VSCode + Cursor)
################################
function cursor_ext_import() {
  while read extension; do
    # code --install-extension "$extension"
    cursor --install-extension "$extension"
  done < $DOTFILES/config/vscode/extensions.txt
}

function volta() {
  switch
  volta list --format=plain

}

# examples
# From home directory
# cpgit /path/to/source /path/to/dest
#
# # With relative paths
# cpgit ../project1 ./project2
#
# # From any directory
# cpgit ~/repos/myproject /tmp/backup  
cp-repo() {
  git -C "$1" ls-files -z | (cd "$1" && rsync -0av --files-from=- . "$(realpath "$2")/")
    rsync -av --include=".*" --exclude="*" "$1/" "$2/" 2>/dev/null
}


# copy_git_project() {
#
#     mkdir -p "$dest"
#
#     # Copy git tracked files
#     (cd "$src" && git ls-files -z | tar --null -cf - -T -) | tar -xf - -C "$dest"
#
#     # Copy config files
#     for f in .env .env.* .envrc .tool-versions .nvmrc .ruby-version .gitignore; do
#         [ -f "$src/$f" ] && cp "$src/$f" "$dest/"
#     done
#
# }

# # uses rsync
# function cp_rsync() {
#     if [ $# -lt 2 ]; then
#         echo "Usage: copy_git_project_rsync <source_dir> <destination_dir>" >&2
#         return 1
#     fi
#
#     # Check if rsync is available
#     if ! command -v rsync >/dev/null 2>&1; then
#         echo "Error: rsync not found. Using tar method instead..." >&2
#         copy_git_project "$@"
#         return $?
#     fi
#
#     src="$1"
#     dest="$2"
#
#     [ -d "$src/.git" ] || {
#         echo "Error: Source is not a git repository" >&2
#         return 1
#     }
#
#     mkdir -p "$dest" || return 1
#
#     src=$(cd "$src" && pwd) || return 1
#     dest=$(cd "$dest" && pwd) || return 1
#
#     echo "Copying with rsync..."
#
#     # Copy git tracked files
#     (
#         cd "$src" && \
#         git ls-files -z | rsync -av --files-from=- --from0 . "$dest/"
#     ) || return 1
#
#     # Copy additional files
#     rsync -av --include=".env*" --include=".tool-versions" \
#               --include=".nvmrc" --include=".ruby-version" \
#               --include=".gitignore" --include=".gitattributes" \
#               --exclude="*" "$src/" "$dest/" 2>/dev/null
#
#     echo "✓ Successfully copied with rsync"
# }
#
# ################################
# Homebrew
################################
# Mac App Store operations command
# function fmas() {
#   # In the context of shell scripting, particularly in Unix-like operating systems, [[ $# -gt 0 ]] is a test condition used to check if one or more arguments have been passed to a script or function.
#   # Here's a breakdown of the components:
#   # > [[ ... ]]: a conditional expression for testing conditions. It is more flexible and safer than the older [ ... ] test command.
#   # > $#: a special variable for number of positional parameters (arguments) passed to the script or function.
#   # > -gt: This is a binary comparison operator that stands for "greater than."
#   # Therefore, [[ $# -gt 0 ]] checks if the number of arguments ($#) is greater than 0, meaning it verifies whether any arguments were provided to the script or function. If true, it indicates that at least one argument has been passed.
#   if [[ $# -gt 0 ]]; then
#     # Direct execution if args provided
#     case "$1" in
#     install | in)
#       shift
#       mas_install "$@"
#       ;;
#     uninstall | rm)
#       shift
#       mas_uninstall "$@"
#       ;;
#     info | i)
#       shift
#       mas_info "$@"
#       ;;
#     cleanup | clean)
#       shift
#       mas_clean "$@"
#       ;;
#     edit | e)
#       shift
#       mas_edit "$@"
#       ;;
#
#     # Help and default case
#     help | --help | -h) _show_mas_help ;;
#     *)
#       log_error "Unknown Mac App Store command: $1"
#       _show_mas_help
#       return 1
#       ;;
#     esac
#     return $?
#   fi
#
#   # Interactive selection with fzf if no args
#   if has_command fzf; then
#     _select_mas_command
#   else
#     _show_mas_help
#   fi
# }
#
# # Interactive command selection for Mac App Store operations
# function _select_mas_command() {
#   _fzf_check || {
#     _show_mas_help
#     return 1
#   }
#
#   local commands=(
#     "install:Install app from Mac App Store:mas_install"
#     "uninstall:Uninstall app from Mac App Store:mas_uninstall"
#     "info:Show app information:mas_info"
#     "cleanup:Clean up and remove unused apps:mas_clean"
#     "edit:Edit Mac App Store apps list:mas_edit"
#   )
#
#   local selected=$(printf "%s\n" "${commands[@]}" | awk -F: '{printf "%-15s %s\n", $1, $2}' |
#     fzf --header="Select a Mac App Store command" \
#       --preview="echo; echo Description: {2..}; echo" \
#       --preview-window=bottom:3:wrap)
#
#   if [[ -n "$selected" ]]; then
#     local cmd=$(echo "$selected" | awk '{print $1}')
#     local idx=0
#     local function_name=""
#
#     # Find the matching command
#     for c in "${commands[@]}"; do
#       local cmd_name=$(echo "$c" | cut -d: -f1)
#       if [[ "$cmd_name" == "$cmd" ]]; then
#         function_name=$(echo "$c" | cut -d: -f3)
#         break
#       fi
#     done
#
#     if [[ -n "$function_name" ]]; then
#       log_info "Executing: $function_name"
#       $function_name
#     fi
#   fi
# }

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
  mas list >"$temp_file"
  ${EDITOR:-vi} "$temp_file"
  log_info "Mac App Store apps list saved to $temp_file"
}

# Simple function to list apps with fzf and return the app ID
function fmas_select() {
  mas list | fzf | awk '{print $1}'
}

# === Functions from .zshrc ===
# symlink
function slink() {
    local src_orig=$1
    local dst_link=$2
    local dst_dir=$(dirname "$dst_link")

    # Create the directory if it does not exist
    mkdir -p "$dst_dir"

    # Create the symlink
    ln -nfs "$src_orig" "$dst_link"
}

function slink_init() {
    slink $DOTFILES/.Brewfile $HOME/.Brewfile
    slink $DOTFILES/.zshrc $HOME/.zshrc

    slink $DOTFILES_EXPORTS $OMZ_CUSTOM/exports.zsh
    slink $DOTFILES_ALIASES $OMZ_CUSTOM/aliases.zsh
    slink $DOTFILES_FUNCTIONS $OMZ_CUSTOM/functions.zsh

    slink $DOTFILES/nvm/default-packages $NVM_DIR/default-packages
    slink $DOTFILES/.config/git/.gitignore $HOME/.gitignore


    slink $DOTFILES/.config/zellij/main-layout.kdl $HOME/.config/config.kdl
}
# === End Functions from .zshrc ===

# === Functions from fzf.zsh ===
_f_has_command() {
  command -v "$1" &>/dev/null
}
_f_search() {
  local preview_cmd="$1"    # Preview command
  local header="$2"         # Header text
  local action_cmd="$3"     # Command to run on selection
  local initial_query="${4:-}" # Initial search query
  local fzf_opts="${5:-}"   # Additional fzf options

  if [[ -z "$action_cmd" ]]; then
    # Simply display selection
    fzf --preview "$preview_cmd" \
        --header "$header" \
        --query "$initial_query" \
        $fzf_opts
  else
    # Run action on selection
    fzf --preview "$preview_cmd" \
        --header "$header" \
        --query "$initial_query" \
        $fzf_opts | eval "$action_cmd"
  fi
}
_f_help() {
  echo "FZF Command Framework - Interactive tools powered by fzf"
  echo ""
  echo "Usage: f [command] [args]"
  echo "       f (with no arguments to show interactive menu)"
  echo ""

  # Extract categories and commands from registry
  local categories=()
  local current_category=""
  
  for cmd_info in "${_F_COMMANDS[@]}"; do
    local parts=("${(s/:/)cmd_info}")
    local cmd_category="${parts[1]}"
    
    if [[ ! " ${categories[@]} " =~ " ${cmd_category} " ]]; then
      categories+=("$cmd_category")
    fi
  done
  
  # Display commands by category
  for category in "${categories[@]}"; do
    echo "${category} Commands:"
    
    for cmd_info in "${_F_COMMANDS[@]}"; do
      local parts=("${(s/:/)cmd_info}")
      local cmd_category="${parts[1]}"
      local cmd_name="${parts[2]}"
      local cmd_aliases="${parts[3]}"
      local cmd_desc="${parts[4]}"
      
      if [[ "$cmd_category" == "$category" ]]; then
        if [[ -n "$cmd_aliases" ]]; then
          printf "  %-15s %-10s - %s\n" "$cmd_name" "($cmd_aliases)" "$cmd_desc"
        else
          printf "  %-15s %11s %s\n" "$cmd_name" "" "$cmd_desc"
        fi
      fi
    done
    echo ""
  done
}
_f_check_deps() {
  local deps=($@)
  local missing=()
  
  for dep in $deps; do
    if ! _f_has_command "$dep"; then
      missing+=("$dep")
    fi
  done
  
  if [[ ${#missing[@]} -gt 0 ]]; then
    echo "Missing required dependencies: ${missing[@]}"
    echo "Please install them to use this command."
    return 1
  fi
  
  return 0
}
_f_cmd_find() {
  local target="${1:-.}"
  
  _f_check_deps "fd" "bat" || return 1
  
  fd --type f --hidden --follow --exclude .git . "$target" 2>/dev/null |
    _f_search \
      "$FZF_PREVIEW_COMMAND" \
      "Find files in $target" \
      "${EDITOR:-nvim} {}" \
      "" \
      "--multi"
}
_f_cmd_dir() {
  local target="${1:-.}"
  
  _f_check_deps "fd" "tree" || return 1
  
  fd --type d --hidden --follow --exclude .git . "$target" 2>/dev/null |
    _f_search \
      "tree -C {} | head -200" \
      "Find directories in $target" \
      "cd {}" \
      "" \
      ""
}
_f_cmd_edit() {
  local target="${1:-.}"
  
  _f_check_deps "fd" "bat" || return 1
  
  fd --type f --hidden --follow --exclude .git . "$target" 2>/dev/null |
    _f_search \
      "$FZF_PREVIEW_COMMAND" \
      "Open in editor" \
      "${EDITOR:-nvim} {}" \
      "" \
      ""
}
_f_cmd_grep() {
  _f_check_deps "rg" "bat" || return 1
  
  local query="${*:1}"
  local reload_cmd='reload:rg --column --color=always --smart-case {q} || :'
  local opener_cmd='if [[ $FZF_SELECT_COUNT -eq 0 ]]; then
                    ${EDITOR:-nvim} {1} +{2}
                  else
                    ${EDITOR:-nvim} +cw -q {+f}
                  fi'

  fzf --disabled --ansi --multi \
      --bind "start:$reload_cmd" --bind "change:$reload_cmd" \
      --bind "enter:become:$opener_cmd" \
      --bind "ctrl-o:execute:$opener_cmd" \
      --bind 'alt-a:select-all,alt-d:deselect-all,ctrl-/:toggle-preview' \
      --delimiter : \
      --preview 'bat --style=full --color=always --highlight-line {2} {1}' \
      --preview-window '~4,+{2}+4/3,<80(up)' \
      --query "$query"
}
_f_cmd_rgopen() {
  _f_check_deps "rg" "bat" || return 1
  
  local query="${*:1}"
  
  if [[ -z "$query" ]]; then
    echo "Usage: f rgopen <search term>"
    return 1
  fi
  
  rg --line-number --no-heading --color=always --smart-case "$query" |
    fzf --ansi \
        --color "hl:-1:underline,hl+:-1:underline:reverse" \
        --delimiter : \
        --preview "bat --style=numbers --color=always --highlight-line {2} {1}" \
        --preview-window "right,60%,border-left,+{2}+3/3,~3" \
        --bind 'ctrl-/:toggle-preview' \
        --header "Search in files for: $query" |
    awk -F: '{print $1 " +" $2}' |
    xargs -o ${EDITOR:-nvim}
}
_f_cmd_ripgrep() {
  _f_check_deps "rg" "bat" || return 1
  
  local query="${*:1}"
  local reload_cmd='reload:rg --column --color=always --smart-case {q} || :'
  local opener_cmd='if [[ $FZF_SELECT_COUNT -eq 0 ]]; then
                  ${EDITOR:-nvim} {1} +{2}  
                else
                  ${EDITOR:-nvim} +cw -q {+f}
                fi'

  fzf --disabled --ansi --multi \
      --bind "start:$reload_cmd" --bind "change:$reload_cmd" \
      --bind "enter:become:$opener_cmd" \
      --bind "ctrl-o:execute:$opener_cmd" \
      --bind 'alt-a:select-all,alt-d:deselect-all,ctrl-/:toggle-preview' \
      --delimiter : \
      --preview 'bat --style=full --color=always --highlight-line {2} {1}' \
      --preview-window '~4,+{2}+4/3,<80(up)' \
      --query "$query"
}
_f_cmd_checkout() {
  _f_check_deps "git" || return 1
  
  if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "Not in a git repository"
    return 1
  fi
  
  local branches branch
  branches=$(git branch --all | grep -v HEAD) &&
    branch=$(echo "$branches" |
      fzf --no-multi --header "Git checkout branch") &&
    git checkout $(echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")
}
_f_cmd_add() {
  _f_check_deps "git" || return 1
  
  if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "Not in a git repository"
    return 1
  fi
  
  git -c color.status=always status --short |
    _f_search \
      "git diff --color=always {2}" \
      "Git add files" \
      "cut -c4- | sed 's/.* -> //' | xargs -r git add" \
      "" \
      "--ansi --multi"
  git status --short
}
_f_cmd_stash() {
  _f_check_deps "git" || return 1
  
  if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "Not in a git repository"
    return 1
  fi
  
  local stashes action
  
  # Get action from menu if not provided
  if [[ -z "$1" ]]; then
    action=$(printf "apply\nshow\npop\ndrop\ncreate" | fzf --header "Choose stash action")
  else
    action="$1"
  fi
  
  [[ -z "$action" ]] && return 0
  
  case "$action" in
    create)
      local msg="$(read -r -p 'Stash message (optional): ' message; echo "$message")"
      if [[ -n "$msg" ]]; then
        git stash push -m "$msg"
      else
        git stash push
      fi
      ;;
    show|apply|pop|drop)
      stashes=$(git stash list) &&
        stash=$(echo "$stashes" |
          fzf --no-multi --header "Choose stash for $action") &&
          stash_id=$(echo "$stash" | grep -o "stash@{[0-9]*}")
          
      [[ -z "$stash_id" ]] && return 0
      
      case "$action" in
        show)  git stash show -p "$stash_id" | bat --style=numbers,changes --color=always ;;
        apply) git stash apply "$stash_id" ;;
        pop)   git stash pop "$stash_id" ;;
        drop)  git stash drop "$stash_id" ;;
      esac
      ;;
    *)
      echo "Invalid action: $action"
      echo "Valid actions: apply, show, pop, drop, create"
      return 1
      ;;
  esac
}
_f_cmd_log() {
  _f_check_deps "git" || return 1
  
  if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "Not in a git repository"
    return 1
  fi
  
  local author="${1:-}"
  local filter=""

  [[ -n "$author" ]] && filter="--author=$author"
  
  git log --graph --color=always --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" $filter |
    fzf --ansi --no-sort --reverse --tiebreak=index \
        --preview 'f() { set -- $(echo -- "$@" | grep -o "[a-f0-9]\{7\}"); [ $# -eq 0 ] || git show --color=always $1; }; f {}' \
        --preview-window=right:60% \
        --bind='ctrl-/:toggle-preview' \
        --header='Browse git log' \
        --bind='enter:execute:
        (grep -o "[a-f0-9]\{7\}" | head -1 |
        xargs -I % sh -c "git show --color=always % | less -R") <<< {}'
}
_f_cmd_status() {
  _f_check_deps "git" || return 1
  
  if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "Not in a git repository"
    return 1
  fi
  
  local selected file
  
  selected=$(git -c color.status=always status --short |
    fzf --ansi --multi \
        --preview 'set -- $(echo {} | awk "{print \$2}"); git diff --color=always $1' \
        --header="Select files for action" \
        --bind 'ctrl-a:select-all' \
        --bind 'ctrl-d:deselect-all' \
        --expect=ctrl-c,ctrl-r,ctrl-a,ctrl-u
  )
  
  [[ -z "$selected" ]] && return 0
  
  local key=$(head -1 <<< "$selected")
  local files=$(sed 1d <<< "$selected" | cut -c4- | sed 's/.* -> //')
  
  [[ -z "$files" ]] && return 0
  
  case "$key" in
    ctrl-a) git add $files; git status --short ;;
    ctrl-r) git restore --staged $files; git status --short ;;
    ctrl-u) git restore $files; git status --short ;;
    *)      
      # Default action: git add
      git add $files; git status --short ;;
  esac
}
_f_cmd_diff() {
  _f_check_deps "git" || return 1
  
  if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "Not in a git repository"
    return 1
  fi
  
  local file
  
  file=$(git diff --name-only |
    fzf --ansi \
        --preview 'git diff --color=always {}' \
        --header="View file diffs" \
        --bind 'ctrl-/:toggle-preview'
  )
  
  [[ -z "$file" ]] && return 0
  
  git diff --color=always "$file" | bat --style=numbers,changes --color=always
}
_f_cmd_kill() {
  ps -ef | sed 1d |
    _f_search \
      "echo {}" \
      "Kill process (SIGTERM by default)" \
      "awk '{print \$2}' | xargs -r kill -${1:-15}" \
      "" \
      "--multi"
}
_f_cmd_port() {
  _f_check_deps "lsof" || return 1
  
  lsof -i -P -n | grep LISTEN |
    _f_search \
      "echo {}" \
      "Kill process on port" \
      "awk '{print \$2}' | xargs -r kill -9" \
      "" \
      "--preview-window=down:3:wrap"
}
_f_cmd_man() {
  _f_check_deps "man" || return 1
  
  man -k . |
    _f_search \
      "echo {} | cut -d\" \" -f1 | xargs -I% man %" \
      "Browse man pages" \
      "awk '{print \$1}' | xargs -r man" \
      "${1:-}" \
      "--preview-window=right:70%"
}
_f_cmd_alias() {
  alias |
    _f_search \
      "echo {}" \
      "Browse aliases" \
      "awk '{print \$0}'" \
      "${1:-}" \
      "--multi"
}
_f_cmd_history() {
  history |
    _f_search \
      "echo {}" \
      "Search command history" \
      "awk '{print substr(\$0, index(\$0, \$2))}' | ${SHELL:-zsh}" \
      "${1:-}" \
      "--sort --exact --preview-window=down:3:wrap"
}
_f_cmd_brew() {
  _f_check_deps "brew" || return 1
  
  local subcommand="${1:-}"
  
  # If no subcommand provided, show menu
  if [[ -z "$subcommand" ]]; then
    subcommand=$(printf "install\nuninstall\ninfo\nsearch\nupdate\ncleanup\ncask-install" |
      fzf --header "Select brew operation")
  fi
  
  [[ -z "$subcommand" ]] && return 0
  
  case "$subcommand" in
    install|i)
      shift
      brew search |
        _f_search \
          "brew info {}" \
          "Install brew packages" \
          "xargs -r brew install" \
          "${1:-}" \
          "--multi"
      ;;
    cask-install|ci)
      shift
      brew search --casks |
        _f_search \
          "brew info --cask {}" \
          "Install brew casks" \
          "xargs -r brew install --cask" \
          "${1:-}" \
          "--multi"
      ;;
    uninstall|rm)
      shift
      brew leaves |
        _f_search \
          "brew info {}" \
          "Remove brew packages" \
          "xargs -r brew uninstall" \
          "${1:-}" \
          "--multi"
      ;;
    info|i)
      shift
      brew list |
        _f_search \
          "brew info {}" \
          "Show package information" \
          "brew info" \
          "${1:-}" \
          ""
      ;;
    search|s)
      shift
      brew search "${1:-}" |
        _f_search \
          "brew info {}" \
          "Search brew packages" \
          "" \
          "" \
          "--multi"
      ;;
    update|up)
      brew update && brew upgrade
      ;;
    cleanup|clean)
      brew cleanup
      ;;
    *)
      echo "Unknown brew subcommand: $subcommand"
      echo "Available: install (i), cask-install (ci), uninstall (rm), info (i), search (s), update (up), cleanup (clean)"
      return 1
      ;;
  esac
}
_f_cmd_npm() {
  _f_check_deps "npm" "jq" || return 1
  
  if [[ ! -f package.json ]]; then
    echo "No package.json found in current directory"
    return 1
  fi

  cat package.json | jq -r '.scripts | to_entries | .[] | .key' |
    _f_search \
      "cat package.json | jq -r .scripts.{}" \
      "Run npm script" \
      'xargs -I{} sh -c "echo \"Running npm run {}...\" && npm run {}"'
}
_f_cmd_docker() {
  _f_check_deps "docker" || return 1
  
  docker ps --format "{{.Names}}" |
    _f_search \
      "docker stats --no-stream {}" \
      "Select container" \
      "xargs -r docker exec -it bash"
}
_f_cmd_z() {
  _f_check_deps "zoxide" || return 1
  
  local dir
  dir=$(zoxide query -l | 
    _f_search \
      "ls -la {}" \
      "Jump to directory" \
      "echo" \
      "${1:-}" \
      "") && 
    cd "$dir"
}
f() {
  # No arguments - show interactive command selector
  if [[ $# -eq 0 ]]; then
    local categories=()
    local all_commands=()
    
    # Extract unique categories
    for cmd_info in "${_F_COMMANDS[@]}"; do
      local parts=("${(s/:/)cmd_info}")
      local category="${parts[1]}"
      
      if [[ ! " ${categories[@]} " =~ " ${category} " ]]; then
        categories+=("$category")
      fi
    done
    
    # Build command list with categories
    for category in "${categories[@]}"; do
      all_commands+=("$category:")
      
      for cmd_info in "${_F_COMMANDS[@]}"; do
        local parts=("${(s/:/)cmd_info}")
        local cmd_category="${parts[1]}"
        local cmd_name="${parts[2]}"
        local cmd_desc="${parts[4]}"
        
        if [[ "$cmd_category" == "$category" ]]; then
          all_commands+=("  $cmd_name:$cmd_desc")
        fi
      done
    done
    
    # Display interactive menu with fzf
    local choice
    choice=$(printf "%s\n" "${all_commands[@]}" |
      fzf --height 60% --border sharp --cycle --ansi \
          --preview 'echo Description: {2..}' \
          --preview-window=down:3:wrap \
          --bind='ctrl-/:toggle-preview' \
          --header="Select a command (Categories are labeled)" \
          --no-multi)
          
    # If category header was selected, get first command in that category
    if [[ "$choice" =~ ^[A-Za-z]+:$ ]]; then
      local category="${choice%:}"
      for cmd_info in "${_F_COMMANDS[@]}"; do
        local parts=("${(s/:/)cmd_info}")
        if [[ "${parts[1]}" == "$category" ]]; then
          choice="  ${parts[2]}:${parts[4]}"
          break
        fi
      done
    fi
    
    # Exit if no selection
    [[ -z "$choice" ]] && return 0
    
    # Extract command name (trim leading whitespace if command was under category)
    local cmd_name=$(echo "$choice" | cut -d: -f1 | sed 's/^ *//')
    
    # Run the command
    f "$cmd_name"
    return $?
  fi
  
  # Help command
  if [[ "$1" == "help" ]]; then
    _f_help
    return 0
  fi
  
  # Look up command in registry
  local cmd_func=""
  local cmd_name=""
  
  for cmd_info in "${_F_COMMANDS[@]}"; do
    local parts=("${(s/:/)cmd_info}")
    local main_cmd="${parts[2]}"
    local aliases="${parts[3]}"
    
    # Split aliases into array
    local alias_array=("${(s/,/)aliases}")
    
    # Check command and aliases
    if [[ "$1" == "$main_cmd" ]] || [[ " ${alias_array[@]} " =~ " $1 " ]]; then
      cmd_name="$main_cmd"
      cmd_func="_f_cmd_$main_cmd"
      break
    fi
  done
  
  # If command found, execute it
  if [[ -n "$cmd_func" ]]; then
    shift
    $cmd_func "$@"
    return $?
  fi
  
  # Command not found
  echo "Unknown command: $1"
  echo "Use 'f help' to see available commands."
  return 1
}
# === End Functions from fzf.zsh ===

# === Functions from defaults.zsh ===
function setup_macos_preferences() {
  info "Configuring macOS system preferences..."
  
  # Faster key repeat
  defaults write NSGlobalDomain KeyRepeat -int 2
  defaults write NSGlobalDomain InitialKeyRepeat -int 15
  
  # Disable press-and-hold for keys in favor of key repeat
  defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
  
  # Always show file extensions
  defaults write NSGlobalDomain AppleShowAllExtensions -bool true
  
  # Don't write .DS_Store files on network drives
  defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
  
  # Dock settings
  defaults write com.apple.dock autohide -bool true
  defaults write com.apple.dock autohide-delay -float 0
  defaults write com.apple.dock show-recents -bool false
  
  # Enable trackpad tap to click
  defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
  
  # Finder settings
  defaults write com.apple.finder AppleShowAllFiles -bool true
  defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
  defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
  defaults write com.apple.finder ShowPathbar -bool true
  defaults write com.apple.finder ShowStatusBar -bool true
  defaults write com.apple.finder _FXSortFoldersFirst -bool true
  
  # Restart affected applications
  for app in "Finder" "Dock"; do
    killall "$app" &>/dev/null || true
  done
  
  success "macOS preferences configured"
}
# === End Functions from defaults.zsh ===

# === Functions from utils.zsh ===
# Log information message
function log_info() {
  printf "${BLUE}[INFO]${RESET} %s\n" "$*"
}

# Log success message
function log_success() {
  printf "${GREEN}[SUCCESS]${RESET} %s\n" "$*"
}

# Log warning message
function log_warn() {
  printf "${YELLOW}[WARNING]${RESET} %s\n" "$*" >&2
}

# Log error message
function log_error() {
  printf "${RED}[ERROR]${RESET} %s\n" "$*" >&2
}

# Aliases for different naming conventions
function info() { log_info "$@"; }
function success() { log_success "$@"; }
function warn() { log_warn "$@"; }
function error() { log_error "$@"; }

# List all utility functions exported by this file
export function list_utils() {
  local util_funcs=$(functions | grep "^[a-z].*() {" | grep -v "^_" | sort)
  local count=$(echo "$util_funcs" | wc -l | tr -d ' ')

  log_info "Available utility functions ($count total):"
  echo "$util_funcs" | sed 's/() {.*//' | column
}

# Detect if running interactively
export function is_interactive() {
  [[ -o interactive ]]
}

# Detect if being sourced
export function is_sourced() {
  [[ "${FUNCNAME[1]-main}" != main ]]
}

# Check if a command exists
export function has_command() {
  command -v "$1" &>/dev/null
}

# System detection functions
export function is_macos() {
  [[ "$(uname -s)" == "Darwin" ]]
}

export function is_linux() {
  [[ "$(uname -s)" == "Linux" ]]
}

export function is_apple_silicon() {
  [[ "$(uname -m)" == "arm64" ]] && is_macos
}

export function is_rosetta() {
  # Check if a process is running under Rosetta translation
  if is_apple_silicon; then
    local arch_output
    arch_output=$(arch)
    [[ "$arch_output" != "arm64" ]]
  else
    false
  fi
}

export function get_macos_version() {
  if is_macos; then
    sw_vers -productVersion
  else
    echo "Not macOS"
  fi
}

# Install a tool if it's missing
export function ensure_tool_installed() {
  local tool="$1"
  local install_cmd="$2"
  local is_essential="${3:-false}"

  if ! has_command "$tool"; then
    if [[ "$is_essential" == "true" ]] || [[ "${INSTALL_MODE:-false}" == "true" ]]; then
      log_info "Installing missing $tool..."
      eval "$install_cmd"
      return $?
    else
      log_info "Tool '$tool' is not installed but not marked essential. Skipping."
      return 0
    fi
  fi
  return 0
}

# Create a directory if it doesn't exist
export function ensure_dir() {
  local dir="$1"
  if [[ ! -d "$dir" ]]; then
    mkdir -p "$dir"
    log_success "Created directory: $dir"
  fi
}

# Alias for backward compatibility
export function dir_exists() {
  ensure_dir "$@"
}

# Create a backup of a file
export function backup_file() {
  local file="$1"
  local backup_dir="${2:-$_BACKUP_DIR}"

  if [[ -e "$file" ]]; then
    ensure_dir "$backup_dir"
    cp -a "$file" "$backup_dir/"
    log_success "Backed up $file to $backup_dir"
  else
    log_warn "File $file does not exist, skipping backup"
  fi
}

# Check if a file exists and is readable
export function file_exists() {
  [[ -r "$1" ]]
}

# Safe source - source a file if it exists
export function safe_source() {
  local file="$1"
  if file_exists "$file"; then
    source "$file"
    return 0
  else
    return 1
  fi
}

# Initialize Homebrew path based on architecture
export function brew_init() {
  # Skip if brew is already in PATH
  if has_command brew; then
    return 0
  fi

  if is_apple_silicon; then
    if [[ -x /opt/homebrew/bin/brew ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
      log_success "Initialized Homebrew for Apple Silicon"
      return 0
    fi
  else
    if [[ -x /usr/local/bin/brew ]]; then
      eval "$(/usr/local/bin/brew shellenv)"
      log_success "Initialized Homebrew for Intel Mac"
      return 0
    fi
  fi

  log_warn "Homebrew not found. Install it with: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
  return 1
}

# uninstall brew
export function uninstall_brew() {
  if has_command brew; then
    log_info "Uninstalling Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
    log_success "Homebrew uninstalled"
  else
    log_warn "Homebrew is not installed"
  fi
}

# Add a directory to PATH if it exists and isn't already in PATH
export function path_add() {
  local dir="$1"
  if [[ -d "$dir" ]] && [[ ":$PATH:" != *":$dir:"* ]]; then
    export PATH="$dir:$PATH"
    return 0
  fi
  return 1
}

# Remove a directory from PATH
export function path_remove() {
  local dir="$1"
  if [[ ":$PATH:" == *":$dir:"* ]]; then
    export PATH=${PATH//:$dir:/:}  # Remove middle
    export PATH=${PATH/#$dir:/}    # Remove beginning
    export PATH=${PATH/%:$dir/}    # Remove end
    return 0
  fi
  return 1
}

# List PATH entries
export function path_list() {
  echo $PATH | tr ':' '\n' | nl
}

# Print the expanded PATH as a list
export function path_print() {
  echo "PATH components:"
  path_list | awk '{printf "  %2d: %s\n", $1, $2}'
}

export function sys() {
  case "$1" in
  env-grep)
    echo "======== env vars =========="
    if [ -z "$2" ]; then
      printenv | sort | awk -F= '{ printf "%-30s %s\n", $1, $2 }'
    else
      printenv | sort | grep -i "$2" | awk -F= '{ printf "%-30s %s\n", $1, $2 }'
    fi
    echo "============================"
    ;;

  hidden | toggle-hidden)
    local current
    current=$(defaults read com.apple.finder AppleShowAllFiles)
    defaults write com.apple.finder AppleShowAllFiles $((!current))
    killall Finder
    echo "Finder hidden files: $((!current))" # Toggle macOS hidden files
    ;;

  ql | quick-look)
    if [ -z "$2" ]; then
      echo "Usage: sys ql <file>"
      return 1
    fi
    qlmanage -p "${@:2}" &>/dev/null # Quick Look files from terminal
    ;;

  killport | kill-port)
    local port="$2"
    if [[ -z "$port" ]]; then
      echo "Please specify a port number"
      return 1
    fi

    local pid
    pid=$(lsof -i ":$port" | awk 'NR!=1 {print $2}')

    if [[ -z "$pid" ]]; then
      echo "No process found on port $port"
      return 1
    fi

    echo "Killing process(es) on port $port: $pid"
    echo "$pid" | xargs kill -9
    echo "Process(es) killed" # Kill process on specified port
    ;;

  man | batman)
    MANPAGER="sh -c 'col -bx | bat -l man -p'" man "${@:2}" # Improved man pages with bat
    ;;

  ports | listening)
    sudo lsof -iTCP -sTCP:LISTEN -n -P # Show all listening ports
    ;;

  space | disk)
    df -h # Check disk space usage
    ;;

  cpu)
    top -l 1 | grep -E "^CPU" # Show CPU usage
    ;;

  mem | memory)
    vm_stat | perl -ne '/page size of (\d+)/ and $size=$1; /Pages\s+([^:]+)[^\d]+(\d+)/ and printf("%-16s % 16.2f MB\n", "$1:", $2 * $size / 1048576);' # Show memory usage
    ;;

  path)
    path_print # List PATH entries
    ;;

  ip | myip)
    echo "Public IP: $(curl -s https://ipinfo.io/ip)"
    echo "Local IP: $(ipconfig getifaddr en0)" # Show IP addresses
    ;;

  help | *)
    if [[ "$1" != "help" && ! -z "$1" ]]; then
      echo "Unknown command: $1"
    fi

    echo "Usage: sys [command]"
    echo ""
    echo "Commands:"
    echo "  env [pattern]      - Display environment variables, optionally filtered"
    echo "  hidden             - Toggle hidden files in Finder"
    echo "  ql <file>          - Quick Look a file"
    echo "  killport <port>    - Kill process running on specified port"
    echo "  man <command>      - Show man pages with syntax highlighting"
    echo "  ports              - Show all listening ports"
    echo "  space              - Check disk space usage"
    echo "  cpu                - Show CPU usage"
    echo "  mem                - Show memory usage"
    echo "  path               - List PATH entries"
    echo "  ip                 - Show public and local IP addresses"
    ;;
  esac
}

# Apply common macOS system preferences
export function defaults_apply() {
  if ! is_macos; then
    log_error "Not running on macOS"
    return 1
  fi

  log_info "Applying macOS preferences..."

  # Keyboard settings
  defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
  defaults write NSGlobalDomain AppleShowAllExtensions -bool true
  defaults write NSGlobalDomain InitialKeyRepeat -int 15
  defaults write NSGlobalDomain KeyRepeat -int 2

  # File system behavior
  defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

  # Dock settings
  defaults write com.apple.dock autohide -bool true
  defaults write com.apple.dock autohide-delay -float 0
  defaults write com.apple.dock show-recents -bool false

  # Trackpad settings
  defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true

  # Finder settings
  defaults write com.apple.finder AppleShowAllFiles -bool true
  defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
  defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
  defaults write com.apple.finder ShowPathbar -bool true
  defaults write com.apple.finder ShowStatusBar -bool true
  defaults write com.apple.finder _FXSortFoldersFirst -bool true

  # Restart affected applications
  for app in "Finder" "Dock"; do
    killall "$app" >/dev/null 2>&1 || true
  done

  log_success "macOS preferences applied"
}

# Setup Homebrew and install packages
export function setup_homebrew() {
  info "Setting up Homebrew..."

  if is_apple_silicon; then
    local brew_path="/opt/homebrew/bin/brew"
  else
    local brew_path="/usr/local/bin/brew"
  fi

  if [[ ! -x $brew_path ]]; then
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    if is_apple_silicon; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    else
      eval "$(/usr/local/bin/brew shellenv)"
    fi
  else
    info "Homebrew is already installed"
  fi

  # Update Homebrew if running from an installation script
  if [[ "${INSTALL_MODE:-false}" == "true" ]]; then
    info "Updating Homebrew..."
    brew update

    # Install from Brewfile
    if [[ -f "$_DOTFILES/Brewfile" ]]; then
      info "Installing packages from Brewfile..."
      brew bundle install --verbose --global --all --force
    else
      warn "Brewfile not found at $_DOTFILES/Brewfile"
    fi
  fi
}

# Setup ZSH configuration
export function setup_zsh() {
  info "Setting up ZSH configuration..."

  # Use environment vars if set, fall back to internal vars if not
  local zdotdir_src="${ZDOTDIR_SRC:-$_DOTFILES/config/zsh}"

  # Create .zshenv in home directory pointing to dotfiles
  info "Creating .zshenv to point to dotfiles ZSH configuration"
  cat >"$HOME/.zshenv" <<EOF
# ZSH configuration bootstrapper
# Auto-generated by dotfiles setup
export ZDOTDIR="$zdotdir_src"
[[ -f "$zdotdir_src/.zshenv" ]] && source "$zdotdir_src/.zshenv"
EOF

  chmod 644 "$HOME/.zshenv"
  success "Created $HOME/.zshenv pointing to $zdotdir_src"
}

# Verify the dotfiles repository structure
export function verify_repo_structure() {
  info "Verifying dotfiles repository structure..."

  # Check if dotfiles directory exists
  if [[ ! -d "$_DOTFILES" ]]; then
    error "Dotfiles directory not found at $_DOTFILES"
    error "Please clone the repository first: git clone <repo-url> $_DOTFILES"
    return 1
  fi

  # Check if it's a git repository
  if [[ ! -d "$_DOTFILES/.git" ]]; then
    error "The dotfiles directory is not a git repository"
    error "Please clone the repository properly: git clone <repo-url> $_DOTFILES"
    return 1
  fi

  # Check for critical directories and files
  local missing_items=()

  [[ ! -f "$_DOTFILES/Brewfile" ]] && missing_items+=("Brewfile")
  [[ ! -d "$_DOTFILES/config" ]] && missing_items+=("config dir")
  [[ ! -d "$_DOTFILES/config/zsh" ]] && missing_items+=("config/zsh dir")
  [[ ! -f "$_DOTFILES/config/zsh/.zshenv" ]] && missing_items+=("config/zsh/.zshenv file")
  [[ ! -f "$_DOTFILES/config/zsh/.zprofile" ]] && missing_items+=("config/zsh/.zprofile file")
  [[ ! -f "$_DOTFILES/config/zsh/.zshrc" ]] && missing_items+=("config/zsh/.zshrc file")
  [[ ! -f "$_DOTFILES/config/zsh/utils.zsh" ]] && missing_items+=("config/zsh/utils.zsh file")

  if ((${#missing_items[@]} > 0)); then
    error "The dotfiles repository is missing critical components:"
    for item in "${missing_items[@]}"; do
      error "  - Missing $item"
    done
    error "Please ensure you've cloned the correct repository."
    return 1
  fi

  success "Repository structure verified successfully"
  return 0
}

# Setup CLI tools and configurations
export function setup_cli_tools() {
  info "Setting up CLI tools configuration..."

  # Get the correct path map based on environment vars or fallback
  local dotfiles="${DOTFILES:-$_DOTFILES}"

  # First, remove all existing symlinks and files that we'll be managing
  # Only do this in full installation mode to avoid disrupting the user's session
  if [[ "${INSTALL_MODE:-false}" == "true" ]]; then
    info "Cleaning up existing configurations..."
    for key in ${(k)DOTFILES_TO_SYMLINK_MAP}; do
      local dst="${DOTFILES_TO_SYMLINK_MAP[$key]}"

      # Remove existing symlink or file/directory
      if [[ -L "$dst" || -e "$dst" ]]; then
        rm -rf "$dst"
        success "Removed existing: $dst"
      fi
    done
  fi

  # Create symlinks for missing targets
  info "Creating missing symlinks..."
  for key in ${(k)DOTFILES_TO_SYMLINK_MAP}; do
    local src="$key"
    local dst="${DOTFILES_TO_SYMLINK_MAP[$key]}"
    local parent_dir=$(dirname "$dst")

    # Create parent directory if it doesn't exist
    ensure_dir "$parent_dir"

    # Create the symlink if it doesn't exist or is pointing to the wrong location
    if [[ ! -e "$dst" ]] || [[ "$(readlink "$dst")" != "$src" ]]; then
      if [[ -e "$src" ]]; then
        ln -sf "$src" "$dst"
        success "Symlinked $dst -> $src"
      else
        warn "Source '$src' does not exist, skipping"
      fi
    fi
  done
}

# Install essential tools
export function install_essential_tools() {
  info "Installing essential tools..."

  # Install Homebrew if needed
  if ! has_command "brew"; then
    setup_homebrew
  fi

  # Order of tool installation (prioritize essential tools)
  local tool_names=(starship nvim fzf eza zoxide atuin volta uv rustup go)

  # Install each tool if missing
  for tool_name in "${tool_names[@]}"; do
    local install_cmd="${TOOL_INSTALL_COMMANDS[$tool_name]}"
    local is_essential="${TOOL_IS_ESSENTIAL[$tool_name]}"
    ensure_tool_installed "$tool_name" "$install_cmd" "$is_essential"
  done

  success "Essential tools installed"
}
# === End Functions from utils.zsh ===

# === Functions from brew.zsh ===
_brew_check() {
  if ! has_command brew; then
    log_error "Homebrew is not installed or not in PATH"
    return 1
  fi
  return 0
}
_fzf_check() {
  if ! has_command fzf; then
    log_error "fzf is required for this operation. Install with: brew install fzf"
    return 1
  fi
  return 0
}
_brewfile_path() {
  local param="${1:-$_BREWFILE}"
  
  if [[ "$param" == "--global" ]]; then
    echo "--global"
  else
    echo "${param:-$_BREWFILE}"
  fi
}
_add_to_brewfile() {
  local type="$1"  # "brew", "cask", "tap", etc.
  local items="$2"
  local brewfile="${3:-$_BREWFILE}"
  
  if [[ ! -f "$brewfile" ]]; then
    touch "$brewfile"
  fi
  
  log_info "Adding to Brewfile: $items"
  
  local count=0
  for item in ${(f)items}; do
    if ! grep -q "^$type \"$item\"$" "$brewfile"; then
      echo "$type \"$item\"" >> "$brewfile"
      ((count++))
    fi
  done
  
  if [[ $count -gt 0 ]]; then
    log_success "Added $count packages to Brewfile at $brewfile"
  else
    log_info "All packages already in Brewfile"
  fi
}
export function b_update() {
  _brew_check || return 1
  
  log_info "Updating Homebrew..."
  brew update && brew upgrade && brew cleanup
  log_success "Homebrew packages updated and cleaned up"
}
export function b_cleanup() {
  _brew_check || return 1
  
  log_info "Cleaning up Homebrew packages..."
  brew cleanup --prune=all
  brew autoremove
  log_success "Removed unused packages and cleaned up"
}
export function b_install() {
  _brew_check || return 1
  
  if [[ -z "$1" ]]; then
    log_error "No package specified. Usage: b_install <package>"
    return 1
  fi
  
  log_info "Installing $1..."
  if brew install "$1"; then
    log_success "Installed $1 successfully"
    return 0
  else
    log_error "Failed to install $1"
    return 1
  fi
}
export function b_cask() {
  _brew_check || return 1
  
  if [[ -z "$1" ]]; then
    log_error "No cask specified. Usage: b_cask <cask>"
    return 1
  fi
  
  log_info "Installing cask $1..."
  if brew install --cask "$1"; then
    log_success "Installed cask $1 successfully"
    return 0
  else
    log_error "Failed to install cask $1"
    return 1
  fi
}
export function b_info() {
  _brew_check || return 1
  
  if [[ -z "$1" ]]; then
    log_error "No package specified. Usage: b_info <package>"
    return 1
  fi
  
  brew info "$1"
}
export function b_list() {
  _brew_check || return 1
  
  case "$1" in
    casks)
      log_info "Installed casks:"
      brew list --cask
      ;;
    leaves)
      log_info "Installed leaf packages (not dependencies):"
      brew leaves
      ;;
    *)
      log_info "Installed packages:"
      brew list
      ;;
  esac
}
export function b_remove() {
  _brew_check || return 1
  
  if [[ -z "$1" ]]; then
    log_error "No package specified. Usage: b_remove <package>"
    return 1
  fi
  
  log_info "Removing $1..."
  if brew uninstall "$1"; then
    log_success "Removed $1 successfully"
    return 0
  else
    log_error "Failed to remove $1"
    return 1
  fi
}
export function bb_install() {
  _brew_check || return 1
  
  local brewfile=$(_brewfile_path "$1")
  local is_global=false
  local file_flag=""
  
  if [[ "$brewfile" == "--global" ]]; then
    is_global=true
    log_info "Installing packages from global Brewfile..."
  else
    if [[ ! -f "$brewfile" ]]; then
      log_error "Brewfile not found at $brewfile"
      return 1
    fi
    log_info "Installing packages from $brewfile..."
    file_flag="--file=$brewfile"
  fi
  
  local cmd="brew bundle install --verbose"
  [[ "$is_global" == true ]] && cmd="$cmd --global" || cmd="$cmd $file_flag"
  cmd="$cmd --cleanup"
  
  if eval "$cmd"; then
    log_success "Installed all packages from Brewfile"
    return 0
  else
    log_error "Failed to install packages from Brewfile"
    return 1
  fi
}
export function bb_check() {
  _brew_check || return 1
  
  local brewfile=$(_brewfile_path "$1")
  local is_global=false
  local file_flag=""
  
  if [[ "$brewfile" == "--global" ]]; then
    is_global=true
  else
    file_flag="--file=$brewfile"
  fi
  
  log_info "Checking Brewfile status..."
  
  local cmd="brew bundle check --verbose"
  [[ "$is_global" == true ]] && cmd="$cmd --global" || cmd="$cmd $file_flag"
  
  if eval "$cmd"; then
    log_success "All packages in Brewfile are installed"
    return 0
  else
    log_warn "Some packages in Brewfile are not installed"
    return 1
  fi
}
export function bb_dump() {
  _brew_check || return 1
  
  local brewfile=$(_brewfile_path "$1")
  local is_global=false
  local file_flag=""
  
  if [[ "$brewfile" == "--global" ]]; then
    is_global=true
    log_info "Dumping to global Brewfile..."
  else
    log_info "Dumping to $brewfile..."
    file_flag="--file=$brewfile"
  fi
  
  local cmd="brew bundle dump --verbose"
  [[ "$is_global" == true ]] && cmd="$cmd --global" || cmd="$cmd $file_flag"
  cmd="$cmd --force"
  
  if eval "$cmd"; then
    log_success "Created Brewfile successfully"
    return 0
  else
    log_error "Failed to create Brewfile"
    return 1
  fi
}
export function bb_list_cleanup() {
  _brew_check || return 1
  
  local brewfile=$(_brewfile_path "$1")
  local is_global=false
  local file_flag=""
  
  if [[ "$brewfile" == "--global" ]]; then
    is_global=true
  else
    file_flag="--file=$brewfile"
  fi
  
  log_info "Packages that would be removed (not in Brewfile):"
  
  local cmd="brew bundle cleanup --verbose"
  [[ "$is_global" == true ]] && cmd="$cmd --global" || cmd="$cmd $file_flag"
  
  eval "$cmd"
}
export function bb_cleanup() {
  _brew_check || return 1
  
  local brewfile=$(_brewfile_path "$1")
  local is_global=false
  local file_flag=""
  
  if [[ "$brewfile" == "--global" ]]; then
    is_global=true
  else
    file_flag="--file=$brewfile"
  fi
  
  log_info "Analyzing packages not in Brewfile..."
  
  # Show what would be removed first
  local cmd="brew bundle cleanup --verbose"
  [[ "$is_global" == true ]] && cmd="$cmd --global" || cmd="$cmd $file_flag"
  
  local to_remove=$(eval "$cmd")
  
  if [[ -z "$to_remove" ]]; then
    log_info "No packages to remove"
    return 0
  fi
  
  log_info "The following packages will be removed:"
  echo "$to_remove"
  
  echo ""
  echo "Proceed with removal? (y/n)"
  read -k 1 confirm
  echo ""
  
  if [[ "$confirm" == "y" ]]; then
    cmd="$cmd --force"
    if eval "$cmd"; then
      log_success "Removed packages not in Brewfile"
      return 0
    else
      log_error "Failed to remove packages"
      return 1
    fi
  else
    log_info "Cleanup canceled"
    return 0
  fi
}
export function bb_edit() {
  _brew_check || return 1
  
  local brewfile=$(_brewfile_path "$1")
  
  if [[ "$brewfile" == "--global" ]]; then
    brew bundle edit --global
  else
    if [[ ! -f "$brewfile" ]]; then
      log_warn "Brewfile not found at $brewfile, creating new file"
      touch "$brewfile"
    fi
    
    ${EDITOR:-vi} "$brewfile"
  fi
}
export function bf_install() {
  _brew_check || return 1
  _fzf_check || return 1
  
  log_info "Searching packages..."
  
  local selected
  selected=$(brew search | fzf -m \
    --header="Select packages to install (TAB: multiple, SPACE: preview)" \
    --preview="brew info {}" \
    --preview-window=right:70% \
    --bind=space:toggle-preview)
  
  if [[ -n "$selected" ]]; then
    log_info "Installing: $selected"
    brew install ${(f)selected}
    log_success "Installation complete"
    
    # Prompt to add to Brewfile
    echo "Add to Brewfile? (y/n)"
    read -k 1 add_to_brewfile
    echo ""
    
    if [[ "$add_to_brewfile" == "y" ]]; then
      _add_to_brewfile "brew" "$selected"
    fi
    
    return 0
  else
    log_info "No packages selected"
    return 0
  fi
}
export function bf_cask() {
  _brew_check || return 1
  _fzf_check || return 1
  
  log_info "Searching casks..."
  
  local selected
  selected=$(brew search --casks | fzf -m \
    --header="Select casks to install (TAB: multiple, SPACE: preview)" \
    --preview="brew info --cask {}" \
    --preview-window=right:70% \
    --bind=space:toggle-preview)
  
  if [[ -n "$selected" ]]; then
    log_info "Installing casks: $selected"
    brew install --cask ${(f)selected}
    log_success "Installation complete"
    
    # Prompt to add to Brewfile
    echo "Add to Brewfile? (y/n)"
    read -k 1 add_to_brewfile
    echo ""
    
    if [[ "$add_to_brewfile" == "y" ]]; then
      _add_to_brewfile "cask" "$selected"
    fi
    
    return 0
  else
    log_info "No casks selected"
    return 0
  fi
}
export function bf_remove() {
  _brew_check || return 1
  _fzf_check || return 1
  
  log_info "Listing installed packages..."
  
  local selected
  selected=$(brew list | fzf -m \
    --header="Select packages to remove (TAB: multiple, SPACE: preview)" \
    --preview="brew info {}" \
    --preview-window=right:70% \
    --bind=space:toggle-preview)
  
  if [[ -n "$selected" ]]; then
    log_info "Removing: $selected"
    brew uninstall ${(f)selected}
    log_success "Removal complete"
    return 0
  else
    log_info "No packages selected"
    return 0
  fi
}
export function bf_tap() {
  _brew_check || return 1
  _fzf_check || return 1
  
  log_info "Loading available taps..."
  
  # Get top taps from GitHub
  local top_taps=(
    "homebrew/cask"
    "homebrew/cask-fonts"
    "homebrew/cask-versions"
    "homebrew/core"
    "homebrew/services"
    "hashicorp/tap"
    "mongodb/brew"
    "neovim/neovim"
    "heroku/brew"
    "cloudflare/cloudflare"
  )
  
  # Combine with currently tapped
  local current_taps=$(brew tap)
  local all_taps=("${top_taps[@]}" "${(f)current_taps}")
  
  # Remove duplicates
  local unique_taps=($(echo "${all_taps[@]}" | tr ' ' '\n' | sort -u))
  
  local selected
  selected=$(printf "%s\n" "${unique_taps[@]}" | fzf -m \
    --header="Select taps to add (TAB: multiple)" \
    --preview="brew tap-info {}" \
    --preview-window=right:70% \
    --bind=space:toggle-preview)
  
  if [[ -n "$selected" ]]; then
    log_info "Adding taps: $selected"
    for tap in ${(f)selected}; do
      brew tap "$tap"
    done
    log_success "Taps added successfully"
    
    # Prompt to add to Brewfile
    echo "Add to Brewfile? (y/n)"
    read -k 1 add_to_brewfile
    echo ""
    
    if [[ "$add_to_brewfile" == "y" ]]; then
      _add_to_brewfile "tap" "$selected"
    fi
    
    return 0
  else
    log_info "No taps selected"
    return 0
  fi
}
export function brew() {
  if ! has_command fzf || [[ $# -gt 0 ]]; then
    # If fzf not available or args provided, pass through to normal brew
    command brew "$@"
    return $?
  fi
  
  # Define commands and descriptions
  local commands=(
    "update:Update Homebrew and all packages:brew update && brew upgrade && brew cleanup"
    "install:Install a package:brew install"
    "cask:Install a cask:brew install --cask"
    "info:Show package information:brew info"
    "search:Search for a package:brew search"
    "list:List installed packages:brew list"
    "leaves:List leaf packages (not dependencies):brew leaves"
    "deps:Show dependency tree:brew deps --tree --installed"
    "doctor:Run brew diagnostics:brew doctor"
    "tap:Add a tap repository:brew tap"
    "casks:List installed casks:brew list --cask"
    "services:Manage background services:brew services"
    "cleanup:Remove old versions:brew cleanup"
    "autoremove:Remove unused dependencies:brew autoremove"
    "outdated:Show outdated packages:brew outdated"
    "pin:Pin a package to prevent upgrades:brew pin"
    "unpin:Unpin a package:brew unpin"
    "uses:Show formulas that depend on specified formula:brew uses --installed"
  )
  
  # Show interactive menu with fzf
  local selected
  selected=$(printf "%s\n" "${commands[@]}" | 
    awk -F: '{printf "%-15s %s\n", $1, $2}' |
    fzf --header="Select a brew command" \
        --preview="echo; echo Description: {2..}; echo; echo Command: $(echo {3..} | sed 's/^//')" \
        --preview-window=bottom:3:wrap)
  
  if [[ -n "$selected" ]]; then
    local cmd=$(echo "$selected" | awk '{print $1}')
    local idx=0
    local cmd_line=""
    
    # Find the matching command
    for c in "${commands[@]}"; do
      local cmd_name=$(echo "$c" | cut -d: -f1)
      if [[ "$cmd_name" == "$cmd" ]]; then
        cmd_line=$(echo "$c" | cut -d: -f3)
        break
      fi
    done
    
    if [[ -n "$cmd_line" ]]; then
      log_info "Executing: $cmd_line"
      eval "$cmd_line"
    fi
  fi
}
export function b() {
  if [[ $# -gt 0 ]]; then
    # Direct execution if args provided
    case "$1" in
      # Basic brew operations
      update|up)     b_update ;;
      cleanup|clean) b_cleanup ;;
      install|in)    shift; b_install "$@" ;;
      cask)          shift; b_cask "$@" ;;
      info)          shift; b_info "$@" ;;
      list|ls)       shift; b_list "$@" ;;
      remove|rm)     shift; b_remove "$@" ;;
      
      # Interactive operations with fzf
      fin)           bf_install ;;
      fcask)         bf_cask ;;
      frm)           bf_remove ;;
      ftap)          bf_tap ;;
      
      # Help and default case
      help|--help|-h) _show_brew_help ;;
      *)
        # Pass through to brew
        command brew "$@"
        ;;
    esac
    return $?
  fi
  
  # Interactive selection with fzf if no args
  if has_command fzf; then
    _select_brew_command
  else
    _show_brew_help
  fi
}
export function bb() {
  if [[ $# -gt 0 ]]; then
    # Direct execution if args provided
    case "$1" in
      install|in)      shift; bb_install "$@" ;;
      check|c)         shift; bb_check "$@" ;;
      dump|d)          shift; bb_dump "$@" ;;
      list-cleanup|lc) shift; bb_list_cleanup "$@" ;;
      cleanup|c)       shift; bb_cleanup "$@" ;;
      edit|e)          shift; bb_edit "$@" ;;
      
      # Help and default case
      help|--help|-h)  _show_brewfile_help ;;
      *)
        log_error "Unknown Brewfile command: $1"
        _show_brewfile_help
        return 1
        ;;
    esac
    return $?
  fi
  
  # Interactive selection with fzf if no args
  if has_command fzf; then
    _select_brewfile_command
  else
    _show_brewfile_help
  fi
}
_show_brew_help() {
  echo "Homebrew management utility"
  echo ""
  echo "Usage: b <command> [arguments]"
  echo ""
  echo "Basic Commands:"
  echo "  update, up       Update Homebrew and upgrade all packages"
  echo "  cleanup, clean   Clean up and remove unused packages"
  echo "  install, in      Install a package"
  echo "  cask             Install a cask"
  echo "  info             Show package information"
  echo "  list, ls         List installed packages"
  echo "  remove, rm       Remove a package"
  echo ""
  echo "Interactive Commands (require fzf):"
  echo "  fin              Interactive package installation"
  echo "  fcask            Interactive cask installation"
  echo "  frm              Interactive package removal"
  echo "  ftap             Interactive tap selection"
  echo ""
  echo "Use 'bb' for Brewfile operations"
}
_show_brewfile_help() {
  echo "Brewfile management utility"
  echo ""
  echo "Usage: bb <command> [arguments]"
  echo ""
  echo "Commands:"
  echo "  install, in      Install packages from Brewfile"
  echo "  check, c         Check if all packages in Brewfile are installed"
  echo "  dump, d          Create Brewfile from installed packages"
  echo "  list-cleanup, lc List packages not in Brewfile"
  echo "  cleanup, c       Remove packages not in Brewfile"
  echo "  edit, e          Edit Brewfile"
}
_select_brew_command() {
  _fzf_check || { _show_brew_help; return 1; }
  
  local commands=(
    "update:Update Homebrew and upgrade all packages:b_update"
    "cleanup:Clean up and remove unused packages:b_cleanup"
    "install:Install a package (interactive):bf_install"
    "cask:Install a cask (interactive):bf_cask"
    "remove:Remove packages (interactive):bf_remove"
    "tap:Add a tap repository (interactive):bf_tap"
    "list:List installed packages:b_list"
    "leaves:List leaf packages (not dependencies):b_list leaves"
    "casks:List installed casks:b_list casks"
  )
  
  local selected
  selected=$(printf "%s\n" "${commands[@]}" | 
    awk -F: '{printf "%-15s %s\n", $1, $2}' |
    fzf --header="Select a brew command" \
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
function _select_brewfile_command() {
  _fzf_check || { _show_brewfile_help; return 1; }
  
  local commands=(
    "install:Install packages from Brewfile:bb_install"
    "check:Check if all packages in Brewfile are installed:bb_check"
    "dump:Create Brewfile from installed packages:bb_dump"
    "list-cleanup:List packages not in Brewfile:bb_list_cleanup"
    "cleanup:Remove packages not in Brewfile:bb_cleanup"
    "edit:Edit Brewfile:bb_edit"
  )
  
  local selected
  selected=$(printf "%s\n" "${commands[@]}" | 
    awk -F: '{printf "%-15s %s\n", $1, $2}' |
    fzf --header="Select a Brewfile command" \
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
# === End Functions from brew.zsh ===
#
#
#


# Docker functions with fzf integration
function _docker_select_container() {
  docker ps | fzf --header="Select a container" | awk '{print $1}'
}

function _docker_select_all_container() {
  docker ps -a | fzf --header="Select a container (including stopped)" | awk '{print $1}'
}

# function _docker_select_image() {
#   docker images | fzf --header="Select an image" | awk '{print $3}'
# }
#
# # Docker container management
# dsh() {
#   local container=$(_docker_select_container)
#   [[ -n "$container" ]] && docker exec -it "$container" sh
# }
#
# dbash() {
#   local container=$(_docker_select_container)
#   [[ -n "$container" ]] && docker exec -it "$container" bash
# }
#
# drm() {
#   local container=$(_docker_select_container)
#   [[ -n "$container" ]] && docker rm "$container"
# }
#
# drma() {
#   local container=$(_docker_select_all_container)
#   [[ -n "$container" ]] && docker rm "$container"
# }
#
# # Docker image management
# drmi() {
#   local image=$(_docker_select_image)
#   [[ -n "$image" ]] && docker rmi "$image"
# }
#
# # Docker logs
# dlogs() {
#   local container=$(_docker_select_container)
#   [[ -n "$container" ]] && docker logs -f "$container"
# }
#
# # Docker stats
# dstats() {
#   local container=$(_docker_select_container)
#   [[ -n "$container" ]] && docker stats "$container"
# }
#
# # Docker inspect
# dinspect() {
#   local container=$(_docker_select_container)
#   [[ -n "$container" ]] && docker inspect "$container" | bat -l json
# }
#
# # Docker compose
# dcomp() {
#   local compose_file=$(find . -name "docker-compose*.yml" | fzf --header="Select a compose file")
#   [[ -n "$compose_file" ]] && docker compose -f "$compose_file" "$@"
# }
#
# # Docker volume management
# dvol() {
#   local volume=$(docker volume ls | fzf --header="Select a volume" | awk '{print $2}')
#   [[ -n "$volume" ]] && docker volume inspect "$volume" | bat -l json
# }
#
# # Docker network management
# dnet() {
#   local network=$(docker network ls | fzf --header="Select a network" | awk '{print $2}')
#   [[ -n "$network" ]] && docker network inspect "$network" | bat -l json
# }
#
# # Docker system cleanup
# dclean() {
#   echo "Cleaning up unused containers, networks, images, and volumes..."
#   docker system prune -f
# }
#
# # Docker container restart
# drestart() {
#   local container=$(_docker_select_container)
#   [[ -n "$container" ]] && docker restart "$container"
# }
#
# # Docker container stop
# dstop() {
#   local container=$(_docker_select_container)
#   [[ -n "$container" ]] && docker stop "$container"
# }
#
# # Docker container start
# dstart() {
#   local container=$(_docker_select_all_container)
#   [[ -n "$container" ]] && docker start "$container"
# }
#
# # Docker container port mapping
# dports() {
#   local container=$(_docker_select_container)
#   [[ -n "$container" ]] && docker port "$container"
# }
#
# # Docker container environment variables
# denv() {
#   local container=$(_docker_select_container)
#   [[ -n "$container" ]] && docker exec "$container" env | sort
# }
#
# # Docker container processes
# dps() {
#   local container=$(_docker_select_container)
#   [[ -n "$container" ]] && docker top "$container"
# }
#
# # Docker container resource usage
# dtop() {
#   local container=$(_docker_select_container)
#   [[ -n "$container" ]] && docker stats --no-stream "$container"
# }
#
# # Docker container commit
# dcommit() {
#   local container=$(_docker_select_container)
#   if [[ -n "$container" ]]; then
#     read "repo?Enter repository name: "
#     read "tag?Enter tag: "
#     docker commit "$container" "$repo:$tag"
#   fi
# }
#
# # Docker container diff
# ddiff() {
#   local container=$(_docker_select_container)
#   [[ -n "$container" ]] && docker diff "$container"
# }
#
# # Docker container copy
# dcp() {
#   local container=$(_docker_select_container)
#   if [[ -n "$container" ]]; then
#     read "src?Enter source path: "
#     read "dst?Enter destination path: "
#     docker cp "$container:$src" "$dst"
#   fi
# }
#
# # Docker container exec with custom command
# dexec() {
#   local container=$(_docker_select_container)
#   if [[ -n "$container" ]]; then
#     read "cmd?Enter command to execute: "
#     docker exec -it "$container" $cmd
#   fi
# }
