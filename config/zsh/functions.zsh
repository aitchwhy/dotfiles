# Create directory and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1"
}


function symlinks_dead_configs() {
  CONFIGS_DIR="$HOME/.config"
  fd -H -t l . "$CONFIGS_DIR" | while read -r link; do
    if [ ! -e "$(readlink -f "$link")" ]; then
      echo "Found dead symlink @ $link --- removing..."
      unlink $link
    fi
  done
}

# Extract various archive formats
extract() {
    if [ -f $1 ]; then
        case $1 in
            *.tar.bz2)  tar xjf $1   ;;
            *.tar.gz)   tar xzf $1   ;;
            *.bz2)      bunzip2 $1   ;;
            *.rar)      unrar x $1   ;;
            *.gz)       gunzip $1    ;;
            *.tar)      tar xf $1    ;;
            *.tbz2)     tar xjf $1   ;;
            *.tgz)      tar xzf $1   ;;
            *.zip)      unzip $1     ;;
            *.Z)        uncompress $1 ;;
            *.7z)       7z x $1      ;;
            *)          echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Create a new directory and enter it
function take() {
  mkdir -p "$@" && cd "$@"
}

# fzf + zoxide integration
function z() {
  local dir
  dir=$(
    zoxide query --list --score |
    fzf --height 40% --layout reverse --info inline \
        --preview 'tree -C {} | head -200' \
        --preview-window='right:60%:border-left' \
        --bind='ctrl-/:toggle-preview' \
        --border-label='Zoxide Directories' \
        --nth 2.. --tac --query "$*"
  ) && cd "$(echo "$dir" | sed 's/^[0-9,.]* *//')"
}

# ripgrep + fzf + neovim integration
function rgv() {
  local file
  local line

  read -r file line <<<"$(rg --no-heading --line-number "$@" |
    fzf --delimiter : \
        --preview 'bat --style=numbers --color=always --highlight-line {2} {1}' \
        --preview-window='right:60%:border-left+{2}+3/3,~3' \
        --bind='ctrl-/:toggle-preview')"
  
  if [[ -n "$file" ]]; then
    nvim "$file" +"$line"
  fi
}

# Homebrew bundle management
# function brewfile() {
#   case "$1" in
#     save)
#       brew bundle dump --force --describe --file="$HOMEBREW_BUNDLE_FILE"
#       ;;
#     install)
#       brew bundle --file="$HOMEBREW_BUNDLE_FILE"
#       ;;
#     check)
#       brew bundle check --verbose --file="$HOMEBREW_BUNDLE_FILE"
#       ;;
#     clean)
#       brew bundle cleanup --force --file="$HOMEBREW_BUNDLE_FILE"
#       ;;
#     *)
#       echo "Usage: brewfile [save|install|check|clean]"
#       ;;
#   esac
# }

# Docker shortcuts
function dex() {
  docker exec -it "$1" "${2:-bash}"
}

function dlog() {
  docker logs -f "$1"
}

# Git utilities
function gclean() {
  git branch --merged | grep -v '\*\|master\|main\|develop' | xargs -n 1 git branch -d
}

# macOS utilities
function spot() {
  mdfind "kMDItemDisplayName == '$@'wc"
}

# Quick HTTP server
function serve() {
  local port="${1:-8000}"
  python3 -m http.server "$port"
}

# ====== Yazi File Manager Configuration ======
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

# -----------------------------------------------------
# Custom functions (example)
# -----------------------------------------------------



# Custom functions
# symlink
slink() {
    local src_orig=$1
    local dst_link=$2
    local dst_dir=$(dirname "$dst_link")
    mkdir -p "$dst_dir"
    ln -sf "$src_orig" "$dst_link"
}

mkcd () {
 mkdir -p "$1" && cd "$1"
}


# custom functions
# symlink
slink() {
    local src_orig=$1
    local dst_link=$2
    local dst_dir=$(dirname "$dst_link")

    # Create the directory if it does not exist
    mkdir -p "$dst_dir"

    # Create the symlink
    ln -sf "$src_orig" "$dst_link"
}

# fzf + zoxide :  https://junegunn.github.io/fzf/examples/directory-navigation/#zoxidehttpsgithubcomajeetdsouzazoxide
z() {
  local dir=$(
    zoxide query --list --score |
    fzf --height 40% --layout reverse --info inline \
        --nth 2.. --tac --no-sort --query "$*" \
        --bind 'enter:become:echo {2..}'
  ) && cd "$dir"
}

# ripgrep->fzf->nvim [QUERY]
# https://junegunn.github.io/fzf/tips/ripgrep-integration/#8-handle-multiple-selections
rfv() (
  RELOAD='reload:rg --column --color=always --smart-case {q} || :'
  OPENER='if [[ $FZF_SELECT_COUNT -eq 0 ]]; then
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
)

# # https://github.com/junegunn/fzf/issues/2789
# rfv() {
#   # rg
#   # --field-match-separator ' ' - tell rg to separate the filename and linenumber with
#   # spaces to play well with fzf, (when recognizing index variables to use in the fzf
#   # preview command, fzf uses a default delimiter of space, see below)
#
#   # fzf
#   # --preview window ~8,+{1}-5
#   #   this is a fzf feature
#   #   ~8 - show first 8 lines (header)
#   #   +{2} - fzf delimits the input piped in to it and provides access via index variables {n}. 
#   #   the default delimiter fzf uses is space but can be specified via --delimiter <delimiter>
#   #   pass the second index variable from bat (which is the line number)
#   #   the number is signed, you can show eg the +n row or the -n row (the nth row from the bottom)
#   #   -5 subtract 5 rows (go up 5 rows) so that you don't show the highlighted line as the first line
#   #   since you want to provide context by showing the rows above the highlighted line
#
#   rg --line-number --with-filename . --color=always --field-match-separator ' '\
#     | fzf --preview "bat --color=always {1} --highlight-line {2}" \
#     --preview-window ~8,+{2}-5
# }
