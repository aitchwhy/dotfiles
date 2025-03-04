#!/usr/bin/env zsh

# ========================================================================
# ZSH Functions - Core utility functions organized by category
# ========================================================================


# ========================================================================
# Environment Settings
# ========================================================================

# source $ZDOTDIR/.zprofile
# export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
# export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
# export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
# export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
# export ZDOTDIR=${ZDOTDIR:-$HOME/.config/zsh}

# ========================================================================
# Dotfiles Management
# ========================================================================

function dot() {
  if [[ "$1" == "help" || -z "$1" ]]; then
    echo "Usage: dot [command]"
    echo ""
    echo "Commands:"
    # Extract commands and their descriptions from the function itself
    grep -E '^\s{2}[a-z|]*\)$' "$ZDOTDIR/functions.zsh" | 
      grep -A 1 -B 0 ")" | 
      sed -n '/)/N;s/\s\s\([a-z|]*\))\n\s\s\s\s\(.*\) #\(.*\)/  \1 - \3/p' |
      sort
  else
    case "$1" in
      z|zdir)
        cd $ZDOTDIR # Navigate to Zsh config directory
        ;;
      ze|zedit)
        fd --hidden --follow --type f . $ZDOTDIR | fzf --preview "bat --color=always {}" | xargs -r $EDITOR # Edit Zsh config files with fuzzy finder
        ;;
      cd|dots)
        cd $DOTFILES # Navigate to dotfiles directory
        ;;
      edit|e)
        fd --no-ignore --hidden --follow --type f . $DOTFILES | fzf --preview "bat --color=always {}" | xargs -r $EDITOR # Edit dotfiles with fuzzy finder
        ;;
      reload|r)
        exec zsh # Reload Zsh configuration
        ;;
      find|f)
        fd --no-ignore --hidden --follow --type f . "${2:-$DOTFILES}" | fzf --preview "bat --color=always {}" # Find files in dotfiles
        ;;
      grep|g)
        rg --hidden --follow --glob "!.git" "$2" "${3:-$DOTFILES}" # Search for pattern in dotfiles
        ;;
      sync|s)
        pushd $DOTFILES > /dev/null
        echo "📦 Syncing dotfiles repository..."
        git pull && git push
        popd > /dev/null # Sync dotfiles repository
        ;;
      backup|b)
        pushd $DOTFILES > /dev/null
        echo "💾 Backing up dotfiles..."
        timestamp=$(date +%Y%m%d-%H%M%S)
        git add -A && git commit -m "Backup: $timestamp" && git push
        popd > /dev/null # Backup dotfiles to git
        ;;
      install|i)
        pushd $DOTFILES > /dev/null
        echo "🔧 Installing dotfiles..."
        ./install.sh
        popd > /dev/null # Run dotfiles install script
        ;;
      update|u)
        pushd $DOTFILES > /dev/null
        echo "🔄 Updating dotfiles dependencies..."
        ./update.sh
        popd > /dev/null # Run dotfiles update script
        ;;
      *)
        echo "Unknown command: $1"
        dot help
        ;;
    esac
  fi
}

# Search environment variables with grep (built-in)
function penvgrep() {
  echo "======== env vars =========="
  if [ -z "$1" ]; then
    printenv | sort | awk -F= '{ printf "%-30s %s\n", $1, $2 }'
  else
    printenv | sort | grep -i "$1" | awk -F= '{ printf "%-30s %s\n", $1, $2 }'
  fi
  echo "============================"
}

# ========================================================================
# System & macOS Utilities
# ========================================================================

# Toggle macOS hidden files
function togglehidden() {
  local current
  current=$(defaults read com.apple.finder AppleShowAllFiles)
  defaults write com.apple.finder AppleShowAllFiles $((!current))
  killall Finder
  log_success "Finder hidden files: $((!current))"
}

# Quick Look from terminal
function ql() {
  qlmanage -p "$@" &>/dev/null
}

# Weather information with optional location
function weather() {
  local city="${1:-}"
  curl -s "wttr.in/$city?format=v2"
}

# Kill process running on a specified port
function killport() {
  local port="$1"
  if [[ -z "$port" ]]; then
    log_error "Please specify a port number"
    return 1
  fi

  local pid
  pid=$(lsof -i ":$port" | awk 'NR!=1 {print $2}')

  if [[ -z "$pid" ]]; then
    log_error "No process found on port $port"
    return 1
  fi

  echo "Killing process(es) on port $port: $pid"
  echo "$pid" | xargs kill -9
  log_success "Process(es) killed"
}

# Show top 10 largest files in current directory
function ducks() {
  du -sh * | sort -rh | head -10
}

# Improved man pages with bat
function batman() {
  MANPAGER="sh -c 'col -bx | bat -l man -p'" man "$@"
}

# ========================================================================
# Yazi File Manager Configuration
# ========================================================================
function y() {
  local tmp cwd
  tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(command cat -- "$tmp")" && [[ -n "$cwd" ]] && [[ "$cwd" != "$PWD" ]]; then
    builtin cd -- "$cwd" || return 1
  fi
  rm -f -- "$tmp"
}

# ========================================================================
# Homebrew Bundle Management
# ========================================================================

# ========================================================================
# Brew Bundle Management
# ========================================================================
function bb() {
  if [[ "$1" == "help" || -z "$1" ]]; then
    echo "Usage: bb [command]"
    echo ""
    echo "Commands:"
    # Extract commands and their descriptions from the function itself
    grep -E '^\s{2}[a-z|]*\)$' "$ZDOTDIR/functions.zsh" | 
      grep -A 1 -B 0 ")" | 
      sed -n '/)/N;s/\s\s\([a-z|]*\))\n\s\s\s\s\(.*\) #\(.*\)/  \1 - \3/p' |
      sort
  else
    case "$1" in
      sudoinstall)
        sudo brew bundle install --verbose --global --all --no-lock --cleanup --force # Install Brewfile bundles with sudo
        ;;
      install)
        brew bundle install --verbose --global --all --cleanup # Install Brewfile bundles
        ;;
      check)
        brew bundle check --verbose --global --all # Check if all dependencies are installed
        ;;
      save)
        brew bundle dump --verbose --global --all --force # Save current packages to Brewfile
        ;;
      unlisted)
        brew bundle cleanup --verbose --global --all --zap # Show packages not in Brewfile
        ;;
      clean)
        brew bundle cleanup --verbose --global --all --zap --force # Remove packages not in Brewfile
        ;;
      edit)
        brew bundle edit --global # Edit global Brewfile
        ;;
      outdated)
        brew bundle outdated --verbose --global # Show outdated packages in Brewfile
        ;;
      upgrade)
        brew upgrade && brew cleanup # Upgrade all packages and cleanup
        ;;
      doctor)
        brew doctor && brew missing # Run brew diagnostics
        ;;
      deps)
        brew deps --tree --installed "$2" # Show dependency tree for a package
        ;;
      leaves)
        brew leaves # List installed formulae that aren't dependencies
        ;;
      *)
        echo "Unknown command: $1"
        bb help
        ;;
    esac
  fi
}
# function bb() {
#   if [[ "$1" == "help" || -z "$1" ]]; then
#     echo "Usage: bb [command]"
#     echo ""
#     echo "Commands:"
#     # Extract commands and their descriptions from the function itself
#     grep -E '^\s{2}[a-z|]*\)$' "$ZDOTDIR/functions.zsh" | 
#       grep -A 1 -B 0 ")" | 
#       sed -n '/)/N;s/\s\s\([a-z|]*\))\n\s\s\s\s\(.*\) #\(.*\)/  \1 - \3/p' |
#       sort
#   else
#     case "$1" in
#       sudoinstall)
#         sudo brew bundle install --verbose --global --all --no-lock --cleanup --force # Install Brewfile bundles with sudo
#         ;;
#       install)
#         brew bundle install --verbose --global --all --cleanup # Install Brewfile bundles
#         ;;
#       check)
#         brew bundle check --verbose --global --all # Check if all dependencies are installed
#         ;;
#       save)
#         brew bundle dump --verbose --global --all --force # Save current packages to Brewfile
#         ;;
#       unlisted)
#         brew bundle cleanup --verbose --global --all --zap # Show packages not in Brewfile
#         ;;
#       clean)
#         brew bundle cleanup --verbose --global --all --zap --force # Remove packages not in Brewfile
#         ;;
#       edit)
#         brew bundle edit --global # Edit global Brewfile
#         ;;
#       outdated)
#         brew bundle outdated --verbose --global # Show outdated packages in Brewfile
#         ;;
#       upgrade)
#         brew upgrade && brew cleanup # Upgrade all packages and cleanup
#         ;;
#       doctor)
#         brew doctor && brew missing # Run brew diagnostics
#         ;;
#       deps)
#         brew deps --tree --installed "$2" # Show dependency tree for a package
#         ;;
#       leaves)
#         brew leaves # List installed formulae that aren't dependencies
#         ;;
#       *)
#         echo "Unknown command: $1"
#         bb help
#         ;;
#     esac
#   fi
# }



function b() {
  case "$1" in
    "up")
      brew update && brew upgrade && brew cleanup --scrub
      ;;
    "in")
      brew install "$2"
      ;;
    "s")
      brew search "$2"
      ;;
    "ini")
      brew install --cask "$2"
      ;;
    # Interactive remove with fzf multi-select
    "rmi")
      local selected
      selected=$(brew list | fzf -m --header="Select packages to remove (use TAB to select multiple)" --preview="brew info {}" --preview-window=:hidden --bind=space:toggle-preview)

      if [[ -n "$selected" ]]; then
        echo "The following packages will be removed:"
        echo "$selected"
        echo ""
        echo "Proceed? (y/n)"
        read -q proceed

        if [[ "$proceed" == "y" ]]; then
          echo "\nRemoving packages..."
          brew remove $selected
          echo "Packages removed successfully."
        else
          echo "\nOperation cancelled."
        fi
      else
        echo "No packages selected."
      fi
      ;;

    # Interactive install with fzf multi-select and Brewfile update
    "insi")
      local selected
      local brewfile="${BREWFILE:-$HOME/Brewfile}"
      selected=$(brew search | fzf -m --header="Select packages to install (use TAB to select multiple)" --preview="brew info {}" --preview-window=:hidden --bind=space:toggle-preview)

      if [[ -n "$selected" ]]; then
        echo "The following packages will be installed and added to $brewfile:"
        echo "$selected"
        echo ""
        echo "Proceed? (y/n)"
        read -q proceed

        if [[ "$proceed" == "y" ]]; then
          echo "\nInstalling packages..."
          brew install $selected

          # Add to Brewfile if it exists or create it
          if [[ ! -f "$brewfile" ]]; then
            touch "$brewfile"
          fi

          # Add each package to Brewfile if not already there
          for pkg in ${(f)selected}; do
            if ! grep -q "^brew \"$pkg\"$" "$brewfile"; then
              echo "brew \"$pkg\"" >> "$brewfile"
              echo "Added $pkg to Brewfile"
            fi
          done

          echo "Packages installed and Brewfile updated."
        else
          echo "\nOperation cancelled."
        fi
      else
        echo "No packages selected."
      fi
      ;;

    # Add more cases as needed
    *)
      echo "Usage: b [command]"
      echo "Commands:"
      echo "  rmi    - Interactive remove brew packages with fzf"
      echo "  insi   - Interactive install brew packages with fzf and update Brewfile"
      ;;
  esac
}


# ========================================================================
# File & Directory Management
# ========================================================================

# ========================================================================
# System & macOS Utilities
# ========================================================================
function sys() {
  case "$1" in
    env | env-grep)
      echo "======== env vars =========="
      if [ -z "$2" ]; then
        printenv | sort | awk -F= '{ printf "%-30s %s\n", $1, $2 }'
      else
        printenv | sort | grep -i "$2" | awk -F= '{ printf "%-30s %s\n", $1, $2 }'
      fi
      echo "============================" # Search environment variables
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
    
    weather | wttr)
      local city="${2:-}"
      curl -s "wttr.in/$city?format=v2" # Get weather information
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
    
    ducks | top-files)
      local count="${2:-10}"
      du -sh * | sort -rh | head -"$count" # Show largest files in directory
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
      echo $PATH | tr ':' '\n' | nl # List PATH entries
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
      echo "  weather [city]     - Show weather information"
      echo "  killport <port>    - Kill process running on specified port"
      echo "  ducks [count]      - Show largest files in current directory"
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

# ========================================================================
# Git Utilities
# ========================================================================

# Lazygit alias
alias lg='lazygit'

# # Custom function to open lazygit in current repo 
# function lgit() {
#   export LAZYGIT_NEW_DIR_FILE=~/.lazygit/newdir
#   lazygit "$@"
  
#   if [ -f $LAZYGIT_NEW_DIR_FILE ]; then
#     cd "$(cat $LAZYGIT_NEW_DIR_FILE)"
#     rm -f $LAZYGIT_NEW_DIR_FILE > /dev/null
#   fi
# }

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

# ========================================================================
# Advanced Search with ripgrep + fzf + nvim
# ========================================================================
function rfv() {
  local RELOAD='reload:rg --column --color=always --smart-case {q} || :'
  local OPENER='if [[ $FZF_SELECT_COUNT -eq 0 ]]; then
                  vim {1} +{2}     # No selection. Open the current line in Vim.
                else
                  vim +cw -q {+f}  # Build quickfix list for the selected items.
                fi'

  fzf --disabled --ansi --multi \
    --bind "start:$RELOAD" --bind "change:$RELOAD" \
    --bind "enter:become:$OPENER" \
    --bind "ctrl-o:execute:$OPENER" \
    --bind 'alt-a:select-all,alt-d:deselect-all,ctrl-/:toggle-preview' \
    --delimiter : \
    --preview 'bat --style=full --color=always --highlight-line {2} {1}' \
    --preview-window '~4,+{2}+4/3,<80(up)' \
    --query "$*"
}


# Keep commonly used aliases for convenience
alias penv='sys env'
alias weather='sys weather'
alias ql='sys ql'
alias batman='sys man'
alias ducks='sys ducks'
