# Modern CLI alternatives
alias ls='eza --icons --group-directories-first'
alias ll='eza -l --icons --group-directories-first'
alias la='eza -la --icons --group-directories-first'
alias lt='eza --tree --icons'
alias cat='bat'
alias grep='rg'
alias find='fd'
alias ps='procs'
alias top='btm'
alias du='dust'
alias df='duf'
alias vi='nvim'
alias vim='nvim'
alias cd='z'

# Git shortcuts
alias g='git'
alias ga='git add'
alias gc='git commit'
alias gco='git checkout'
alias gd='git diff'
alias gs='git status'
alias gp='git push'
alias gl='git pull'
alias gst='git status -sb'
alias glog='git log --oneline --decorate --graph'
alias lg='lazygit'

# Directory shortcuts
alias dots='cd ~/.config'
# Directory navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias -- -='cd -'

# Homebrew
alias brewup='brew update && brew upgrade && brew cleanup'
alias brewdeps='brew deps --tree --installed'
alias brewin='brew info'
alias brewls='brew list'
alias cask='brew cask'

# System
alias flushdns='sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder'
alias paths='echo -e ${PATH//:/\\n}'
alias ports='lsof -i -P -n | grep LISTEN'
alias ip='curl -s ipinfo.io | jq .'

# Development
alias py='python3'
alias pip='pip3'
alias npml='npm list --depth=0'
alias npms='npm start'
alias npmt='npm test'


################################
# Custom aliases
################################

# ====== Aliases ======
# Modern replacements


# # Navigation
# alias ..='cd ..'
# alias ...='cd ../..'
# alias ....='cd ../../..'
# alias -- -='cd -'

# Aliases
# Modern CLI tool alternatives
# https://github.com/MohamedElashri/eza-zsh/blob/main/eza-zsh.plugin.zsh
if command -v eza >/dev/null; then
    # general use aliases updated for eza
    alias ls='eza' # Basic replacement for ls with eza
    alias l='eza --long -bF' # Extended details with binary sizes and type indicators
    alias ll='eza --long -a' # Long format, including hidden files
    alias llm='eza --long -a --sort=modified' # Long format, including hidden files, sorted by modification date
    alias la='eza -a --group-directories-first' # Show all files, with directories listed first
    alias lx='eza -a --group-directories-first --extended' # Show all files and extended attributes, directories first
    alias tree='eza --tree' # Tree view
    alias lS='eza --oneline' # Display one entry per line

    # new aliases than exa-zsh
    alias lT='eza --tree --long' # Tree view with extended details
    alias lr='eza --recurse --all' # Recursively list all files, including hidden ones
    alias lg='eza --grid --color=always' # Display entries as a grid with color
    alias ld='eza --only-dirs' # List only directories
    alias lf='eza --only-files' # List only files
    alias lC='eza --color-scale=size --long' # Use color scale based on file size
    alias li='eza --icons=always --grid' # Display with icons in grid format
    alias lh='eza --hyperlink --all' # Display all entries as hyperlinks
    alias lX='eza --across' # Sort the grid across, rather than downwards
    alias lt='eza --long --sort=type' # Sort by file type in long format
    alias lsize='eza --long --sort=size' # Sort by size in long format
    alias lmod='eza --long --modified --sort=modified' # Sort by modification date in long format, using the modified timestamp

    # Advanced filtering and display options
    alias ldepth='eza --level=2' # Limit recursion depth to 2
    alias lignore='eza --git-ignore' # Ignore files mentioned in .gitignore
    alias lcontext='eza --long --context' # Show security context
fi

# TODO: improvements (https://news.ycombinator.com/item?id=41037197)
# TODO: ripgrep rg
# TODO: fd
# TODO: fzf
# TODO: lazydocker
# TODO: jless
# TODO: starship
# TODO: sd
# TODO: vegeta
# TODO: miller
# TODO: hyperfine


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


# Utility aliases
alias path='echo $PATH | tr ":" "\n"'
alias reload='exec zsh'
alias sz='source ~/.zshrc'


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
alias benv="brew --env"
alias bp="brew --prefix"
alias bc="brew config"
alias bh="brew home"
alias bcmd="brew commands"
alias bdr="brew doctor"
alias bud="brew update"
alias bug="brew upgrade"
alias bclean="brew cleanup --prune=all && brew autoremove"
alias bcleanall='brew cleanup --prune=all && brew autoremove && rm -rf $(brew --cache)'
alias bin="brew install"
alias brein="brew reinstall"
alias bi="brew info"
alias bs="brew search --eval-all --desc"
alias bl="brew leaves"

## Homebrew Cask/Bundle management
alias bcl="brew list --cask"
alias bcin="brew install --cask"

# brew bundle
alias bb="brew bundle"
alias bbin="brew bundle install --global --all"
alias bbe="brew bundle edit --global"
alias bbdump="bb dump --all --verbose --desc --file=-"
alias bbdumpf="bb dump --all --verbose --global --force"
alias bbcheck="bb check --all --verbose --global"
alias bblist="bb list --all --verbose --global"
alias bbcleanup="bb cleanup --zap --all --verbose --global"
alias bbcleanupf="bb cleanup --zap --all --verbose --global --force"

## Directory navigation
alias gdot='cd ~/dotfiles'
alias gsrc='cd ~/src'
alias ghammer='cd ~/.hammerspoon'
alias gcf='cd ~/.config'
alias glocal='cd ~/.local'
alias gnvim='cd ~/.config/nvim'

alias gdl='cd ~/Downloads'
alias gdesk='cd ~/Desktop'
alias gdoc='cd ~/Documents'
alias gobs='cd ~/obsidian/primary'

alias gcloud='cd ~/Library/CloudStorage'
alias gdrop='cd ~/Library/CloudStorage/Dropbox'
alias glib='cd ~/Library'
alias glibapp='cd ~/Library/Application Support'
alias gicloud='cd ~/iCloud Drive'


#
#
# Zsh configuration
alias be="nvim ~/.Brewfile"
alias ze="nvim ~/.zshrc"
alias zr="exec zsh"
alias zreset="rm -f ~/.zcompdump; compinit && exec zsh"


# Tailscale
alias ts="tailscale"
alias es="espanso"


# Zellij
alias zj="zellij"
alias zje="nvim $HOME/.config/zellij/config.kdl"
alias zjl="fd --format="{/.}" . $HOME/.config/zellij/layouts | fzf --preview 'cat {-1}' --bind 'enter:become(zellij --layout {-1})'"

# ghostty
alias g="ghostty"


# todoist
alias td="todoist"

# atuin
alias at="atuin"
alias ats="atuin store"
alias ati="atuin import auto"

# python + uv
alias py='python' # Quick access to python interpreter
alias py3='python3' # Explicitly use python 3
alias venv='python3 -m .venv' # Create virtual environments
alias activate='source .venv/bin/activate' # Activate virtual environment
# alias deactivate='deactivate' # Deactivate virtual environment
alias pyrun='python -m' # Run a module as a script
alias pydoc='pydoc3' # Access python documentation

# +-----+
# | Git |
# +-----+

alias gs='git status'
alias gss='git status -s'
alias ga='git add'
alias gp='git push'
alias gplo='git pull origin'
alias gblame='git blame'
alias gpo='git push origin'
alias gpof='git push origin --force-with-lease'
alias gpofn='git push origin --force-with-lease --no-verify'
alias gpt='git push --tag'
alias gtd='git tag --delete'
alias gtdr='git tag --delete origin'
alias grb='git branch -r'                                                                           # display remote branch
alias gb='git branch '
alias gc='git commit'
alias gd='git diff'
alias gco='git checkout '
alias gl='git log --oneline'
alias gr='git remote'
alias grs='git remote show'
alias glol='git log --graph --abbrev-commit --oneline --decorate'
alias gclean="git branch --merged | grep  -v '\\*\\|master\\|develop' | xargs -n 1 git branch -d" # Delete local branch merged with master
alias gblog="git for-each-ref --sort=committerdate refs/heads/ --format='%(HEAD) %(color:red)%(refname:short)%(color:reset) - %(color:yellow)%(objectname:short)%(color:reset) - %(contents:subject) - %(authorname) (%(color:blue)%(committerdate:relative)%(color:reset))'"                                                             # git log for each branches
alias gsub="git submodule update --remote"                                                        # pull submodules
alias gj="git-jump"                                                                               # Open in vim quickfix list files of interest (git diff, merged...)
alias dif="git diff --no-index"                                                                   # Diff two files even if not in git repo! Can add -w (don't diff whitespaces)


# +--------+
# | docker |
# +--------+
alias dockls="docker container ls | awk 'NR > 1 {print \$NF}'"                  # display names of running containers
alias dockRr='docker rm $(docker ps -a -q)'                                     # delete every containers / images
alias dockRr='docker rm $(docker ps -a -q) && docker rmi $(docker images -q)'   # delete every containers / images
alias dockstats='docker stats $(docker ps -q)'                                  # stats on images
alias dockimg='docker images'                                                   # list images installed
alias dockprune='docker system prune -a'                                        # prune everything
alias dockceu='docker-compose run --rm -u $(id -u):$(id -g)'                    # run as the host user
alias dockce='docker-compose run --rm'

# +----------------+
# | docker-compose |
# +----------------+

alias docker-compose-dev='docker-compose -f docker-compose-dev.yml' # run a different config file than the default one

# +----------+
# | Personal |
# +----------+

alias nvidia-settings='nvidia-settings --config="$XDG_CONFIG_HOME"/nvidia/settings'

# Folders

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

