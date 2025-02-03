# Smart directory creation
mkcd() { mkdir -p "$1" && cd "$1" }

# Quick config editing
conf() {
  local configs=(
    ~/.config/zsh/.zshrc
    ~/.config/nvim/init.lua
    ~/.config/git/config
  )
  nvim $configs
}

# Enhanced file search with preview
fzp() {
  rg --files --hidden --follow --glob '!{.git,node_modules}/**' | \
  fzf --preview 'bat --color=always --style=numbers --line-range=:500 {}'
}

# Smart branch checkout
gco() {
  local branches branch
  branches=$(git branch -a --sort=-committerdate | grep -v HEAD) &&
  branch=$(echo "$branches" | fzf --height 40% --reverse) &&
  git checkout $(echo "$branch" | sed "s:.* remotes/origin/::" | sed "s:.* ::")
}

# Universal package installer
up() {
  case $1 in
    brew*) brew install ${@:2} ;;
    npm*) npm install ${@:2} ;;
    pip*) pip3 install ${@:2} ;;
    cargo*) cargo install ${@:2} ;;
    *) echo "Unknown package manager" ;;
  esac
}

# Project workspace initializer
init-workspace() {
  local dir=${1:-.}
  mkcd $dir && \
  git init && \
  nvim README.md && \
  zellij
}