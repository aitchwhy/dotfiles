export EDITOR="nvim"
export YAZI_CONFIG_DIR="$XDG_CONFIG_HOME/yazi"
export ZELLIJ_CONFIG_DIR="$XDG_CONFIG_HOME/zellij"

# add local bin to PATH
path=("$HOME/.local/bin" $path)

# --- Optional configuration from the full .zshrc ---
# # ========================================================================
# # ZSH Configuration (.zshrc)
# # ========================================================================
# # Main configuration for interactive shells - consolidated and minimal
# 
# # Performance monitoring (uncomment to debug)
# # zmodload zsh/zprof
# 
# # ========================================================================
# # Shell Options
# # ========================================================================
# setopt AUTO_PUSHD         # Push directory to stack on cd
# setopt PUSHD_IGNORE_DUPS  # Don't store duplicates in dir stack
# setopt PUSHD_SILENT       # Don't print stack after pushd/popd
# setopt NO_CASE_GLOB       # Case insensitive globbing
# setopt INTERACTIVE_COMMENTS # Allow comments in interactive shells
# setopt NO_NOMATCH         # Don't error on no glob matches
# 
# # History Configuration
# setopt SHARE_HISTORY      # Share history between sessions
# setopt HIST_IGNORE_DUPS   # Don't record duplicates
# setopt HIST_IGNORE_SPACE  # Ignore commands starting with space
# setopt HIST_VERIFY        # Don't execute immediately on history expansion
# setopt EXTENDED_HISTORY   # Record timestamp
# 
# export HISTFILE="$HOME/.zsh_history"
# export HISTSIZE=100000
# export SAVEHIST=$HISTSIZE
# 
# # ========================================================================
# # Environment Variables
# # ========================================================================
# # XDG directories
# export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
# export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
# export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
# 
# # Create XDG directories if they don't exist
# for dir in "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME"; do
#     [[ ! -d "$dir" ]] && mkdir -p "$dir"
# done
# 
# # Shortcuts
# export DOTS="$DOTFILES"
# export CFS="$DOTFILES/.config"
# export CFSZSH="$CFS/zsh"
# export SCRIPTS="$DOTFILES/scripts"
# export OBS="$HOME/obsidian/primary"
# 
# # Tool configurations
# export BAT_THEME="OneHalfDark"
# export DELTA_PAGER="bat --plain --paging=never"
# export FZF_DEFAULT_OPTS='--height 40% --border --cycle --layout=reverse --marker="✓" --bind=ctrl-j:down,ctrl-k:up'
# export STARSHIP_CONFIG="$CFS/starship/starship.toml"
# export GIT_CONFIG_GLOBAL="$CFS/git/gitconfig"
# export LG_CONFIG_FILE="$CFS/lazygit/config.yml"
# export CARGO_HOME="${CARGO_HOME:-$HOME/.cargo}"
# export RUSTUP_HOME="${RUSTUP_HOME:-$HOME/.rustup}"
# export GOPATH="$HOME/go"
# export GOBIN="$GOPATH/bin"
# export ATUIN_CONFIG_DIR="$CFS/atuin"
# export YAZI_CONFIG_DIR="$CFS/yazi"
# export ZELLIJ_CONFIG_DIR="$CFS/zellij"
# export HOMEBREW_NO_ANALYTICS=1
# export COLORTERM="truecolor"
# export USER_JUSTFILE="$CFS/just/.user.justfile"
# 
# # NPM configuration - using standard ~/.npmrc (symlinked from dotfiles)
# # export NPM_CONFIG_USERCONFIG="$CFS/npm/.npm-global"  # No longer needed
# 
# # Add a directory to PATH if it exists and isn't already in PATH
# export path_add() {
#   local dir="$1"
#   if [[ -d "$dir" ]] && [[ ":$PATH:" != *":$dir:"* ]]; then
#     export PATH="$dir:$PATH"
#     return 0
#   fi
#   return 1
# }
# path_add "$CFS/npm-global/bin"  # Add npm global packages to PATH
# 
# # ========================================================================
# # Completions
# # ========================================================================
# # Add Homebrew completions
# if [[ -n "$HOMEBREW_PREFIX" ]]; then
#     FPATH="$HOMEBREW_PREFIX/share/zsh/site-functions:$FPATH"
# fi
# 
# # Add Nix completions if available
# if [[ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]]; then
#     fpath+=(/nix/var/nix/profiles/default/share/zsh/site-functions)
# fi
# 
# # Add custom completions
# fpath=("$CFS/zsh/.zfunc" $fpath)
# 
# # Initialize completion system
# autoload -Uz compinit && compinit
# 
# # ========================================================================
# # Key Bindings
# # ========================================================================
# bindkey -v
# export KEYTIMEOUT=1
# 
# # ========================================================================
# # Plugins (from Homebrew)
# # ========================================================================
# if [[ -d "$HOMEBREW_PREFIX/share" ]]; then
#     # Load plugins if available
#     [[ -f "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] && \
#         source "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
#     
#     [[ -f "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] && \
#         source "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
#     
#     [[ -f "$HOMEBREW_PREFIX/share/zsh-abbr/zsh-abbr.zsh" ]] && \
#         source "$HOMEBREW_PREFIX/share/zsh-abbr/zsh-abbr.zsh"
# fi
# 
# # ========================================================================
# # Core Functions
# # ========================================================================
# 
# 
# # Check if command exists
# has_command() {
#     command -v "$1" &>/dev/null
# }
# 
# # Add to PATH if not already present
# path_add() {
#     [[ -d "$1" && ":$PATH:" != *":$1:"* ]] && export PATH="$PATH:$1"
# }
# 
# # ========================================================================
# # Aliases - File System
# # ========================================================================
# alias ls='eza --git --icons'
# alias l='eza --git --icons -lF'
# alias ll='eza -lahF --git'
# alias lll="eza -1F --git --icons"
# alias llm='ll --sort=modified'
# alias la='eza -lbhHigUmuSa --color-scale --git --icons'
# alias lx='eza -lbhHigUmuSa@ --color-scale --git --icons'
# alias lt='eza --tree --level=2'
# alias llt='eza -lahF --tree --level=2'
# alias ltt='eza -lahF | grep "$(date +"%d %b")"'
# 
# # ========================================================================
# # Aliases - Navigation
# # ========================================================================
# alias ..='cd ..'
# alias ...='cd ../..'
# alias ....='cd ../../..'
# 
# # ========================================================================
# # Aliases - Editors
# # ========================================================================
# alias v='$EDITOR'
# alias vi='$EDITOR'
# alias vim='$EDITOR'
# 
# # ========================================================================
# # Aliases - Zsh
# # ========================================================================
# alias zr="exec zsh"
# alias ze="$EDITOR $ZDOTDIR/.zshrc"
# alias zeall="$EDITOR $ZDOTDIR/{.zshrc,.zprofile,.zshenv}"
# alias zcompreset="rm -f ~/.zcompdump; compinit"
# 
# # ========================================================================
# # Aliases - Git
# # ========================================================================
# alias g='git'
# alias gs='git status'
# alias ga='git add'
# alias gai='git add -i'
# alias gaa='git add --all'
# alias gc='git commit'
# alias gcm='git commit -m'
# alias gca='git commit --amend --no-edit'
# alias gp='git push'
# alias gll='git pull'
# alias lg='lazygit'
# alias lgdot='lazygit --path $DOTFILES'
# 
# # ========================================================================
# # Aliases - Modern CLI Tools
# # ========================================================================
# alias cat='bat --paging=always'
# alias grep='rg'
# alias find='fd'
# alias ps='procs'
# alias diff='delta'
# alias ping='gping'
# alias du='dust'
# alias sed='sd'
# alias md='glow'
# alias cheat='tldr'
# alias ch='cheat'
# 
# # ========================================================================
# # Aliases - Homebrew
# # ========================================================================
# alias b='brew'
# alias bup='brew update && brew upgrade'
# alias bupd='brew update'
# alias bupg='brew upgrade'
# alias bclean='brew cleanup --prune=all && rm -rf $(brew --cache) && brew autoremove'
# alias bi='brew info'
# alias bin='brew install'
# alias brein='brew reinstall'
# alias bs='brew search'
# alias bl='brew leaves'
# alias bcin='brew install --cask'
# 
# # ========================================================================
# # Aliases - Docker
# # ========================================================================
# alias d='docker'
# alias dps='docker ps'
# alias dpsa='docker ps -a'
# alias dimg='docker images'
# alias dx='docker exec -it'
# alias dc='docker-compose'
# alias ld='lazydocker'
# alias k='k9s'
# 
# # ========================================================================
# # Aliases - Just
# # ========================================================================
# alias j='just'
# alias .j='just --justfile $USER_JUSTFILE'
# 
# # ========================================================================
# # Aliases - System
# # ========================================================================
# alias ports='lsof -i -P -n | grep LISTEN'
# alias printpath='echo $PATH | tr ":" "\n"'
# alias ip='ipconfig getifaddr en0'
# alias publicip='curl -s https://api.ipify.org'
# alias flush='dscacheutil -flushcache && killall -HUP mDNSResponder'
# 
# # ========================================================================
# # Aliases - Terminal Multiplexers
# # ========================================================================
# alias zj='zellij'
# alias zjls='zellij list-sessions'
# alias zja='zellij attach "$(zellij list-sessions -n | fzf --reverse --border --no-sort --height 40% | awk '\''{print $1}'\'')"'
# 
# # ========================================================================
# # Aliases - Other Tools
# # ========================================================================
# alias tm='task-master'
# alias claude='/Users/hank/.claude/local/claude'
# alias ts='tailscale'
# alias hf='huggingface-cli'
# alias rx='repomix'
# alias at='atuin'
# alias aero='aerospace'
# alias pc='process-compose'
# alias envx='dotenvx'
# 
# # ========================================================================
# # Aliases - Nix
# # ========================================================================
# alias nixzsh='nix develop --command zsh'
# alias nixcf='$EDITOR ~/.config/nix/nix.conf'
# alias nixdev='nix develop'
# alias nixpkgs='nix search'
# alias nixf='nix flake'
# 
# # ========================================================================
# # Functions - Directory Navigation
# # ========================================================================
# 
# # Quick directory navigation with fzf
# cdf() {
#     local dir
#     dir=$(fd --type d --hidden --exclude .git | fzf --preview 'eza --tree --level=1 {}') && cd "$dir"
# }
# 
# # Edit config directories
# fdirs() {
#     local DIRPATH="$1"
#     nvim $(fd . -t d --exact-depth 1 --color never $DIRPATH | fzf --prompt="${DIRPATH} configs>" --preview='gls -s {}')
# }
# 
# xdg() {
#     fdirs $XDG_CONFIG_HOME
# }
# 
# cfs() {
#     fdirs $CFS
# }
# 
# 
# source "$DOTS/scripts/ant.zsh"
# 
# 
# # ========================================================================
# # Functions - File Operations
# # ========================================================================
# 
# # Edit files with fzf preview
# vf() {
#     local file
#     file=$(fd --type f --hidden --exclude .git | fzf --preview 'bat --color=always {}') && $EDITOR "$file"
# }
# 
# # FZF enhanced file operations
# f() {
#     local cmd result
#     case "$1" in
#     find|file)
#         result=$(fd --type f --follow --hidden --exclude .git | fzf --preview="bat --color=always {}")
#         echo "$result"
#         ;;
#     edit)
#         result=$(fd --type f --follow --hidden --exclude .git | fzf --preview="bat --color=always {}")
#         [[ -n "$result" ]] && "$EDITOR" "$result"
#         ;;
#     dir)
#         result=$(fd --type d --follow --hidden --exclude .git | fzf --preview="eza --tree --level=1 --color=always {}")
#         echo "$result"
#         ;;
#     cd)
#         result=$(fd --type d --follow --hidden --exclude .git | fzf --preview="eza --tree --level=1 --color=always {}")
#         [[ -n "$result" ]] && cd "$result"
#         ;;
#     *)
#         echo "Usage: f {find|file|edit|dir|cd}"
#         ;;
#     esac
# }
# 
# # ========================================================================
# # Functions - Yazi File Manager
# # ========================================================================
# y() {
#     local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
#     yazi "$@" --cwd-file="$tmp"
#     if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
#         builtin cd -- "$cwd"
#     fi
#     rm -f -- "$tmp"
# }
# 
# # ========================================================================
# # Tool Initialization
# # ========================================================================
# 
# # Starship prompt
# has_command starship && eval "$(starship init zsh)"
# 
# 
# 
# # Atuin (history management)
# [[ -f "$HOME/.atuin/bin/env" ]] && source "$HOME/.atuin/bin/env"
# eval "$(atuin init zsh)"
# 
# # Load utility functions if available
# [[ -f "$SCRIPTS/utils.zsh" ]] && source "$SCRIPTS/utils.zsh"
# 
# # Load local/private configuration if exists
# [[ -f "$ZDOTDIR/.zshrc.local" ]] && source "$ZDOTDIR/.zshrc.local"
# 
# 
# eval "$(zoxide init zsh)"
# 
# # ========================================================================
# # Cleanup
# # ========================================================================
# # Performance monitoring (uncomment to debug)
# # zprof
