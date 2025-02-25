# ~/.dotfiles/config/zsh/functions.zsh
# Useful ZSH functions

# Create and enter directory
mkcd() {
  mkdir -p "$1" && cd "$1"
}

# Extract archives
extract() {
  if [ -f "$1" ]; then
    case "$1" in
      *.tar.bz2) tar xjf "$1" ;;
      *.tar.gz) tar xzf "$1" ;;
      *.bz2) bunzip2 "$1" ;;
      *.rar) unrar x "$1" ;;
      *.gz) gunzip "$1" ;;
      *.tar) tar xf "$1" ;;
      *.tbz2) tar xjf "$1" ;;
      *.tgz) tar xzf "$1" ;;
      *.zip) unzip "$1" ;;
      *.Z) uncompress "$1" ;;
      *.7z) 7z x "$1" ;;
      *) echo "'$1' cannot be extracted" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

# Git functions enhanced with fzf

# Git checkout with fzf
fco() {
  local branches branch
  branches=$(git branch --all | grep -v HEAD) &&
  branch=$(echo "$branches" |
           fzf-tmux -d 15 --no-multi) &&
  git checkout $(echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")
}

# Git add with fzf
fga() {
  local files
  files=$(git -c color.status=always status --short |
          fzf --ansi --multi --preview 'git diff --color=always {2}' |
          cut -c4- |
          sed 's/.* -> //')
  if [[ -n "$files" ]]; then
    git add ${files}
    git status --short
  fi
}

# Kill process with fzf
fkill() {
  local pid
  pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')
  
  if [[ -n "$pid" ]]; then
    echo $pid | xargs kill -${1:-9}
  fi
}

# Find directory and cd to it
fd() {
  local dir
  dir=$(find ${1:-.} -path '*/\.*' -prune -o -type d -print 2> /dev/null | fzf +m) &&
  cd "$dir"
}

# Find file and open in editor
fe() {
  local file
  file=$(find ${1:-.} -type f -not -path "*/node_modules/*" -not -path "*/\.git/*" -not -path "*/.venv/*" 2> /dev/null | fzf +m) &&
  ${EDITOR:-vim} "$file"
}

# Process management - find and kill a process
pskill() {
  local pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')
  
  if [ "x$pid" != "x" ]; then
    echo $pid | xargs kill -${1:-9}
  fi
}

# Kill process running on a specified port
killport() {
  local port="$1"
  lsof -i ":$port" | awk 'NR!=1 {print $2}' | xargs kill -9
}

# Find string in current directory
search() {
  rg --color=always --line-number --no-heading --smart-case "${*:-}" |
    fzf --ansi \
        --color "hl:-1:underline,hl+:-1:underline:reverse" \
        --delimiter : \
        --preview 'bat --style=numbers --color=always --highlight-line {2} {1}' \
        --preview-window 'up,60%,border-bottom,+{2}+3/3,~3'
}

# Improved man pages with bat
batman() {
  batman() {
    MANPAGER="sh -c 'col -bx | bat -l man -p'" man "$@"
  }
}

# Open man pages with fzf
fman() {
  man -k . | fzf --prompt='Man> ' | awk '{print $1}' | xargs -r man
}

# Directory bookmarks
bookmark() {
  local mark_dir="$XDG_DATA_HOME/marks"
  mkdir -p "$mark_dir"
  ln -sf "$(pwd)" "$mark_dir/$1"
}

jump() {
  local mark_dir="$XDG_DATA_HOME/marks"
  local mark="$1"
  
  if [[ -L "$mark_dir/$mark" ]]; then
    cd "$(readlink "$mark_dir/$mark")"
  else
    echo "No such mark: $mark"
    return 1
  fi
}

# marks() {
#   local mark_dir="$XDG_DATA_HOME/marks"
#   ls -l "$mark_dir" | sed 's/  / /g' | cut -d' ' -f9- | sed 's/ -/\t-/g'
# }
#
# # Weather information
# weather() {
#   local city="${1:-}"
#   curl -s "wttr.in/$city?format=v2"
# }

# Quick HTTP server
serve() {
  local port="${1:-8000}"
  local ip=$(ipconfig getifaddr en0)
  python3 -m http.server "$port" --bind "$ip"
  echo "Server running at http://$ip:$port/"
}

# Git utilities
gcb() {
  # Clean merged branches
  local branches_to_delete=$(git branch --merged | grep -v "^\*" | grep -v "master\|main")
  if [[ -n "$branches_to_delete" ]]; then
    echo "The following branches will be deleted:"
    echo "$branches_to_delete"
    read -q "REPLY?Are you sure you want to delete these branches? [y/N] "
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      git branch --merged | grep -v "^\*" | grep -v "master\|main" | xargs git branch -d
      echo "Branches deleted successfully!"
    else
      echo "Operation canceled."
    fi
  else
    echo "No merged branches to delete."
  fi
}

# # Show top 10 largest files in current directory
# ducks() {
#   du -sh * | sort -rh | head -10
# }

# Enhanced tree command with eza/exa if available
lstree() {
  if [[ -n "$(command -v eza)" ]]; then
    eza --tree --level="${1:-2}" --icons
  elif [[ -n "$(command -v exa)" ]]; then
    exa --tree --level="${1:-2}" --icons
  else
    find . -type d -not -path "*/\.*" -not -path "*/node_modules/*" -maxdepth "${1:-2}" | sort | sed -e 's/[^-][^\/]*\//  |/g' -e 's/|\([^ ]\)/|-\1/'
  fi
}

# Enhanced cd with ls
# function cd() {
#     builtin cd "$@" && eza --icons --group-directories-first
# }

# # Extract archives
# extract() {
#     if [ -f "$1" ]; then
#         case "$1" in
#         *.tar.bz2) tar xjf "$1" ;;
#         *.tar.gz) tar xzf "$1" ;;
#         *.bz2) bunzip2 "$1" ;;
#         *.rar) unrar x "$1" ;;
#         *.gz) gunzip "$1" ;;
#         *.tar) tar xf "$1" ;;
#         *.tbz2) tar xjf "$1" ;;
#         *.tgz) tar xzf "$1" ;;
#         *.zip) unzip "$1" ;;
#         *.Z) uncompress "$1" ;;
#         *.7z) 7z x "$1" ;;
#         *) echo "'$1' cannot be extracted" ;;
#         esac
#     else
#         echo "'$1' is not a valid file"
#     fi
# }

# Git utilities

# Unalias conflicting names (e.g. 'gco') before defining functions
# unalias gco 2>/dev/null

# Enhanced git checkout
# gco() {
#     if [ $# -eq 0 ]; then
#         git branch | fzf | xargs git checkout
#     else
#         git checkout "$@"
#     fi
# }

# Git add with fzf
# unalias ga 2>/dev/null
# ga() {
#     if [ $# -eq 0 ]; then
#         git status -s | fzf --multi | awk '{print $2}' | xargs git add
#     else
#         git add "$@"
#     fi
# }

# # Clean merged branches
# # unalias gclean 2>/dev/null
# gclean() {
#     git branch --merged | grep -v '\*\|master\|main\|develop' | xargs -n 1 git branch -d
# }

# Docker utilities
# Docker exec with container selection
# unalias dex 2>/dev/null
# dex() {
#     local cid
#     cid=$(docker ps | sed 1d | fzf -q "$1" | awk '{print $1}')
#     [ -n "$cid" ] && docker exec -it "$cid" "${2:-bash}"
# }

# Docker container logs
# unalias dlog 2>/dev/null
# dlog() {
#     local cid
#     cid=$(docker ps | sed 1d | fzf -q "$1" | awk '{print $1}')
#     [ -n "$cid" ] && docker logs -f "$cid"
# }

# System utilities
# Find large files
# bigfiles() {
#     local size="${1:-500M}"
#     fd --type f --size "+${size}" . "${2:-.}"
# }

# # Process management
# killport() {
#     local port="$1"
#     lsof -i ":$port" | awk 'NR!=1 {print $2}' | xargs kill
# }
#
# # Directory utilities
# # Directory bookmarks
# bm() {
#     local mark_dir="$XDG_DATA_HOME/marks"
#     mkdir -p "$mark_dir"
#     ln -s "$(pwd)" "$mark_dir/$1"
# }

# jump() {
#     local mark_dir="$XDG_DATA_HOME/marks"
#     cd -P "$mark_dir/$1" 2>/dev/null || echo "No such mark: $1"
# }
#
# marks() {
#     local mark_dir="$XDG_DATA_HOME/marks"
#     ls -l "$mark_dir" | sed 's/  / /g' | cut -d' ' -f9- | sed 's/ -/\t-/g'
# }

# # # Enhanced tree command with eza
# lstree() {
#     eza --tree --level="${1:-2}" --icons
# }
#
# # Weather information
# weather() {
#     local city="${1:-}"
#     curl -s "wttr.in/$city?format=v2"
# }
#
# # Quick HTTP server
# serve() {
#     local port="${1:-8000}"
#     python3 -m http.server "$port"
# }
#
# # macOS specific
# # Show/hide hidden files
# togglehidden() {
#     local current=$(defaults read com.apple.finder AppleShowAllFiles)
#     defaults write com.apple.finder AppleShowAllFiles $((!current))
#     killall Finder
# }
# #
# # # Quick Look from terminal
# ql() {
#     qlmanage -p "$@" &>/dev/null
# }

# Additional utilities will be added as needed...
#
# ###############################
# # fzf examples -> https://github.com/junegunn/fzf/wiki/examples#homebrew
# ###############################
#
#
#
#
# # Extract various archive formats
# extract() {
#     if [ -f $1 ]; then
#         case $1 in
#             *.tar.bz2)  tar xjf $1   ;;
#             *.tar.gz)   tar xzf $1   ;;
#             *.bz2)      bunzip2 $1   ;;
#             *.rar)      unrar x $1   ;;
#             *.gz)       gunzip $1    ;;
#             *.tar)      tar xf $1    ;;
#             *.tbz2)     tar xjf $1   ;;
#             *.tgz)      tar xzf $1   ;;
#             *.zip)      unzip $1     ;;
#             *.Z)        uncompress $1 ;;
#             *.7z)       7z x $1      ;;
#             *)          echo "'$1' cannot be extracted via extract()" ;;
#         esac
#     else
#         echo "'$1' is not a valid file"
#     fi
# }
#
# # Create a new directory and enter it
# function take() {
#   mkdir -p "$@" && cd "$@"
# }
#
# # fzf + zoxide integration
# function z() {
#   local dir
#   dir=$(
#     zoxide query --list --score |
#     fzf --height 40% --layout reverse --info inline \
#         --preview 'tree -C {} | head -200' \
#         --preview-window='right:60%:border-left' \
#         --bind='ctrl-/:toggle-preview' \
#         --border-label='Zoxide Directories' \
#         --nth 2.. --tac --query "$*"
#   ) && cd "$(echo "$dir" | sed 's/^[0-9,.]* *//')"
# }
#
# # ripgrep + fzf + neovim integration
# function rgv() {
#   local file
#   local line
#
#   read -r file line <<<"$(rg --no-heading --line-number "$@" |
#     fzf --delimiter : \
#         --preview 'bat --style=numbers --color=always --highlight-line {2} {1}' \
#         --preview-window='right:60%:border-left+{2}+3/3,~3' \
#         --bind='ctrl-/:toggle-preview')"
#
#   if [[ -n "$file" ]]; then
#     nvim "$file" +"$line"
#   fi
# }
#
# # Homebrew bundle management
# # function brewfile() {
# #   case "$1" in
# #     save)
# #       brew bundle dump --force --describe --file="$HOMEBREW_BUNDLE_FILE"
# #       ;;
# #     install)
# #       brew bundle --file="$HOMEBREW_BUNDLE_FILE"
# #       ;;
# #     check)
# #       brew bundle check --verbose --file="$HOMEBREW_BUNDLE_FILE"
# #       ;;
# #     clean)
# #       brew bundle cleanup --force --file="$HOMEBREW_BUNDLE_FILE"
# #       ;;
# #     *)
# #       echo "Usage: brewfile [save|install|check|clean]"
# #       ;;
# #   esac
# # }
#
# # Docker shortcuts
# function dex() {
#   docker exec -it "$1" "${2:-bash}"
# }
#
# function dlog() {
#   docker logs -f "$1"
# }
#
# # Git utilities
# function gclean() {
#   git branch --merged | grep -v '\*\|master\|main\|develop' | xargs -n 1 git branch -d
# }
#
# # macOS utilities
# function spot() {
#   mdfind "kMDItemDisplayName == '$@'wc"
# }
#
# # Quick HTTP server
# function serve() {
#   local port="${1:-8000}"
#   python3 -m http.server "$port"
# }
#
# # ====== Yazi File Manager Configuration ======
# function y() {
# 	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
# 	yazi "$@" --cwd-file="$tmp"
# 	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
# 		builtin cd -- "$cwd"
# 	fi
# 	rm -f -- "$tmp"
# }
#
# # -----------------------------------------------------
# # Custom functions (example)
# # -----------------------------------------------------
#
#
#
# # Custom functions
# # symlink
# slink() {
#     local src_orig=$1
#     local dst_link=$2
#     local dst_dir=$(dirname "$dst_link")
#     mkdir -p "$dst_dir"
#     ln -sf "$src_orig" "$dst_link"
# }
#
# mkcd () {
#  mkdir -p "$1" && cd "$1"
# }
#
#
# # custom functions
# # symlink
# slink() {
#     local src_orig=$1
#     local dst_link=$2
#     local dst_dir=$(dirname "$dst_link")
#
#     # Create the directory if it does not exist
#     mkdir -p "$dst_dir"
#
#     # Create the symlink
#     ln -sf "$src_orig" "$dst_link"
# }
#
# # fzf + zoxide :  https://junegunn.github.io/fzf/examples/directory-navigation/#zoxidehttpsgithubcomajeetdsouzazoxide
# z() {
#   local dir=$(
#     zoxide query --list --score |
#     fzf --height 40% --layout reverse --info inline \
#         --nth 2.. --tac --no-sort --query "$*" \
#         --bind 'enter:become:echo {2..}'
#   ) && cd "$dir"
# }
#
# # ripgrep->fzf->nvim [QUERY]
# # https://junegunn.github.io/fzf/tips/ripgrep-integration/#8-handle-multiple-selections
# rfv() (
#   RELOAD='reload:rg --column --color=always --smart-case {q} || :'
#   OPENER='if [[ $FZF_SELECT_COUNT -eq 0 ]]; then
#             vim {1} +{2}     # No selection. Open the current line in Vim.
#           else
#             vim +cw -q {+f}  # Build quickfix list for the selected items.
#           fi'
#   fzf --disabled --ansi --multi \
#       --bind "start:$RELOAD" --bind "change:$RELOAD" \
#       --bind "enter:become:$OPENER" \
#       --bind "ctrl-o:execute:$OPENER" \
#       --bind 'alt-a:select-all,alt-d:deselect-all,ctrl-/:toggle-preview' \
#       --delimiter : \
#       --preview 'bat --style=full --color=always --highlight-line {2} {1}' \
#       --preview-window '~4,+{2}+4/3,<80(up)' \
#       --query "$*"
# )
#
# # # https://github.com/junegunn/fzf/issues/2789
# # rfv() {
# #   # rg
# #   # --field-match-separator ' ' - tell rg to separate the filename and linenumber with
# #   # spaces to play well with fzf, (when recognizing index variables to use in the fzf
# #   # preview command, fzf uses a default delimiter of space, see below)
# #
# #   # fzf
# #   # --preview window ~8,+{1}-5
# #   #   this is a fzf feature
# #   #   ~8 - show first 8 lines (header)
# #   #   +{2} - fzf delimits the input piped in to it and provides access via index variables {n}.
# #   #   the default delimiter fzf uses is space but can be specified via --delimiter <delimiter>
# #   #   pass the second index variable from bat (which is the line number)
# #   #   the number is signed, you can show eg the +n row or the -n row (the nth row from the bottom)
# #   #   -5 subtract 5 rows (go up 5 rows) so that you don't show the highlighted line as the first line
# #   #   since you want to provide context by showing the rows above the highlighted line
# #
# #   rg --line-number --with-filename . --color=always --field-match-separator ' '\
# #     | fzf --preview "bat --color=always {1} --highlight-line {2}" \
# #     --preview-window ~8,+{2}-5
# # }
