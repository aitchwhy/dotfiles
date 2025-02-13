
# default command for fzf
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git --exclude node_modules --exclude target'
# export FZF_DEFAULT_COMMAND='rg --files --no-ignore-vcs --hidden'

# Default options
export FZF_DEFAULT_OPTS="
  --height 80% 
  --layout=reverse 
  --border sharp
  --preview 'bat --style=numbers,changes --color=always --line-range :500 {}' 
  --preview-window='right:60%:border-left'
  --bind='ctrl-/:toggle-preview'
  --bind='ctrl-y:execute-silent(echo {} | pbcopy)'
  --bind='ctrl-e:execute(nvim {} < /dev/tty > /dev/tty)'
  --bind='ctrl-f:preview-page-down'
  --bind='ctrl-b:preview-page-up'
  --color=fg:#c0caf5,bg:#1a1b26,hl:#bb9af7
  --color=fg+:#c0caf5,bg+:#292e42,hl+:#7dcfff
  --color=info:#7aa2f7,prompt:#7dcfff,pointer:#7dcfff
  --color=marker:#9ece6a,spinner:#9ece6a,header:#9ece6a
"

#############
# History search (CTRL-R) + atuin
# Paste the selected command from history onto the command-line
#
# If you want to see the commands in chronological order, press CTRL-R again which toggles sorting by relevance
# Press CTRL-/ to toggle line wrapping and see the whole command
#
# Set FZF_CTRL_R_OPTS to pass additional options to fzf
# CTRL-Y to copy the command into clipboard using pbcopy
#############

# History search (CTRL-R) - Integrated with Atuin
export FZF_CTRL_R_OPTS="
  --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'
  --color header:italic
  --header 'CTRL-Y: Copy | CTRL-R: Toggle sort'
  --border-label='Command History'"

#############
# Dir+File search (CTRL-T)
# Preview file content using bat (https://github.com/sharkdp/bat)
#
# Paste the selected files and directories onto the command-line
#
# The list is generated using --walker file,dir,follow,hidden option
# You can override the behavior by setting FZF_CTRL_T_COMMAND to a custom command that generates the desired list
# Or you can set --walker* options in FZF_CTRL_T_OPTS
# Set FZF_CTRL_T_OPTS to pass additional options to fzf
#############
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="
  --walker-skip .git,node_modules,target,.cache
  --preview 'bat -n --color=always {}'
  --bind 'ctrl-/:change-preview-window(down|hidden|)'
  --border-label='Files'"

#############
# Directory navigation (ALT-C) (cd into the selected directory)
#
# The list is generated using --walker dir,follow,hidden option
# Set FZF_ALT_C_COMMAND to override the default command
# Or you can set --walker-* options in FZF_ALT_C_OPTS
# Set FZF_ALT_C_OPTS to pass additional options to fzf
#
# Print tree structure in the preview window
#############
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git --exclude node_modules --exclude target'
export FZF_ALT_C_OPTS="
  --walker-skip .git,node_modules,target,.cache
  --preview 'tree -C {} | head -200'
  --border-label='Directories'"

# Load fzf keybindings
# source "$(brew --prefix)/opt/fzf/shell/key-bindings.zsh"


####################################
# Utils
####################################
####################################

# ~/.config/zsh/functions/fzf-utils.zsh
# Dependencies: fzf, ripgrep (rg), git (optional), docker (optional), brew (optional)

# Chrome bookmark search
function chrome-bookmark-browser() {
  local bookmarks_path
  case "$(uname)" in
    "Darwin")
      bookmarks_path="$HOME/Library/Application Support/Google/Chrome/Default/Bookmarks"
      ;;
    "Linux")
      bookmarks_path="$HOME/.config/google-chrome/Default/Bookmarks"
      ;;
  esac
  
  if [[ ! -f "$bookmarks_path" ]]; then
    echo "Chrome Bookmarks file not found"
    return 1
  fi

  local jq_script='
    def ancestors: while(. | length >= 2; del(.[-1,-2]));
    . as $root | paths(try .url catch false) as $path | $path | . as $p |
    $root | getpath($p) | {name,url, path: [$p[0:-2] | ancestors as $a | $root | getpath($a) | .name?] | reverse | join("/") } | .path + "/" + .name + "\t" + .url
  '

  local bookmark_url=$(jq -r "$jq_script" < "$bookmarks_path" | \
    sed -E 's/\t/│/g' | \
    fzf --delimiter='│' --with-nth=1 --preview-window=hidden | \
    cut -d'│' -f2)

  if [[ -n "$bookmark_url" ]]; then
    open "$bookmark_url"
  fi
}

# Docker container management functions
function d-attach() {
  local container=$(docker ps | sed 1d | fzf -q "$1" | awk '{print $1}')
  if [[ -n "$container" ]]; then
    docker attach "$container"
  fi
}

function d-stop-container() {
  local container=$(docker ps | sed 1d | fzf -q "$1" | awk '{print $1}')
  if [[ -n "$container" ]]; then
    docker stop "$container"
  fi
}

function d-rm() {
  local container=$(docker ps -a | sed 1d | fzf -q "$1" | awk '{print $1}')
  if [[ -n "$container" ]]; then
    docker rm "$container"
  fi
}

function d-image-rm() {
  local image=$(docker images | sed 1d | fzf -q "$1" | awk '{print $3}')
  if [[ -n "$image" ]]; then
    docker rmi "$image"
  fi
}

# File search and edit functions
function fif() {
  if [ ! "$#" -gt 0 ]; then
    echo "Need a string to search for!"
    return 1
  fi
  rg --files-with-matches --no-messages "$1" | fzf --preview "highlight -O ansi -l {} 2> /dev/null | rg --colors 'match:bg:yellow' --ignore-case --pretty --context 10 '$1' || rg --ignore-case --pretty --context 10 '$1' {}"
}

function fzf-find-edit() {
  local file=$(fzf --preview 'bat --style=numbers --color=always --line-range :500 {}')
  if [[ -n "$file" ]]; then
    $EDITOR "$file"
  fi
}

function fzf-grep-edit() {
  if [[ $# == 0 ]]; then
    echo 'Error: search term was not provided.'
    return 1
  fi
  local match=$(rg --color=never --line-number "$1" | fzf --delimiter : \
    --preview "bat --style=numbers --color=always --highlight-line {2} {1}" \
    --preview-window=up,60%)
  if [[ -n "$match" ]]; then
    local file=$(echo "$match" | cut -d: -f1)
    $EDITOR "$file" +$(echo "$match" | cut -d: -f2)
  fi
}

# Git utilities
function fzf-git-branch() {
  git rev-parse HEAD > /dev/null 2>&1 || return

  local branch=$(git branch --color=always | \
    grep -v '/HEAD\s' | \
    fzf --height 40% --ansi --preview-window right:70% \
    --preview 'git log --oneline --graph --date=short --color=always --pretty="format:%C(auto)%cd %h%d %s" $(sed s/^..// <<< {} | cut -d" " -f1)' | \
    sed 's/^..//' | cut -d' ' -f1)

  if [[ -n "$branch" ]]; then
    echo "$branch"
  fi
}

function fzf-git-checkout() {
  local branch=$(fzf-git-branch)
  if [[ -n "$branch" ]]; then
    git checkout "$branch"
  fi
}

# Process management
function fzf-kill() {
  local pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')
  if [[ -n "$pid" ]]; then
    echo "$pid" | xargs kill -"${1:-9}"
  fi
}

# VSCode integration
function fzf-vscode() {
  local file=$(rg --files | fzf --preview 'bat --style=numbers --color=always --line-range :500 {}')
  if [[ -n "$file" ]]; then
    code "$file"
  fi
}

# Homebrew functions
function fzf-brew-install() {
  local inst=$(brew search | fzf -m)
  if [[ -n "$inst" ]]; then
    for prog in $(echo "$inst"); do
      brew install "$prog"
    done
  fi
}

function fzf-brew-uninstall() {
  local inst=$(brew list | fzf -m)
  if [[ -n "$inst" ]]; then
    for prog in $(echo "$inst"); do
      brew uninstall "$prog"
    done
  fi
}

# Tmux integration
function tm() {
  [[ -n "$TMUX" ]] && change="switch-client" || change="attach-session"
  if [ "$1" ]; then
    tmux $change -t "$1" 2>/dev/null || (tmux new-session -d -s "$1" && tmux $change -t "$1")
    return
  fi
  
  local session=$(tmux list-sessions -F "#{session_name}" 2>/dev/null | fzf --exit-0) && \
    tmux $change -t "$session" || tmux
}

function tmux-kill() {
  local session=$(tmux list-sessions -F "#{session_name}" | \
    fzf --exit-0) && tmux kill-session -t "$session"
}
