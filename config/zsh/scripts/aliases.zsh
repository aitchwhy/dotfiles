#!/usr/bin/env zsh

DOTFILES="${DOTFILES:-$HOME/dotfiles}"
export dot="${dot:-$DOTFILES}"
export cf="${cf:-$DOTFILES/config}"
export cfzsh="${cfzsh:-$cf/zsh}"

####################################
# justfile
####################################

export USER_JUSTFILE="$cf/just/.user.justfile"

alias j="just"
alias jfmt="just --unstable --fmt"

alias .j='just --justfile $USER_JUSTFILE --working-directory .'

# a recipe called foo in ~/.user.justfile --> (.j foo)
alias .j='just --justfile $USER_JUSTFILE --working-directory .'
alias .jfmt='just --justfile $USER_JUSTFILE --working-directory . --unstable --fmt'

# # run recipe directly without ".j"
# for recipe in `just --justfile ~/.user.justfile --summary`; do
#   alias $recipe="just --justfile $USER_JUSTFILE --working-directory . $recipe"
# done

####################################
# Nix
####################################

alias nixh='nix --help'

alias nixflake="$EDITOR $DOTFILES/flake.nix"
alias nixconf="$EDITOR $cf/nix/nix.conf"

# nix garbage collection
alias nixgc="nix-collect-garbage -d"

# nix package management
alias nixpkgs="nix search"
# alias nixpin="nix profile install"
# alias nixpls="nix profile list"
# alias nixprm="nix profile remove"

# nix development
alias nixsh="nix-shell --run zsh"
alias nixdev="nix develop"
alias nixdevzsh="nix develop --command zsh"
alias nixfk="nix flake"

# nix system
alias nixup="sudo nixos-rebuild switch"
alias nixdarwinup="darwin-rebuild switch --flake ~/dotfiles"

# Aliases
alias v='$EDITOR'
alias vi='$EDITOR'
alias vim='$EDITOR'

# Dotfiles Management
# alias zdot='cd $ZDOTDIR'
alias zr="exec zsh"
alias ce="nvim '$ZDOTDIR'/{.zshrc,.zprofile,.zshenv}"
alias c="cursor $cf"
alias ze="nvim '$ZDOTDIR'/{.zshrc,.zprofile,.zshenv,*.zsh} ~/.zshenv "

alias e="cursor $DOTFILES"

# FZF enhanced file selection and navigation
function f() {
  local cmd result

  case "$1" in
  find | file)
    # Find files
    result=$(fd --type f --follow --hidden --exclude .git | fzf --preview="bat --color=always {}")
    echo "$result"
    ;;
  edit)
    # Find and edit file
    result=$(fd --type f --follow --hidden --exclude .git | fzf --preview="bat --color=always {}")
    [[ -n "$result" ]] && "$EDITOR" "$result"
    ;;
  dir)
    # Find directories
    result=$(fd --type d --follow --hidden --exclude .git | fzf --preview="eza --tree --level=1 --color=always {}")
    echo "$result"
    ;;
  z)
    # Jump with zoxide
    result=$(zoxide query -l | fzf --preview="eza --tree --level=1 --color=always {}")
    [[ -n "$result" ]] && cd "$result"
    ;;
  *)
    echo "Usage: f [find|edit|dir|z]"
    return 1
    ;;
  esac
}

####################################

alias cheat="tldr"
alias ch="cheat"

# === Core Tool Aliases ===
alias claude="/Users/hank/.claude/local/claude"

# List Files - Prioritize eza with fallback to ls
if (($ + commands[eza])); then
  alias ls="eza --icons --group-directories-first"
  alias ll="eza --icons --group-directories-first -la"
  alias la="eza --icons --group-directories-first -a"
  alias lt="eza --icons --group-directories-first --tree"
  alias lt2="eza --icons --group-directories-first --tree --level=2"
  alias lt3="eza --icons --group-directories-first --tree --level=3"
else
  alias ls="ls -G"
  alias ll="ls -la"
  alias la="ls -a"
fi

# Networking Utilities
alias ip="ipconfig getifaddr en0"
alias localip="ipconfig getifaddr en0"
alias publicip="curl -s https://api.ipify.org"
alias ports="sudo lsof -i -P -n | grep LISTEN"
alias flush="dscacheutil -flushcache && killall -HUP mDNSResponder" # Flush DNS

# System Information
alias ppath='echo $PATH | tr ":" "\n"'
alias printfuncs='print -l ${(k)functions[(I)[^_]*]} | sort'
alias printfpath='for fp in $fpath; do echo $fp; done; unset fp'
alias printpath='ppath'

# Example: flush DNS
alias flushdns="sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder"
alias showhidden="defaults write com.apple.finder AppleShowAllFiles YES; killall Finder"

# Package management
alias bup='brew update && brew upgrade && brew cleanup'
alias brewup='bup'

# upgrade to modern
alias ps='procs'
alias ping='gping'
alias diff='delta'

# FZF enhanced commands
alias flog='fzf --preview "bat --style=numbers --color=always --line-range=:500 {}"'
alias falias='alias | fzf'
alias fman='man -k . | fzf --preview "man {}"'
alias fls='man -k . | fzf --preview "man {}"'
alias ls='eza -al' # Note: Overwrites previous ls alias
# alias cheat='navi'
# alias tldr='navi'
alias net='trippy'
alias netviz='netop'
alias jwt='jet-ui'
alias sed='sd'
alias du='dust'
# alias ssh='sshs'
# alias s3='stu'
# alias http='xh'
# alias http='posting'
alias csv='xsv'
# alias rm='rip'
alias jsonfilter='jnv'
alias jsonviewer='jnv'
# k8s kubernetes + docker + containers
alias d='docker' # Note: Overwrites previous d alias
alias dstart='docker start'
alias dstop='docker stop'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias dimg='docker images'
alias dx='docker exec -it'
alias drm='docker rm'
alias drmi='docker rmi'
alias dbuild='docker build'
alias dc='docker-compose'
alias k='k9s'
# Modern CLI alternatives
alias cat='bat --paging=never'   # Changed to --paging=never for better pipe compatibility
alias less='bat --paging=always' # Added less for when paging is desired
alias miller='mlr'
alias grep='rg'
alias find='fd'
alias md='glow'
# Note: ls/ll/la are already defined at the top of the file with proper fallback
# Git shortcuts
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias lg='lazygit' # Note: Overwrites previous lg alias
# Ghostty
alias g='ghostty'
# Homebrew aliases + shortcuts
alias b="brew"
#alias bdr="brew doctor"
alias bupd="brew update"
alias bupg="brew upgrade"
alias bclean="brew cleanup --prune=all && brew autoremove"
alias bcleanall='brew cleanup --prune=all && rm -rf $(brew --cache) && brew autoremove'
alias bi="brew info"
alias bin="brew install"
alias brein="brew reinstall"
alias bs="brew search"
alias bsa="brew search --eval-all --desc"
alias bl="brew leaves"
# Homebrew Cask/Bundle management
alias bcin="brew install --cask"
alias bb="brew bundle -g"
alias bbe="brew bundle edit -g"
alias bba="brew bundle add -g"
alias bbrm="brew bundle remove -g"
alias bbls="brew bundle dump -g --all --file=- --verbose"
alias bbsave="brew bundle dump -g --all --verbose --global"
alias bbcheck="brew bundle check -g --all --verbose --global"
# Directory navigation
alias dl='cd ~/Downloads'
alias cf='cd ~/.config/'
alias zcompreset="rm -f ~/.zcompdump; compinit"
# Tailscale
alias ts="tailscale"
# atuin
alias at="atuin"

# Misc Shortcuts
alias hf="huggingface-cli"
alias lg="lazygit"    # Note: Overwrites previous lg alias
alias ld="lazydocker" # Note: Overwrites previous lg alias

alias rx="repomix" # Note: Overwrites previous lg alias

alias zj="zellij"
alias zjl="zellij list-sessions"
alias zja='zellij attach "$(zellij list-sessions -n | fzf --reverse --border --no-sort --height 40% | awk '\''{print $1}'\'')"'
alias zje="zellij edit"

# Environment variables for tools
export BAT_THEME="--theme=OneHalfDark"
export DELTA_PAGER="bat --plain --paging=never"
export FZF_DEFAULT_OPTS='--height 40% --border --cycle --layout=reverse --marker="✓" --bind=ctrl-j:down,ctrl-k:up'
export GLOW_PAGER="bat --plain --language=markdown"
export HOMEBREW_NO_ANALYTICS=1

# FZF enhanced aliases
# File navigation
alias ff='f find'  # Find files
alias fe='f edit'  # Find and edit files
alias fdir='f dir' # Find directories
alias fz='f z'     # Jump with zoxide

# Define function for git operations with fzf
fgit() {
  local cmd="$1"
  case "$cmd" in
  checkout | co)
    local branch=$(git branch --all | grep -v HEAD | fzf --preview="git log -p {}" | sed "s/.* //")
    [[ -n "$branch" ]] && git checkout "$branch"
    ;;
  add)
    local files=$(git status -s | fzf --multi --preview="git diff {2}" | awk '{print $2}')
    [[ -n "$files" ]] && git add $files
    ;;
  log)
    git log --oneline | fzf --preview="git show {1}" | cut -d' ' -f1
    ;;
  diff)
    git diff --name-only | fzf --preview="git diff {}"
    ;;
  status)
    git status -s | fzf --preview="git diff {2}"
    ;;
  *)
    echo "Usage: fgit [checkout|add|log|diff|status]"
    return 1
    ;;
  esac
}

# Git fzf aliases
alias fco='fgit checkout' # Git checkout
alias fga='fgit add'      # Git add files
alias fgl='fgit log'      # Git log
alias fgs='fgit status'   # Git status
alias fgd='fgit diff'     # Git diff
