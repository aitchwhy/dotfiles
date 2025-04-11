#!/usr/bin/env zsh
# ========================================================================
# FZF Integrated Utilities - Modern FZF Command Framework
# ========================================================================
# A unified interface for fzf-powered commands with dynamic discovery
# Usage: f <command> [args] or f to see available commands

# Source common utilities if not already loaded
[[ -f "$ZDOTDIR/utils.zsh" ]] && source "$ZDOTDIR/utils.zsh"

# ========================================================================
# Core FZF Configuration
# ========================================================================

# Default command for listing files
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'

# Default visual options
export FZF_DEFAULT_OPTS="
    --height 80%
    --layout=reverse
    --border sharp
    --margin=1
    --padding=1
    --info=inline
    --prompt='❯ '
    --pointer='▶'
    --marker='✓'
    --preview-window='right:60%:border-left'
    --bind='ctrl-/:toggle-preview'
    --bind='ctrl-y:execute-silent(echo {} | pbcopy)'
    --bind='ctrl-e:execute(${EDITOR:-nvim} {} < /dev/tty > /dev/tty)'
    --bind='ctrl-f:preview-page-down'
    --bind='ctrl-b:preview-page-up'
    --bind='ctrl-a:select-all'
    --bind='ctrl-d:deselect-all'
    --bind='change:first'
    --color=fg:#c0caf5,bg:#1a1b26,hl:#bb9af7
    --color=fg+:#c0caf5,bg+:#292e42,hl+:#7dcfff
    --color=info:#7aa2f7,prompt:#7dcfff,pointer:#7dcfff
    --color=marker:#9ece6a,spinner:#9ece6a,header:#9ece6a
"

# Preview command for files
export FZF_PREVIEW_COMMAND="bat --style=numbers,changes --color=always --line-range :500 {}"

# Standard keyboard shortcuts
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="--preview '$FZF_PREVIEW_COMMAND' --bind 'ctrl-/:toggle-preview' --header 'Select files'"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
export FZF_ALT_C_OPTS="--preview 'tree -C {} | head -200' --bind 'ctrl-/:toggle-preview' --header 'Jump to directory'"
export FZF_CTRL_R_OPTS="--preview 'echo {}' --preview-window=down:3:wrap --bind 'ctrl-/:toggle-preview' --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort' --header 'Search command history' --sort --exact"

# ========================================================================
# Helper Functions
# ========================================================================

# # Check if a command exists
# _f_has_command() {
#   command -v "$1" &>/dev/null
# }
# 
# # Search and display list with fzf then execute command on selection
# _f_search() {
#   local preview_cmd="$1"    # Preview command
#   local header="$2"         # Header text
#   local action_cmd="$3"     # Command to run on selection
#   local initial_query="${4:-}" # Initial search query
#   local fzf_opts="${5:-}"   # Additional fzf options
# 
#   if [[ -z "$action_cmd" ]]; then
#     # Simply display selection
#     fzf --preview "$preview_cmd" \
#         --header "$header" \
#         --query "$initial_query" \
#         $fzf_opts
#   else
#     # Run action on selection
#     fzf --preview "$preview_cmd" \
#         --header "$header" \
#         --query "$initial_query" \
#         $fzf_opts | eval "$action_cmd"
#   fi
# }
# 
# # Generate and display help from command registry
# _f_help() {
#   echo "FZF Command Framework - Interactive tools powered by fzf"
#   echo ""
#   echo "Usage: f [command] [args]"
#   echo "       f (with no arguments to show interactive menu)"
#   echo ""
# 
#   # Extract categories and commands from registry
#   local categories=()
#   local current_category=""
#   
#   for cmd_info in "${_F_COMMANDS[@]}"; do
#     local parts=("${(s/:/)cmd_info}")
#     local cmd_category="${parts[1]}"
#     
#     if [[ ! " ${categories[@]} " =~ " ${cmd_category} " ]]; then
#       categories+=("$cmd_category")
#     fi
#   done
#   
#   # Display commands by category
#   for category in "${categories[@]}"; do
#     echo "${category} Commands:"
#     
#     for cmd_info in "${_F_COMMANDS[@]}"; do
#       local parts=("${(s/:/)cmd_info}")
#       local cmd_category="${parts[1]}"
#       local cmd_name="${parts[2]}"
#       local cmd_aliases="${parts[3]}"
#       local cmd_desc="${parts[4]}"
#       
#       if [[ "$cmd_category" == "$category" ]]; then
#         if [[ -n "$cmd_aliases" ]]; then
#           printf "  %-15s %-10s - %s\n" "$cmd_name" "($cmd_aliases)" "$cmd_desc"
#         else
#           printf "  %-15s %11s %s\n" "$cmd_name" "" "$cmd_desc"
#         fi
#       fi
#     done
#     echo ""
#   done
# }
# 
# # Check if dependencies for a command are available
# _f_check_deps() {
#   local deps=($@)
#   local missing=()
#   
#   for dep in $deps; do
#     if ! _f_has_command "$dep"; then
#       missing+=("$dep")
#     fi
#   done
#   
#   if [[ ${#missing[@]} -gt 0 ]]; then
#     echo "Missing required dependencies: ${missing[@]}"
#     echo "Please install them to use this command."
#     return 1
#   fi
#   
#   return 0
# }

# ========================================================================
# Command Registry - Add commands here
# ========================================================================
# Format: "Category:CommandName:Aliases:Description"
_F_COMMANDS=(
  # File Operations
  "Files:find:f,file:Find files and open in editor"
  "Files:edit:e,nvim:Find and edit files with nvim"
  "Files:dir:d,cd:Find directories and cd to them"
  
  # Search Operations
  "Search:grep:g,search:Search file contents with ripgrep"
  "Search:rgopen:rg,r:Search and open matched files"
  "Search:ripgrep::Advanced search with ripgrep"
  
  # Git Operations
  "Git:checkout:co,gco:Git checkout branch"
  "Git:add:ga,a:Git add files interactively"
  "Git:stash:gst,s:Git stash operations"
  "Git:log:glog,l:Git log browser"
  "Git:status:gs:Git status with actions"
  "Git:diff:gd:Git diff browser"
  
  # System Operations
  "System:kill:k:Kill processes interactively"
  "System:port:p:Kill process on port"
  "System:man:m:Browse man pages"
  "System:alias:al:Browse aliases"
  "System:history:h:Search command history"
  
  # Package Management
  "Packages:brew:b:Brew package operations"
  "Packages:npm:n:NPM script runner"
  
  # Development
  "Dev:docker:dc:Docker container management"
  "Dev:z:j,jump:Jump to directories with zoxide"
)

# ========================================================================
# Shared Command Implementations
# ========================================================================

# File finder with preview
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

# Directory finder with preview
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

# Find files and edit with nvim
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

# Fuzzy grep with ripgrep
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

# Enhanced search with ripgrep
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

# Advanced search with ripgrep (the original rfv function but improved)
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

# Git checkout with FZF
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

# Git add with FZF
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

# Git stash operations
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

# Git log browser
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

# Git status with actions
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

# Git diff browser
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

# Process killing with FZF
_f_cmd_kill() {
  ps -ef | sed 1d |
    _f_search \
      "echo {}" \
      "Kill process (SIGTERM by default)" \
      "awk '{print \$2}' | xargs -r kill -${1:-15}" \
      "" \
      "--multi"
}

# Kill process on port
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

# Man page browser
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

# Alias browser
_f_cmd_alias() {
  alias |
    _f_search \
      "echo {}" \
      "Browse aliases" \
      "awk '{print \$0}'" \
      "${1:-}" \
      "--multi"
}

# Enhanced history search
_f_cmd_history() {
  history |
    _f_search \
      "echo {}" \
      "Search command history" \
      "awk '{print substr(\$0, index(\$0, \$2))}' | ${SHELL:-zsh}" \
      "${1:-}" \
      "--sort --exact --preview-window=down:3:wrap"
}

# Brew operations
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

# NPM script runner
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

# Docker container management
_f_cmd_docker() {
  _f_check_deps "docker" || return 1
  
  docker ps --format "{{.Names}}" |
    _f_search \
      "docker stats --no-stream {}" \
      "Select container" \
      "xargs -r docker exec -it bash"
}

# Jump to directories with zoxide
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

# ========================================================================
# Main FZF Command Function
# ========================================================================

# # Main entry point for all fzf commands
# f() {
#   # No arguments - show interactive command selector
#   if [[ $# -eq 0 ]]; then
#     local categories=()
#     local all_commands=()
#     
#     # Extract unique categories
#     for cmd_info in "${_F_COMMANDS[@]}"; do
#       local parts=("${(s/:/)cmd_info}")
#       local category="${parts[1]}"
#       
#       if [[ ! " ${categories[@]} " =~ " ${category} " ]]; then
#         categories+=("$category")
#       fi
#     done
#     
#     # Build command list with categories
#     for category in "${categories[@]}"; do
#       all_commands+=("$category:")
#       
#       for cmd_info in "${_F_COMMANDS[@]}"; do
#         local parts=("${(s/:/)cmd_info}")
#         local cmd_category="${parts[1]}"
#         local cmd_name="${parts[2]}"
#         local cmd_desc="${parts[4]}"
#         
#         if [[ "$cmd_category" == "$category" ]]; then
#           all_commands+=("  $cmd_name:$cmd_desc")
#         fi
#       done
#     done
#     
#     # Display interactive menu with fzf
#     local choice
#     choice=$(printf "%s\n" "${all_commands[@]}" |
#       fzf --height 60% --border sharp --cycle --ansi \
#           --preview 'echo Description: {2..}' \
#           --preview-window=down:3:wrap \
#           --bind='ctrl-/:toggle-preview' \
#           --header="Select a command (Categories are labeled)" \
#           --no-multi)
#           
#     # If category header was selected, get first command in that category
#     if [[ "$choice" =~ ^[A-Za-z]+:$ ]]; then
#       local category="${choice%:}"
#       for cmd_info in "${_F_COMMANDS[@]}"; do
#         local parts=("${(s/:/)cmd_info}")
#         if [[ "${parts[1]}" == "$category" ]]; then
#           choice="  ${parts[2]}:${parts[4]}"
#           break
#         fi
#       done
#     fi
#     
#     # Exit if no selection
#     [[ -z "$choice" ]] && return 0
#     
#     # Extract command name (trim leading whitespace if command was under category)
#     local cmd_name=$(echo "$choice" | cut -d: -f1 | sed 's/^ *//')
#     
#     # Run the command
#     f "$cmd_name"
#     return $?
#   fi
#   
#   # Help command
#   if [[ "$1" == "help" ]]; then
#     _f_help
#     return 0
#   fi
#   
#   # Look up command in registry
#   local cmd_func=""
#   local cmd_name=""
#   
#   for cmd_info in "${_F_COMMANDS[@]}"; do
#     local parts=("${(s/:/)cmd_info}")
#     local main_cmd="${parts[2]}"
#     local aliases="${parts[3]}"
#     
#     # Split aliases into array
#     local alias_array=("${(s/,/)aliases}")
#     
#     # Check command and aliases
#     if [[ "$1" == "$main_cmd" ]] || [[ " ${alias_array[@]} " =~ " $1 " ]]; then
#       cmd_name="$main_cmd"
#       cmd_func="_f_cmd_$main_cmd"
#       break
#     fi
#   done
#   
#   # If command found, execute it
#   if [[ -n "$cmd_func" ]]; then
#     shift
#     $cmd_func "$@"
#     return $?
#   fi
#   
#   # Command not found
#   echo "Unknown command: $1"
#   echo "Use 'f help' to see available commands."
#   return 1
# }

# ========================================================================
# Common Aliases - Shorter forms for frequently used commands
# ========================================================================

# # File navigation
# alias ff='f find'         # Find files
# alias fe='f edit'         # Find and edit files
# alias fd='f dir'          # Find directories
# alias fz='f z'            # Jump with zoxide
# 
# # Git operations
# alias fco='f checkout'    # Git checkout
# alias fga='f add'         # Git add files
# alias fgl='f log'         # Git log
# alias fgs='f status'      # Git status
# alias fgd='f diff'        # Git diff
# 
# # Search
# alias fgr='f grep'        # Grep with fzf
# alias frg='f rgopen'      # Ripgrep and open
# 
# # System
# alias fk='f kill'         # Kill process
# alias fp='f port'         # Kill process on port
# alias fh='f history'      # History search
# alias fm='f man'          # Man pages
# alias fa='f alias'        # Aliases
# 
# # Package management
# alias fb='f brew'         # Brew operations
# alias fbi='f brew install' # Brew install
# alias fbu='f brew uninstall' # Brew uninstall

# Load FZF completion and key bindings if available
if [[ -f ~/.fzf.zsh ]]; then
  source ~/.fzf.zsh
elif [[ -f /usr/share/fzf/shell/key-bindings.zsh ]]; then
  source /usr/share/fzf/shell/key-bindings.zsh
fi

# ========================================================================
# Initialization
# ========================================================================

# Check if fzf is installed
if ! _f_has_command "fzf"; then
  echo "Warning: fzf is not installed. Install it with: brew install fzf"
  echo "Then run: $(brew --prefix)/opt/fzf/install"
fi

# Print help message if this file is being sourced directly (not from .zshrc)
if [[ ${#funcstack[@]} -eq 0 ]]; then
  echo "FZF Command Framework loaded successfully"
  echo "Use 'f' or 'f help' to see available commands"
fi

# Function to preview files with bat in fzf
_f_preview() {
  fzf --preview 'bat --style=numbers --color=always --line-range :500 {}'
}
