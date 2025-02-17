
#########################
# Modern CLI alternatives with fallbacks
#########################
command -v bat >/dev/null && alias cat='bat --paging=never'
command -v btop >/dev/null && alias top='btop'
command -v delta >/dev/null && alias diff='delta'
command -v duf >/dev/null && alias df='duf'
command -v dust >/dev/null && alias du='dust'
command -v fd >/dev/null && alias find='fd'
command -v gping >/dev/null && alias ping='gping'
command -v htop >/dev/null && alias top='htop'
command -v lazygit >/dev/null && alias lg='lazygit'
command -v nvim >/dev/null && alias vi='nvim' && alias vim='nvim'
command -v procs >/dev/null && alias ps='procs'
command -v rg >/dev/null && alias grep='rg'
command -v yazi >/dev/null && alias ranger='yazi'

#
# # TODO: improvements (https://news.ycombinator.com/item?id=41037197)
# # TODO: ripgrep rg
# # TODO: fd
# # TODO: fzf
# # TODO: lazydocker
# # TODO: jless
# # TODO: starship
# # TODO: sd
# # TODO: vegeta
# # TODO: miller
# # TODO: hyperfine
#

# File listing with eza
if command -v eza >/dev/null; then
    # Basic listings
    alias ls='eza --icons --group-directories-first'
    alias ll='eza -l --icons --group-directories-first'
    alias la='eza -la --icons --group-directories-first'
    
    # Specialized listings
    alias lt='eza --tree --icons'
    alias lm='eza -l --sort=modified'
    alias lsize='eza -l --sort=size'
    alias ltype='eza -l --sort=extension'
    alias ld='eza --only-dirs'
    alias lf='eza --only-files'
    
    # Advanced options
    alias ldepth='eza --level=2'
    alias lignore='eza --git-ignore'
    alias lcontext='eza --long --context'

# # https://github.com/MohamedElashri/eza-zsh/blob/main/eza-zsh.plugin.zsh
# if command -v eza >/dev/null; then
#     alias ls='eza --icons --group-directories-first'
#     alias l='eza --long -bF' # Extended details with binary sizes and type indicators
#     alias ll='eza -l --icons --group-directories-first'
#     alias la='eza -la --icons --group-directories-first' # Show all files, with directories listed first
#     alias lt='eza --tree --icons'
#     alias lm='eza -l --sort=modified'
#     alias llm='eza --long -a --sort=modified' # Long format, including hidden files, sorted by modification date
#     alias lsize='eza -l --sort=size'
#     alias ltype='eza -l --sort=extension'
#     alias lsize='eza --long --sort=size' # Sort by size in long format
#     alias lmod='eza --long --modified --sort=modified' # Sort by modification date in long format, using the modified timestamp
#     alias ld='eza --only-dirs' # List only directories
#     alias lf='eza --only-files' # List only files
#     alias lr='eza --recurse --all' # Recursively list all files, including hidden ones
#
#     # Advanced filtering and display options
#     alias ldepth='eza --level=2' # Limit recursion depth to 2
#     alias lignore='eza --git-ignore' # Ignore files mentioned in .gitignore
#     alias lcontext='eza --long --context' # Show security context
#     alias lsize='eza --long --sort=size' # Sort by size in long format
#     alias lmod='eza --long --modified --sort=modified' # Sort by modification date in long format, using the modified timestamp
#     alias lt='eza --long --sort=type' # Sort by file type in long format
#     alias lh='eza --hyperlink --all' # Display all entries as hyperlinks
#     alias lC='eza --color-scale=size --long' # Use color scale based on file size
#
fi

# Directory navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias -- -='cd -'

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
alias g='git'
alias gs='git status'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit'
alias gca='git commit --amend'
alias gco='git checkout'
alias gd='git diff'
alias glog='git log --oneline'
alias gp='git push'
alias gll='git pull'
alias gb='git branch'
alias gst='git status -sb'
alias glog='git log --oneline --decorate --graph'
alias gpf='git push --force-with-lease'
alias grb='git rebase'
alias grs='git restore'
alias gsw='git switch'

alias gplo='git pull origin'
alias gpo='git push origin'
alias gpof='git push origin --force-with-lease'
alias gpofn='git push origin --force-with-lease --no-verify'
alias gpt='git push --tag'
alias gr='git remote'
alias grb='git branch -r'
alias grs='git remote show'
alias gs="git status"
alias gss='git status -s'
alias gst='git status -sb'
alias gsub="git submodule update --remote"                                                        # pull submodules
alias gt='git tag'
alias gtd='git tag --delete'
alias gtdr='git tag --delete origin'

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

# Development tools
# Python
alias py='python'
alias pip='uv pip'
alias pip3='uv pip3'
# alias venv='python -m venv .venv'
alias venva='source .venv/bin/activate'
alias venvd='deactivate'

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

# Task management
alias td='todoist'
alias tda='todoist add'
alias tdl='todoist list'
alias tdt='todoist today'

# System commands
alias flushdns='sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder'
alias paths='echo -e ${PATH//:/\\n}'
alias ports='lsof -i -P -n | grep LISTEN'
alias ip='curl -s ipinfo.io | jq .'

# Reload shell
alias reload='exec zsh'
alias zs='source ~/.config/zsh/.zshrc'

# Utils 
alias paths='echo $PATH | tr ":" "\n"'
# alias src='cd ~/src'
# alias dots='cd ~/dotfiles'

# tool
alias st='starship'

######################################### END
# # Modern file listing with eza
# fi

#
#
# ########################
# # Homebrew
# #
# #
# # "brew cleanup scrub" removes all downloaded files from the cache, including those for the latest versions of installed packages, while "brew cleanup --prune all" removes all cache files regardless of their age, essentially wiping the entire cache completely; the key difference is that "scrub" specifically targets even the newest downloads, while "prune all" just removes everything in the cache regardless of version. 
# # Key points to remember:
# #
# # brew cleanup scrub (-s flag):
# # - Aggressive cleaning, deleting even the latest downloaded files from the cache. 
# # - Useful when you want to completely free up disk space, even if it means potentially re-downloading the latest versions of packages on the next install. 
# #
# # brew cleanup --prune all:
# # - Removes all cached files, including old versions, from the cache. 
# # - Less aggressive than "scrub" as it only targets files older than a specific threshold (in this case, "all").
# #
# # https://mac.install.guide/homebrew/8#:~:text=Homebrew%20maintains%20a%20cache%20of,cleanup%20with%20%2D%2Dprune=all%20.
# #
# ########################
# # alias cask='brew cask'
#
# # System
# alias flushdns='sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder'
# alias paths='echo -e ${PATH//:/\\n}'
# alias ports='lsof -i -P -n | grep LISTEN'
# alias ip='curl -s ipinfo.io | jq .'
#
# # Development
# # alias py='python3'
# # alias pip='pip3'
# alias npml='npm list --depth=0'
# alias npms='npm start'
# alias npmt='npm test'
#
#
#
# # starship
#
# # ------------------------
# # Git shortcuts
# # ------------------------
# alias dif="git diff --no-index"                                                                   # Diff two files even if not in git repo! Can add -w (don't diff whitespaces)
# alias g='git'
# alias ga='git add'
# alias gaa='git add --all'
# alias gb='git branch '
# alias gblame='git blame'
# alias gblog="git for-each-ref --sort=committerdate refs/heads/ --format='%(HEAD) %(color:red)%(refname:short)%(color:reset) - %(color:yellow)%(objectname:short)%(color:reset) - %(contents:subject) - %(authorname) (%(color:blue)%(committerdate:relative)%(color:reset))'"                                                             # git log for each branches
# alias gc="git commit"
# alias gca='git commit --amend'
# alias gclean="git branch --merged | grep  -v '\\*\\|master\\|develop' | xargs -n 1 git branch -d" # Delete local branch merged with master
# alias gco='git checkout '
# alias gd='git diff'
# alias gj="git-jump"                                                                               # Open in vim quickfix list files of interest (git diff, merged...)
# alias gl='git log --oneline'
# alias gl='git pull'
# alias glog='git log --oneline --decorate --graph'
# alias glol='git log --graph --abbrev-commit --oneline --decorate'
# alias gp="git push"
# alias gplo='git pull origin'
# alias gpo='git push origin'
# alias gpof='git push origin --force-with-lease'
# alias gpofn='git push origin --force-with-lease --no-verify'
# alias gpt='git push --tag'
# alias gr='git remote'
# alias grb='git branch -r'                                                                           # display remote branch
# alias grs='git remote show'
# alias gs="git status"
# alias gss='git status -s'
# alias gst='git status -sb'
# alias gsub="git submodule update --remote"                                                        # pull submodules
# alias gtd='git tag --delete'
# alias gtdr='git tag --delete origin'
#
#
#
#
# ################################
# # Custom aliases
# ################################
#
# # ====== Aliases ======
# # Modern replacements
#
#
#
#
# # Alias suggestions for your .zshrc:
# alias fbr='fzf-brew'
# alias fb='fzf-browse'
# alias ff='fzf-find'
# alias fk='fzf-kill'
# alias fh='fzf-history'
# alias fgb='fzf-git-branch'
# ## FZF enhanced commands
# alias flog='fzf --preview "bat --style=numbers --color=always --line-range=:500 {}"'
# alias falias='alias | fzf'
# alias fman='man -k . | fzf --preview "man {}"'
# alias fls='man -k . | fzf --preview "man {}"'
#
# # Example: flush DNS
# alias flushdns="sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder"
# alias showhidden="defaults write com.apple.finder AppleShowAllFiles YES; killall Finder"
#
#
# # Package management
# alias brewup='brew update && brew upgrade && brew cleanup --prune=all'
#
# #------------------------------------------------------------------------------
# # Useful Aliases
# #------------------------------------------------------------------------------
# alias ll="ls -lahG"
# alias brewup="brew update && brew upgrade && brew cleanup"
# alias vi="nvim"
#
#
# # Utility aliases
# alias path='echo $PATH | tr ":" "\n"'
# alias reload='exec zsh'
# alias sz='source ~/.zshrc'
#
#
# #############################################
# # vim + neovim
# #############################################
# alias vi=nvim
# alias vim=nvim
#
# # upgrade to modern
# alias ps='procs'
# alias ping='gping'
#
# alias diff='delta'
#
#
#
# alias ls='eza -al'
# # alias cheat='navi'
# # alias tldr='navi'
# alias net='trippy'
# alias netviz='netop'
# alias jwt='jet-ui'
# alias sed='sd'
# alias du='dust'
# alias ssh='sshs'
# alias s3='stu'
# # alias http='xh'
# alias http='posting'
# alias csv='xsv'
# # alias rm='rip'
# alias tmux='zellij'
#
# alias jsonfilter='jnv'
# alias jsonviewer='jnv'
#
# # k8s kubernetes + docker + containers
# alias k='k9s'
#
# ## Modern CLI alternatives
# alias cat='bat --paging=always'
# alias miller='mlr'
# alias grep='rg'
# alias find='fd'
# alias md='glow'
# # alias ls='eza --icons'
# # alias ll='eza -l --icons'
# # alias la='eza -al --icons'
# #
# ## Ghostty
# alias g='ghostty'
#
# ##########################################
# # Homebrew aliases + shortcuts
# #
# # https://github.com/Homebrew/homebrew-aliases
# ##########################################
#
# alias .be="nvim ~/.Brewfile"
# alias bup='brew update && brew upgrade && brew cleanup --scrub'
# alias bdeps='brew deps --tree --installed'
#
# alias b="brew"
# alias benv="brew --env"
# alias bpre="brew --prefix"
# alias bc="brew config"
# alias bh="brew home"
# alias bcmds="brew commands"
# alias bdr="brew doctor"
# alias bud="brew update"
# alias bug="brew upgrade"
# alias bclean="brew cleanup --prune=all && brew autoremove"
# alias bcleanall='brew cleanup --prune=all && brew autoremove && rm -rf $(brew --cache)'
# alias bin="brew install"
# alias brein="brew reinstall"
# alias bi="brew info"
# alias bs="brew search --eval-all --desc"
# alias bls="brew list"
# alias blv="brew leaves"
# alias btree="brew deps --tree --installed"
#
# ## Homebrew Cask/Bundle management
# alias bcl="brew list --cask"
# alias bcin="brew install --cask"
#
# # brew bundle
# alias bb="brew bundle"
# alias bbin="brew bundle install --global --all"
# alias bbe="brew bundle edit --global"
# alias bbdump="bb dump --all --verbose --desc --file=-"
# alias bbdumpf="bb dump --all --verbose --global --force"
# alias bbcheck="bb check --all --verbose --global"
# alias bblist="bb list --all --verbose --global"
# alias bbcleanup="bb cleanup --zap --all --verbose --global"
# alias bbcleanupf="bb cleanup --zap --all --verbose --global --force"
# alias bbsave="bbcleanup"
#
# ##########################################
# # Homebrew aliases + shortcuts
# #
# # https://github.com/Homebrew/homebrew-aliases
# ##########################################
#
# #
# #
# ##########################################
# # Zsh configuration
# ##########################################
# alias .ze="nvim $ZDOTDIR/.zshrc"
# alias .zp="nvim $ZDOTDIR/.zprofile"
# alias .zr="exec zsh"
# alias .zs="exec zsh"
# alias .zclean="rm -f ~/.zcompdump; compinit && exec zsh"
#
#
# # Tailscale
# alias ts="tailscale"
# alias es="espanso"
#
#
# # Zellij
# alias zj="zellij"
# alias zje="nvim $XDG_CONFIG_HOME/zellij/config.kdl"
# alias zjl="fd --format="{/.}" . $HOME/.config/zellij/layouts | fzf --preview 'cat {-1}' --bind 'enter:become(zellij --layout {-1})'"
#
# # ghostty
# alias g="ghostty"
#
#
# # todoist
# alias td="todoist"
#
# # atuin
# alias at="atuin"
# alias ats="atuin store"
# alias ati="atuin import auto"
#
# # python + uv
# alias py='python' # Quick access to python interpreter
# alias py3='python3' # Explicitly use python 3
# # alias venv='python3 -m .venv' # Create virtual environments
# # alias activate='source .venv/bin/activate' # Activate virtual environment
# # alias deactivate='deactivate' # Deactivate virtual environment
# # alias pyrun='python -m' # Run a module as a script
# # alias pydoc='pydoc3' # Access python documentation
#
#
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
#
# # Folders
#
# # # +--------+
# # # | System |
# # # +--------+
# #
# # alias shutdown='sudo shutdown now'
# # alias restart='sudo reboot'
# # alias suspend='sudo pm-suspend'
# #
# # alias bigf= 'find / -xdev -type f -size +500M'  # display "big" files > 500M
# #
# # # +-----+
# # # | X11 |
# # # +-----+
# #
# # alias xpropc='xprop | grep WM_CLASS' # display xprop class
# #
# # # +-----+
# # # | Zsh |
# # # +-----+
# #
# # alias d='dirs -v'
# # for index ({1..9}) alias "$index"="cd +${index} > /dev/null"; unset index # directory stack
# #
# # alias kitty='kitty -o allow_remote_control=yes --single-instance --listen-on unix:@mykitty'
# #
# #
# # # +------+
# # # | wget |
# # # +------+
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


