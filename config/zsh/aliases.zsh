#!/usr/bin/env bash

source "$HOME/dotfiles/utils.sh"

#########################
# Modern CLI alternatives with fallbacks
#########################

# Alias commands to newer versions IF modern alternatives are installed
# function alias_if_exists() {
#   local orig_cmd="$1"
#   local new_cmd="$2"
#   if [[ ! -z $orig_cmd ]] && [[ command -v $orig_cmd >/dev/null 2>&1 ]]; then
#     alias $orig_cmd=$new_cmd
#     # nvim --headless -c 'autocmd User PackerComplete quitall' -c 'PackerSync'
#   fi
# }

# Directory navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias -- -='cd -'

# Reload shell
alias reload='exec zsh'
alias zs='source ~/.config/zsh/.zshrc'

# System commands
alias flushdns='sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder'
alias paths='echo -e ${PATH//:/\\n}'
alias ports='lsof -i -P -n | grep LISTEN'
alias ip='curl -s ipinfo.io | jq .'


# Utils
alias paths='echo $PATH | tr ":" "\n"'

# tool
alias st='starship'

# Directory shortcuts
alias gdl='cd ~/Downloads'
alias gdoc='cd ~/Documents'
alias gdt='cd ~/Desktop'
alias gdev='cd ~/Development'
alias gdots='cd ~/dotfiles'

# Config shortcuts
alias gcf='cd ~/.config'
alias gdots='cd ~/dotfiles'
alias gvi='cd ~/.config/nvim'
alias gz='cd ~/.config/zsh'
alias ghs='cd ~/.hammerspoon'
alias glib='cd ~/Library'
alias gapps='cd ~/Library/Application Support'
alias gcloud='cd ~/Library/CloudStorage'

# Cloud storage
alias gicloud='cd ~/Library/CloudStorage/iCloud~com~apple~CloudDocs'
alias gdbx='cd ~/Library/CloudStorage/Dropbox'

# Zsh configuration shortcuts
alias ze='nvim $ZDOTDIR/.zshrc'
alias zp='nvim $ZDOTDIR/.zprofile'
alias zr='exec zsh'
alias zc='rm -f ~/.zcompdump; compinit && exec zsh'

# Git shortcuts
alias gs='git status'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit'
alias gca='git commit --amend'
alias gco='git checkout'
alias gd='git diff'
alias glog='git log --oneline --decorate --graph'
alias gp='git push'
alias gll='git pull'
alias gb='git branch'
alias gst='git status -sb'
alias gpf='git push --force-with-lease'
alias gt='git tag'
alias gtd='git tag --delete'
alias gtdr='git tag --delete origin'
# alias grb='git rebase'
# alias grs='git restore'
# alias gsw='git switch'

has_command bat && alias cat='bat --paging=never'
has_command delta && alias diff='delta'
has_command duf && alias df='duf'
has_command duf && alias du='dust'
has_command fd && alias find='fd'
has_command gping && alias ping='gping'
has_command htop && alias top='htop'
has_command nvim && alias lg='lazygit'
has_command nvim && alias vi='nvim' && alias vim='nvim'
has_command procs && alias ps='procs'
has_command rg && alias grep='rg'
has_command yazi && alias ranger='yazi'
has_command sd && alias sed='sd'
has_command mlr && alias miller='mlr'


# File listing with eza
if has_command eza; then
  # Basic listings
  alias ls='eza --icons --group-directories-first'
  alias l='eza --long -bF' # Extended details with binary sizes and type indicators
  alias ll='eza -l --icons --group-directories-first'
  alias la='eza -la --icons --group-directories-first' # Show all files, with directories listed first
  alias ld='eza --only-dirs'
  alias lf='eza --only-files' # List only files
  alias ld='eza --only-dirs' # List only directories

  # Specialized listings
  alias lt='eza --tree --icons'
  alias lm='eza -l --sort=modified'
  alias lsize='eza -l --sort=size'
  alias ltype='eza -l --sort=extension'
  alias lmod='eza --long --modified --sort=modified' # Sort by modification date in long format, using the modified timestamp

  # Advanced options
  alias ldepth2='eza --level=2'
  alias lignore='eza --git-ignore'
  # alias lcontext='eza --long --context'
  alias lcontext='eza --long --context' # Show security context
  # alias llm='eza --long -a --sort=modified' # Long format, including hidden files, sorted by modification date
  alias lr='eza --recurse --all' # Recursively list all files, including hidden ones
  #
  # # Advanced filtering and display options
  alias ltype='eza --long --sort=type' # Sort by file type in long format
  alias lignore='eza --git-ignore' # Ignore files mentioned in .gitignore
  alias lh='eza --hyperlink --all' # Display all entries as hyperlinks
  alias lC='eza --color-scale=size --long' # Use color scale based on file size
fi


# Homebrew shortcuts
alias b='brew'
alias bi='brew info'
alias bin='brew install'
alias bcin='brew install --cask'
alias bs='brew search --eval-all --desc'
alias bup='brew update && brew upgrade && brew cleanup --prune=all'
alias bclean='brew cleanup --prune=all && brew autoremove'
alias bdeps='brew deps --tree --installed'

# Homebrew Bundle
alias bb='brew bundle'
alias bbe='brew bundle edit --global --all'
alias bbcheck='brew bundle check --global --all'
alias bbdump='brew bundle dump --global --all'
alias bbdumpf='brew bundle dump --global --all --force'

# Task management
alias td='todoist'
alias tda='todoist add'
alias tdl='todoist list'
alias tdt='todoist today'


# Development tools
# Python
alias py='python'
alias pip='uv pip'
alias pip3='uv pip3'

# Node.js
alias nr='npm run'
alias ni='npm install'
alias nid='npm install --save-dev'
alias nrs='npm run start'
alias nrb='npm run build'
alias nrt='npm run test'

# Docker
alias d='docker'
alias dc='docker compose'
alias dps='docker ps'
alias dex='docker exec -it'
alias dprune='docker system prune -a'

# Kubernetes
alias k='kubectl'
alias kns='kubectl config set-context --current --namespace'
alias kctx='kubectl config use-context'
alias kg='kubectl get'
alias kd='kubectl describe'
alias kl='kubectl logs'
alias ke='kubectl exec -it'

# Terminal multiplexer (Zellij)
alias zj='zellij'
alias zja='zellij attach'
alias zjls='zellij list-sessions'
