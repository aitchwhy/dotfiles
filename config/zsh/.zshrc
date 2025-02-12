############################
# Consolidated Zsh configuration for interactive shells
# Organized for performance and clarity
############################

# source "$HOME/dotfiles/scripts/utils.sh"


# # Helper functions
# _load_if_exists() 
#     local cmd="$1"
#     local setup_cmd="$2"
#
#     if command -v "$cmd" > /dev/null; then
#         eval "$setup_cmd"
#     fi
# }
#
# _load_config_if_exists() {
#     local config="$1"
#     [[ -f "$config" ]] && source "$config"
# }

# ============================================================================ #
# .zshenv
# ============================================================================ #

# ====== Environment Variables ======
# XDG Base Directory Specification
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

# Ensure directories exist
mkdir -p "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME/zsh"

# Tool configurations
export LANG=en_US.UTF-8
export EDITOR="nvim"
export VISUAL="nvim"

export STARSHIP_CONFIG="$XDG_CONFIG_HOME/starship/starship.toml"
export ATUIN_CONFIG_DIR="$XDG_CONFIG_HOME/atuin"
export ZELLIJ_CONFIG_DIR="$XDG_CONFIG_HOME/zellij"
# export VOLTA_HOME="$HOME/.volta"

export BAT_CONFIG_PATH="$XDG_CONFIG_HOME/bat/config"
export RIPGREP_CONFIG_PATH="$XDG_CONFIG_HOME/ripgrep/config"
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border"

# Zoxide configuration
export _ZO_DATA_DIR="${XDG_DATA_HOME}/zoxide"


# Enable TF metal acceleration
export METAL_DEVICE_WRAPPER_TYPE=1
export TF_ENABLE_METAL=1

# History configuration
export HISTFILE="$XDG_STATE_HOME/zsh/history"
export HISTSIZE=10000
export SAVEHIST=10000

# # Runs in all sessions
# export CARGO_HOME="$HOME/.cargo"
# export CLICOLOR=1
# export GOPATH="$HOME/go"
# if [[ -d "$CARGO_HOME" ]]; then
#     source "$HOME/.cargo/env"
# fi

# ============================================================================ #
# .zprofile
# ============================================================================ #

# ====== Path Configuration ======
# Initialize Homebrew (this also sets up PATH)
if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi
# Use /opt/homebrew if on Apple Silicon
# export HOMEBREW_PREFIX="/opt/homebrew"
# export PATH="$HOMEBREW_PREFIX/bin:$PATH"

# Additional PATH entries (only add if they exist and aren't already in PATH)
typeset -U path  # Ensure unique entries
local additional_paths=(
    "$HOME/.local/bin"
    # "/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
    "$CARGO_HOME/bin"
    "$GOPATH/bin"
    "$PYENV_ROOT/bin"
)

for p in $additional_paths; do
    if [[ -d "$p" ]] && [[ ":$PATH:" != *":$p:"* ]]; then
        path+=("$p")
    fi
done


# ============================================================================ #
# .zshrc
# ============================================================================ #

# ====== Shell Options ======
setopt AUTO_CD              # Change directory without cd
setopt EXTENDED_GLOB        # Extended globbing
setopt NOTIFY              # Report status of background jobs immediately
setopt PROMPT_SUBST        # Enable parameter expansion in prompts
setopt INTERACTIVE_COMMENTS # Allow comments in interactive shells
setopt HIST_IGNORE_DUPS    # Don't record duplicated entries in history
setopt HIST_REDUCE_BLANKS  # Remove unnecessary blanks from history
setopt HIST_VERIFY         # Don't execute immediately upon history expansion

# ====== Vi Mode Configuration ======
bindkey -v
export KEYTIMEOUT=1

# Maintain some emacs-style bindings in vi mode
bindkey '^P' up-line-or-history
bindkey '^N' down-line-or-history
bindkey '^E' end-of-line
bindkey '^A' beginning-of-line
bindkey '^?' backward-delete-char

# ====== Completion System ======

# https://docs.brew.sh/Shell-Completion#configuring-completions-in-zsh
# Initialize completions for Homebrew and installed packages
# if type brew &>/dev/null; then
#     FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
#
#     # Load brew-installed completions
#     local completion_file
#     for completion_file in "$(brew --prefix)/share/zsh/site-functions"/_*; do
#         if [[ -f "$completion_file" ]]; then
#             source "$completion_file"
#         fi
#     done
# fi

# Load completion system
autoload -Uz compinit
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
    compinit
else
    compinit -C
fi


# ====== Plugin Loading ======
# Function to load brew-installed plugins
_load_brew_plugin() {
    local plugin_name="$1"
    local plugin_path="$(brew --prefix)/share/zsh-${plugin_name}/${plugin_name}.zsh"
    [[ -f "$plugin_path" ]] && source "$plugin_path"
}

# Load essential plugins
_load_brew_plugin "syntax-highlighting"
_load_brew_plugin "autosuggestions"

# ====== Tool Initialization ======
# Initialize starship prompt if installed
(( $+commands[starship] )) && eval "$(starship init zsh)"

# Initialize atuin if installed (with up arrow disabled due to vi mode)
(( $+commands[atuin] )) && eval "$(atuin init zsh --disable-up-arrow)"

# Initialize zsh-abbr if installed
(( $+commands[abbr] )) && eval "$(abbr init zsh)"

(( $+commands[zoxide] )) && eval "$(zoxide init zsh)"


# Initialize zellij if installed and not already in a session
# if (( $+commands[zellij] )) && [[ -z "$ZELLIJ" ]]; then
#     eval "$(zellij setup --generate-auto-start zsh)"
# fi

# pyenv
# (( $+commands[pyenv] )) && eval "$(pyenv init -)"

# fnm
(( $+commands[fnm] )) && eval "$(fnm env --use-on-cd)"

# uv
eval "$(uv generate-shell-completion zsh)"


# # Python (pyenv)
# if command -v pyenv >/dev/null; then
#     eval "$(pyenv init -)"
# fi

# # Node.js (fnm)
# if command -v fnm >/dev/null; then
#     eval "$(fnm env --use-on-cd)"
# fi


# ====== Yazi File Manager Configuration ======
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}


# ====== Aliases ======
# Modern replacements


# # Navigation
# alias ..='cd ..'
# alias ...='cd ../..'
# alias ....='cd ../../..'
# alias -- -='cd -'

# Aliases
# Modern CLI tool alternatives
if command -v eza >/dev/null; then
    alias ls='eza --icons --group-directories-first'
    alias ll='eza -l --git --icons --group-directories-first'
    alias la='eza -la --git --icons --group-directories-first'
    alias lt='eza --tree --icons --group-directories-first'
fi


# Editor
alias v='$EDITOR'
alias vi='$EDITOR'
alias vim='$EDITOR'
alias ls="ls --color=auto"
alias ll="ls -la"
alias cat="bat"

command -v bat >/dev/null && alias cat='bat --paging=never'
command -v rg >/dev/null && alias grep='rg'
command -v fd >/dev/null && alias find='fd'
command -v lazygit >/dev/null && alias lg='lazygit'


# Git shortcuts
alias g="git"
alias ga="git add"
alias gc="git commit"
alias gp="git push"
alias gs="git status"
alias gp='git push'
alias gl='git pull'

# Example: flush DNS
alias flushdns="sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder"
alias showhidden="defaults write com.apple.finder AppleShowAllFiles YES; killall Finder"


# Package management
alias brewup='brew update && brew upgrade && brew cleanup'

# Load Custom Functions
# [[ -f "${ZDOTDIR}/functions.zsh" ]] && source "${ZDOTDIR}/functions.zsh"

# ====== Local Configuration ======
# Source local customizations if they exist
# [[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
# [[ -f "$ZDOTDIR/local.zsh" ]] && source "$ZDOTDIR/local.zsh"


#------------------------------------------------------------------------------
# Useful Aliases
#------------------------------------------------------------------------------
alias ll="ls -lahG"
alias brewup="brew update && brew upgrade && brew cleanup"
alias vi="nvim"



#############################################
# vim + neovim
#############################################
alias vi=nvim
alias vim=nvim

# upgrade to modern
alias ps='procs'
alias ping='gping'

alias diff='delta'


## FZF enhanced commands
alias flog='fzf --preview "bat --style=numbers --color=always --line-range=:500 {}"'
alias falias='alias | fzf'
alias fman='man -k . | fzf --preview "man {}"'
alias fls='man -k . | fzf --preview "man {}"'

alias ls='eza -al'
# alias cheat='navi'
# alias tldr='navi'
alias net='trippy'
alias netviz='netop'
alias jwt='jet-ui'
alias sed='sd'
alias du='dust'
alias ssh='sshs'
alias s3='stu'
# alias http='xh'
alias http='posting'
alias csv='xsv'
# alias rm='rip'
alias tmux='zellij'

alias jsonfilter='jnv'
alias jsonviewer='jnv'

# k8s kubernetes + docker + containers
alias k='k9s'

## Modern CLI alternatives
alias cat='bat --paging=always'
alias miller='mlr'
alias grep='rg'
alias find='fd'
alias md='glow'
alias ls='eza --icons'
alias ll='eza -l --icons'
alias la='eza -al --icons'
#
## Git shortcuts
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias lg='lazygit'

## Ghostty
alias g='ghostty'

## Homebrew aliases + shortcuts
#
# https://github.com/Homebrew/homebrew-aliases

alias b="brew"
#alias bdr="brew doctor"
#alias boc="brew outdated --cask"
#alias bof="brew outdated --formula"
alias bupd="brew update"
alias bupg="brew upgrade"
alias bclean="brew cleanup --prune=all && brew autoremove"
alias bcleanall='brew cleanup --prune=all && rm -rf $(brew --cache) && brew autoremove'
alias bin="brew install"
alias brein="brew reinstall"
alias bi="brew info"
alias bs="brew search"
alias bl="brew leaves"

## Homebrew Cask/Bundle management
alias bcl="brew list --cask"
alias bcin="brew install --cask"
alias bb="brew bundle"
alias bbls="brew bundle dump --all --file=- --verbose"
alias bbsave="brew bundle dump --all --verbose --global"
alias bbcheck="brew bundle check --all --verbose --global"

## Directory navigation
alias gdl='cd ~/Downloads'
alias gcf='cd ~/.config/'
#
#
# Zsh configuration
alias ze="nvim ~/.zshrc"
alias zs="exec zsh"
alias zr="exec zsh"
alias zcompreset="rm -f ~/.zcompdump; compinit"


# Tailscale
alias ts="tailscale"

# # +--------+
# # | System |
# # +--------+
#
# alias shutdown='sudo shutdown now'
# alias restart='sudo reboot'
# alias suspend='sudo pm-suspend'
#
# alias bigf= 'find / -xdev -type f -size +500M'  # display "big" files > 500M
#
# # +-----+
# # | X11 |
# # +-----+
#
# alias xpropc='xprop | grep WM_CLASS' # display xprop class
#
# # +-----+
# # | Zsh |
# # +-----+
#
# alias d='dirs -v'
# for index ({1..9}) alias "$index"="cd +${index} > /dev/null"; unset index # directory stack
#
# alias kitty='kitty -o allow_remote_control=yes --single-instance --listen-on unix:@mykitty'
#
#
# # +------+
# # | wget |
# # +------+
# alias wget='wget --hsts-file="$HOME/wget-hsts'
#
# # +----+
# # | cp |
# # +----+
#
# alias cp='cp -iv'
# alias mv='mv -iv'
# alias rm='rm -iv'
#
# # +------+
# # | grep |
# # +------+
#
# alias grep="grep -P -i --color=auto"
#
# # +------+
# # | xlip |
# # +------+
#
# alias cb='xclip -sel clip'
#
# # +------+
# # | dust |
# # +------+
#
# alias dust='du -sh * | sort -hr'
#
# # +------+
# # | ping |
# # +------+
#
# alias pg='ping 8.8.8.8'
#
# # +------+
# # | time |
# # +------+
#
# alias time='/usr/bin/time'
#
# # +----+
# # | bc |
# # +----+
#
# alias calc="noglob calcul"
#
# # +-----+
# # | bat |
# # +-----+
#
# alias batl='bat --paging=never -l log'
#
# # +--------+
# # | pacman |
# # +--------+
#
# alias paci='sudo pacman -S'               # install
# alias pachi='sudo pacman -Ql'             # Pacman Has Installed - what files where installed in a package
# alias pacs='sudo pacman -Ss'              # search
# alias pacu='sudo pacman -Syu'             # update
# alias pacr='sudo pacman -R'               # remove package but not dependencies
# alias pacrr='sudo pacman -Rs'             # remove package with unused dependencies by other softwares
# alias pacrc='sudo pacman -Sc'             # remove pacman's cache
# alias pacro='pacman -Rns $(pacman -Qtdq)'
# alias pacrl='rm /var/lib/pacman/db.lck'   # pacman remove locks
# alias pacls="sudo pacman -Qe"
# alias pacc='sudo pacman -Sc'
# alias paccc='sudo pacman -Scc'            # empty the whole cache
#
# # +-------+
# # | fonts |
# # +-------+
#
# alias fonts='fc-cache -f -v'
#
# # +-----+
# # | yay |
# # +-----+
#
# alias yayi='yay -S'     # install
# alias yayhi='yay -Ql'   # Yay Has Installed - what files where installed in a package
# alias yays='yay -Ss'    # search
# alias yayu='yay -Syu'   # update
# alias yayr='yay -R'     # remove package but not dependencies
# alias yayrr='yay -Rs'   # remove package with unused dependencies by other softwares
# alias yayrc='yay -Sc'   # remove yay's cache
# alias yayls="yay -Qe"
#
# # +--------+
# # | netctl |
# # +--------+
#
# alias wifi='sudo wifi-menu -o'
#
# # +--------+
# # | Golang |
# # +--------+
#
# alias gob="go build"
# alias gor="go run" 
# alias goc="go clean -i"
# alias gta="go test ./..."       # go test all
# alias gia="go install ./..."    # go install all
#
# # +------+
# # | Hugo |
# # +------+
#
# alias hugostart="hugo server -DEF --ignoreCache"
#
# # +--------+
# # | muffet |
# # +--------+
#
# alias deadlink="muffet -t 20"
#
# # +---------+
# # | netstat |
# # +---------+
#
# alias port="netstat -tulpn | grep"
#
# # +--------+
# # | Neovim |
# # +--------+
#
# alias vim='nvim'
# alias vi='nvim'
# alias svim='sudoedit'
# alias dvim="vim -u /usr/share/nvim/archlinux.vim" # nvim with default config
# alias nvimc='rm -I $VIMCONFIG/swap/*'             # clean nvim swap file
# alias nvimcu='rm -I $VIMCONFIG/undo/*'            # clean the vim undo
# alias nviml='nvim -w $VIMCONFIG/vimlog "$@"'      # log the keystrokes 
# alias nvimd='nvim --noplugin -u NONE'             # launch nvim without any plugin or config (nvim debug)
# alias nvimfr='nvim +e /tmp/scratchpad.md -c "set spelllang=fr"'
# alias lvim='\vim -c "set nowrap|syntax off"'        # fast vim for big files / big oneliner
#
# # +-----+
# # | Git |
# # +-----+
#
# alias gs='git status'
# alias gss='git status -s'
# alias ga='git add'
# alias gp='git push'
# alias gpraise='git blame'
# alias gpo='git push origin'
# alias gpof='git push origin --force-with-lease'
# alias gpofn='git push origin --force-with-lease --no-verify'
# alias gpt='git push --tag'
# alias gtd='git tag --delete'
# alias gtdr='git tag --delete origin'
# alias grb='git branch -r'                                                                           # display remote branch
# alias gplo='git pull origin'
# alias gb='git branch '
# alias gc='git commit'
# alias gd='git diff'
# alias gco='git checkout '
# alias gl='git log --oneline'
# alias gr='git remote'
# alias grs='git remote show'
# alias glol='git log --graph --abbrev-commit --oneline --decorate'
# alias gclean="git branch --merged | grep  -v '\\*\\|master\\|develop' | xargs -n 1 git branch -d" # Delete local branch merged with master
# alias gblog="git for-each-ref --sort=committerdate refs/heads/ --format='%(HEAD) %(color:red)%(refname:short)%(color:reset) - %(color:yellow)%(objectname:short)%(color:reset) - %(contents:subject) - %(authorname) (%(color:blue)%(committerdate:relative)%(color:reset))'"                                                             # git log for each branches
# alias gsub="git submodule update --remote"                                                        # pull submodules
# alias gj="git-jump"                                                                               # Open in vim quickfix list files of interest (git diff, merged...)
#
# alias dif="git diff --no-index"                                                                   # Diff two files even if not in git repo! Can add -w (don't diff whitespaces)
#
# # +------+
# # | tmux |
# # +------+
#
# alias tmuxk='tmux kill-session -t'
# alias tmuxa='tmux attach -t'
# alias tmuxl='tmux list-sessions'
#
# # +-------+
# # | tmuxp |
# # +-------+
#
# alias mux='tmuxp load'
#
#
# # +------+
# # | lynx |
# # +------+
#
# alias lynx='lynx -vikeys -accept_all_cookies'
#
# # +----------------+
# # | udiskie-umount |
# # +----------------+
#
# alias ubackup='udiskie-umount $MEDIA/BACKUP'
# alias umedia='udiskie-umount $MEDIA/*'
#
# # +--------+
# # | docker |
# # +--------+
# alias dockls="docker container ls | awk 'NR > 1 {print \$NF}'"                  # display names of running containers
# alias dockRr='docker rm $(docker ps -a -q)'                                     # delete every containers / images
# alias dockRr='docker rm $(docker ps -a -q) && docker rmi $(docker images -q)'   # delete every containers / images
# alias dockstats='docker stats $(docker ps -q)'                                  # stats on images
# alias dockimg='docker images'                                                   # list images installed
# alias dockprune='docker system prune -a'                                        # prune everything
# alias dockceu='docker-compose run --rm -u $(id -u):$(id -g)'                    # run as the host user
# alias dockce='docker-compose run --rm'
#
# # +----------------+
# # | docker-compose |
# # +----------------+
#
# alias docker-compose-dev='docker-compose -f docker-compose-dev.yml' # run a different config file than the default one
#
# # +----------+
# # | Personal |
# # +----------+
#
# alias nvidia-settings='nvidia-settings --config="$XDG_CONFIG_HOME"/nvidia/settings'
#
# # Folders
# alias work="$HOME/workspace"
# alias doc="$HOME/Documents"
# alias dow="$HOME/Downloads"
# alias dot="$HOME/.dotfiles"
#
# # Mindmaps
# alias freebrain="freemind $CLOUD/knowledge_base/_BRAINSTORMING/*.mm &> /dev/null &"
# alias freelists="freemind $CLOUD/knowledge_base/_LISTS/*.mm &> /dev/null &"
# alias freepain="freemind $CLOUD/knowledge_base/_PROBLEMS/*.mm &> /dev/null &"
# alias freeproj="freemind $CLOUD/knowledge_base/_PROJECTS/*.mm &> /dev/null &"
#  
# # Golang
# alias gosrc="$GOPATH/src/" # golang src
# alias gobin="$GOPATH/bin/" # golang bin
#
# # Clojure
# alias cljrepl='clojure -Sdeps "{:deps {com.bhauman/rebel-readline {:mvn/version \"0.1.4\"}}}" -m rebel-readline.main'
#
# # AWS
# alias awsa='aws --profile amboss-profile'
#
# # OBS
#
# alias obsn='prime-run obs&'
#
# # +--------+
# # | Custom |
# # +--------+
#
# alias mke='mkextract'
# alias ex='extract'
#
# # +---------+
# # | scripts |
# # +---------+
#
# alias ddg="duckduckgo"
# alias wiki="wikipedia"
#
#
# ## marta file manager symlink
# ## ln -s /Applications/Marta.app/Contents/Resources/launcher /usr/local/bin/marta
# #alias marta="/Applications/Marta.app/Contents/Resources/launcher"
# #
# ## -----------------------------------------------------
# ## Custom functions (example)
# ## -----------------------------------------------------
# #mkcd () {
# #  mkdir -p "$1" && cd "$1"
# #}
# #
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
#     ln -nfs "$src_orig" "$dst_link"
# }
#
# slink_init() {
#     slink $DOTFILES/.Brewfile $HOME/.Brewfile
#     slink $DOTFILES/.zshrc $HOME/.zshrc
#
#     slink $DOTFILES_EXPORTS $OMZ_CUSTOM/exports.zsh
#     slink $DOTFILES_ALIASES $OMZ_CUSTOM/aliases.zsh
#     slink $DOTFILES_FUNCTIONS $OMZ_CUSTOM/functions.zsh
#
#     slink $DOTFILES/nvm/default-packages $NVM_DIR/default-packages
#     slink $DOTFILES/.config/git/.gitignore $HOME/.gitignore
#
#
#     slink $DOTFILES/.config/zellij/main-layout.kdl $HOME/.config/config.kdl
# }
#
