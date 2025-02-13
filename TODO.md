# TODOs

```shell
# zsh plugins (https://github.com/unixorn/awesome-zsh-plugins?tab=readme-ov-file#plugins)

# -----------------------------------------------------
# Homebrew environment setup for Apple Silicon
# -----------------------------------------------------
# eval "$(/opt/homebrew/bin/brew shellenv)"
# autoload -Uz compinit; compinit
# source /opt/homebrew/share/zsh/site-functions
#
# -----------------------------------------------------
# ❯ brew info zsh-completions
#
# ==> zsh-completions: stable 0.35.0 (bottled), HEAD
# Additional completion definitions for zsh
# https://github.com/zsh-users/zsh-completions
# Installed
# /opt/homebrew/Cellar/zsh-completions/0.35.0 (152 files, 1.4MB) *
# ...
# To activate these completions, add the following to your .zshrc:
#
#   if type brew &>/dev/null; then
#     FPATH=$(brew --prefix)/share/zsh-completions:$FPATH
#     autoload -Uz compinit
#     compinit
#   fi
#
# You may also need to force rebuild `zcompdump`:
#   rm -f ~/.zcompdump; compinit
#
# Additionally, if you receive "zsh compinit: insecure directories" warnings when attempting
# to load these completions, you may need to run these commands:
#
#   chmod go-w '/opt/homebrew/share'
#   chmod -R go-w '/opt/homebrew/share/zsh'
#
# -----------------------------------------------------
#


if type brew &>/dev/null; then
    FPATH=$(brew --prefix)/share/zsh-completions:$FPATH
    autoload -Uz compinit; compinit
fi



# -----------------------------------------------------
# Path updates & default editor
# -----------------------------------------------------
export EDITOR="nvim"
export VISUAL="nvim"
export PAGER="bat --paging"
export DOTFILES="$HOME/dotfiles/"
export CODE_DIR="$HOME/src/"
export CONFIGS_DIR='$HOME/.configs/'


# Man pages
export MANPAGER='nvim +Man!'



# fzf
export FZF_DEFAULT_COMMAND='rg --files --hidden --glob "!.git"'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"


#-----------------------------------------------------
# keybindings + configs
#-----------------------------------------------------

# Enable Vim keybindings in zsh
bindkey -v 

# Rebind Ctrl+R to use Atuin's interactive search
bindkey '^R' 'atuin search --interactive'

#------------------------------------------------------------------------------
# Configure fzf with Vim-like keybindings
#------------------------------------------------------------------------------
export FZF_DEFAULT_OPTS="--layout=reverse --multi --height=40% --bind='ctrl-j:down,ctrl-k:up,ctrl-m:accept' --bind='esc:cancel'"

# Advanced fzf usage: Ctrl-T for file search, Alt-C for directory search
# Ctrl-R is bound to Atuin's search above, so here are custom keybindings:
bindkey '^T' fzf-file-widget
bindkey '^[C' fzf-cd-widget



# -----------------------------------------------------
# Prompt customization (example with Starship, optional)
# https://starship.rs/
# -----------------------------------------------------
if command -v starship >/dev/null 2>&1; then
 eval "$(starship init zsh)"
fi

# -----------------------------------------------------
# zsh tools setup
# -----------------------------------------------------

# atuin shell history
eval "$(atuin init zsh)"

# zoxide shell fuzzy nav
eval "$(zoxide init zsh)"

# eval "$(thefuck --alias fk)"

# Source Broot launcher for easier navigation (if installed)
# [[ -s $HOME/.config/broot/launcher/bash/br ]] && source $HOME/.config/broot/launcher/bash/br


# fzf



export NVIM_CONFIGS='$CONFIGS/nvim'


# -----------------------------------------------------
# Zsh plugins (modify based on your chosen framework)
# -----------------------------------------------------

# Manually sourcing plugins if not using a framework:
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /opt/homebrew/share/zsh-autopair/autopair.zsh
source /opt/homebrew/share/zsh-abbr/zsh-abbr.zsh


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
#
# # yazi
# function yy() {
# 	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
# 	yazi "$@" --cwd-file="$tmp"
# 	if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
# 		builtin cd -- "$cwd"
# 	fi
# 	rm -f -- "$tmp"
# }
#
#
#
#
# #############
# # TODO
# #############
#
# # screenres() {
# #     [ ! -z $1 ] && xrandr --current | grep '*' | awk '{print $1}' | sed -n "$1p"
# # }
#
# # # Begin a screencast 
# # # TODO - To fix (and miss the webcam)
# # screencast() {
# #     T="$(date +%d-%m-%Y-%H-%M-%S)".mkv
# #     if [ $# -gt 0 ]; then
# #         if echo $1 | grep '\....$' > /dev/null; then
# #             T=$1
# #         else
# #             T=$1.mkv
# #         fi
# #     fi
#
# #     # To list cams: v4l2-ctl --list-devices
# #     # Record screen 2 by default
# #     local screen=2
# #     local offset=""
# #     local heights=(`screenres 1 | awk -Fx '{print $2}'` `screenres 2 | awk -Fx '{print $2}'`)
# #     local bigger_height=$(echo $heights | sed "s/ /\n/" | sort -rg | line 1)
#
# #         [ $screen -eq 1 ] && offset="+0,$(( $bigger_height -  $(screenres 1 | awk -Fx '{print $2}')))"
# #         ffmpeg -f x11grab -framerate 60 -s $(screenres $screen) -i :0.0$offset \
# #             -f v4l2 -framerate 30 -video_size 640x480 -i /dev/video2 \
# #             -f pulse -sample_rate 44100 -i default \
# #             -filter_complex "overlay=main_w-overlay_w-2:main_h-overlay_h-2" \
# #             -c:v libx264 -preset ultrafast -crf 18 -c:a aac -b:a 320k $T
# # }
#
# # oscreencast() {
# #     if [ ! -z $1 ]; then
# #         ffmpeg -f x11grab -s $(xdpyinfo | grep dimensions | awk '{print $2}') -i :0.0 $1
# #     else
# #         echo "You need to precise an output file as first argument - eg 'example.mkv'"
# #     fi
# # }
#
# # # Run script to update Arch and others
# # updatesys() {
# #     sh $DOTFILES/update.sh
# # }
#
# # # Extract files
# # extract() {
# #     for file in "$@"
# #     do
# #         if [ -f $file ]; then
# #             _ex $file
# #         else
# #             echo "'$file' is not a valid file"
# #         fi
# #     done
# # }
#
# # # Extract files in their own directories
# # mkextract() {
# #     for file in "$@"
# #     do
# #         if [ -f $file ]; then
# #             local filename=${file%\.*}
# #             mkdir -p $filename
# #             cp $file $filename
# #             cd $filename
# #             _ex $file
# #             rm -f $file
# #             cd -
# #         else
# #             echo "'$1' is not a valid file"
# #         fi
# #     done
# # }
#
# # # Internal function to extract any file
# # _ex() {
# #     case $1 in
# #         *.tar.bz2)  tar xjf $1      ;;
# #         *.tar.gz)   tar xzf $1      ;;
# #         *.bz2)      bunzip2 $1      ;;
# #         *.gz)       gunzip $1       ;;
# #         *.tar)      tar xf $1       ;;
# #         *.tbz2)     tar xjf $1      ;;
# #         *.tgz)      tar xzf $1      ;;
# #         *.zip)      unzip $1        ;;
# #         *.7z)       7z x $1         ;; # require p7zip
# #         *.rar)      7z x $1         ;; # require p7zip
# #         *.iso)      7z x $1         ;; # require p7zip
# #         *.Z)        uncompress $1   ;;
# #         *)          echo "'$1' cannot be extracted" ;;
# #     esac
# # }
#
# # # Compress a file 
# # # TODO to improve to compress in any possible format
# # # TODO to improve to compress multiple files
# # compress() {
# #     local DATE="$(date +%Y%m%d-%H%M%S)"
# #     tar cvzf "$DATE.tar.gz" "$@"
# # }
#
# # # Take a screenshot
# # screenshot () {
# #     local DIR="$SCREENSHOT"
# #     local DATE="$(date +%Y%m%d-%H%M%S)"
# #     local NAME="${DIR}/screenshot-${DATE}.png"
#
# #     # Check if the dir to store the screenshots exists, else create it:
# #     if [ ! -d "${DIR}" ]; then mkdir -p "${DIR}"; fi
#
# #     # Screenshot a selected window
# #     if [ "$1" = "win" ]; then import -format png -quality 100 "${NAME}"; fi
#
# #     # Screenshot the entire screen
# #     if [ "$1" = "scr" ]; then import -format png -quality 100 -window root "${NAME}"; fi
#
# #     # Screenshot a selected area
# #     if [ "$1" = "area" ]; then import -format png -quality 100 "${NAME}"; fi
#
# #     if [[ $1 =~ "^[0-9].*x[0-9].*$" ]]; then import -format png -quality 100 -resize $1 "${NAME}"; fi
#
# #     if [[ $1 =~ "^[0-9]+$" ]]; then import -format png -quality 100 -resize $1 "${NAME}" ; fi
#
# #     if [[ $# = 0 ]]; then
# #         # Display a warning if no area defined
# #         echo "No screenshot area has been specified. Please choose between: win, scr, area. Screenshot not taken."
# #     fi
# # }
#
# # # Spit the size of images
# # imgsize() {
# #     for file in "$@"
# #     do
# #         local width=$(identify -format "%w" "$file")> /dev/null
# #         local height=$(identify -format "%h" "$file")> /dev/null
#
# #         echo -e "Size of $file: $width*$height"
# #     done
# # }
#
# # # Resize an image
# # # arg1: the file
# # # arg2: the width to resize
# # # arg3: modify the file in place
# # # Example: imgresize myimage.jpg 780 true
# # imgresize() {
# #     local filename=${1%\.*}
# #     local extension="${1##*.}"
# #     local separator="_"
# #     if [ ! -z $3 ]; then
# #         local finalName="$filename.$extension"
# #     else
# #         local finalName="$filename$separator$2.$extension"
# #     fi
# #     convert $1 -quality 100 -resize $2 $finalName
# #     echo "$finalName resized to $2"
# # }
#
# # Imgresize() {
# #     imgresize $1 $2 true
# # }
#
# # # Resize all images
# # # arg1: the extension of all images
# # # arg2: the width to resize
# # # arg3: modify the files in place
# # # Example: imgresizeall jpg 780 true
# # imgresizeall() {
# #     for f in *.${1}; do
# #         if [ ! -z $3 ]; then
# #             imgresize "$f" ${2} t
# #         else
# #             imgresize "$f" ${2}
# #         fi
# #     done
# # }
#
# # imginvert() {
# #     local filename=${1%\.*}
# #     local extension="${1##*.}"
# #     local separator="_"
# #     local invert="inverted"
# #     if [ ! -z $2 ]; then
# #         local finalName="$filename.$extension"
# #     else
# #         local finalName="$filename$separator$invert.$extension"
# #     fi
# #     convert $1 -channel RGB -negate $finalName
# #     echo "$finalName inverted"
# # }
#
# # imgoptimize() {
# #     local filename=${1%\.*}
# #     local extension="${1##*.}"
# #     local separator="_"
# #     local suffix="optimized"
# #     local finalName="$filename$separator$suffix.$extension"
# #     convert $1 -strip -interlace Plane -quality 85% $finalName
# #     echo "$finalName created"
# # }
#
# # Imgoptimize() {
# #     local filename=${1%\.*}
# #     local extension="${1##*.}"
# #     local separator="_"
# #     local suffix="optimized"
# #     local convert $1 -strip -interlace Plane -quality 85% $1
# #     echo "$1 created"
# # }
#
# # imgoptimizeall() {
# #     for f in *.${1}; do
# #         imgoptimize "$f"
# #     done
# # }
#
# # Imgoptimizeall() {
# #     for f in *.${1}; do
# #         Imgoptimize "$f"
# #     done
# # }
#
# # imgtojpg() {
# #     for file in "$@"
# #     do
# #         local filename=${file%\.*}
# #         convert -quality 100 $file "${filename}.jpg"
# #     done
# # }
#
# # imgtopng() {
# #     for file in "$@"
# #     do
# #         local filename=${file%\.*}
# #         convert -quality 100 $file "${filename}.png"
# #     done
# # }
#
# # imgtowebp() {
# #     for file in "$@"
# #     do
# #         local filename=${file%\.*}
# #         cwebp -q 100 $file -o $(basename ${filename}).webp
# #     done
# # }
#
# # gtrm() {
# #     git tag -d $1
#
# #     if [ ! -z "$2" ]; then
# #         git push $2 :refs/tags/$1
# #     else
# #         git push origin :refs/tags/$1
# #     fi
# # }
#
# # ssh-create() {
# #     if [ ! -z "$1" ]; then
# #         ssh-keygen -f $HOME/.ssh/$1 -t rsa -N '' -C "$1"
# #         chmod 700 $HOME/.ssh/$1*
# #     fi
# # }
#
# # dback () {
# #     if [ ! -z $1 ] && [ ! -z $2 ]; then
# #         if [ ! -z $3 ]; then
# #             BS=$3
# #         else
# #             BS="512k"
# #         fi
#
# #         dialog --defaultno --title "Are you sure?" --yesno "This will copy $1 to $2 (bitsize: $BS). Everything on $2 will be deleted.\n\n
# #         Are you sure?"  15 60 || exit
#
# #         (sudo pv -n $1 | sudo dd of=$2 bs=$BS conv=notrunc,noerror) 2>&1 | dialog --gauge "Backup from disk $1 to disk $2... please wait" 10 70 0
# #     else
# #         echo "You need to provide an input disk as first argument (i.e /dev/sda) and an output disk as second argument (i.e /dev/sdb)"
# #     fi
# # }
#
# # blimg() {
# #     if [ ! -z $1 ] && [ ! -z $2 ] && [ ! -z $3 ]; then
# #         local CYEAR=$(date +'%Y')
# #         local BASEDIR="${HOME}/workspace/webtechno/static"
# #         #Basedir current year
# #         local BASEDIRY="${HOME}/workspace/webtechno/static/${CYEAR}"
#
# #         if [ ! -d $BASEDIRY ]; then
# #             mkdir $BASEDIRY
# #         fi
#
# #         #basedir current article
# #         local BASEDIRC="${BASEDIRY}/${2}"
#
# #         if [ ! -d $BASEDIRP ]; then
# #             mkdir $BASEDIRP
# #         fi
#
# #         local IMGRESIZED=imgresize "${1} 780"
# #         echo "$IMGRESIZED"
# #     fi
# # }
#
# # postgdump() {
# #     local USER="postgres"
# #     local HOST="localhost"
# #     if [ ! -z $1 ]; then
# #         if [ -f "${1}.sql" ]; then
# #             rm -i "${1}.sql"
# #         fi
#
# #         if [ $# = 1 ]; then
# #             pg_dump -c -U $USER -h $HOST $1 | pv --progress > "${1}.sql"
# #             echo $1
# #         fi
#
# #         if [ $# = 2 ]; then
# #             pg_dump -c -U $2 -h $HOST $1 | pv --progress > "${1}.sql"
# #             echo $1
# #         fi
#
# #         if [ $# = 3 ]; then
# #             pg_dump -c -U $2 -h $3 $1 | pv --progress > "${1}.sql"
# #             echo $1
# #         fi
# #     fi
#
# #     if [ $# = 0 ]; then
# #         echo "You need at least to provide the database name"
# #     fi
# # }
#
# # postgimport() {
# #     local USER="postgres"
# #     local HOST="localhost"
# #     if [ ! -z $1 ]; then
# #         DB=${1%\.*}
# #         # sed -i "1s/^/CREATE DATABASE $DB;\n/" $1
# #         if [ $# = 1 ];
# #         then
# #             pv --progress ${1} | psql -U $USER -h $HOST $1 -d $DB
# #             echo $1
# #         fi
#
# #         if [ $# = 2 ]; then
# #             pv --progress ${1} | psql -U $1 -h $HOST $1 -d $DB
# #             echo $1
# #         fi
#
# #         if [ $# = 3 ]; then
# #             pv --progress ${1} | psql -U $1 -h $2 $1 -d $DB
# #             echo $1
# #         fi
# #     fi
#
# #     if [ $# = 0 ]; then
# #         echo "You need at least to provide the database name"
# #     fi
# # }
#
# # matrix () {
# #     local lines=$(tput lines)
# #     cols=$(tput cols)
#
# #     awkscript='
# #     {
# #         letters="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@#$%^&*()"
# #         lines=$1
# #         random_col=$3
# #         c=$4
# #         letter=substr(letters,c,1)
# #         cols[random_col]=0;
# #         for (col in cols) {
# #             line=cols[col];
# #             cols[col]=cols[col]+1;
# #             printf "\033[%s;%sH\033[2;32m%s", line, col, letter;
# #             printf "\033[%s;%sH\033[1;37m%s\033[0;0H", cols[col], col, letter;
# #             if (cols[col] >= lines) {
# #                 cols[col]=0;
# #             }
# #     }
# # }
# # '
#
# # echo -e "\e[1;40m"
# # clear
#
# # while :; do
# #     echo $lines $cols $(( $RANDOM % $cols)) $(( $RANDOM % 72 ))
# #     sleep 0.05
# # done | awk "$awkscript"
# # }
#
# # pgdump() {
# #     pg_dump -U postgres -h localhost x_loc_0bdf08de > pulsecheck_service_test.sql 
# # }
#
# # githeat() {
# #     $DOTFILES/bash/scripts/heatmap.sh
# # }
#
# # colorblocks() {
# #     $DOTFILES/bash/scripts/colorblocks.sh
# # }
#
# # colorcards() {
# #     $DOTFILES/bash/scripts/colorcards.sh
# # }
#
# # colors() {
# #     $DOTFILES/bash/scripts/colors.sh
# # }
#
# # pipes() {
# #     $DOTFILES/bash/scripts/pipes.sh
# # }
#
# # smedia() {
# #     $DOTFILES/bash/scripts/smedia.sh $@
# # }
#
# # mkcd() {
# #     local dir="$*";
# #     local mkdir -p "$dir" && cd "$dir";
# # }
#
# # mkcp() {
# #     local dir="$2"
# #     local tmp="$2"; tmp="${tmp: -1}"
# #     [ "$tmp" != "/" ] && dir="$(dirname "$2")"
# #     [ -d "$dir" ] ||
# #         mkdir -p "$dir" &&
# #         cp -r "$@"
# # }
#
# # mkmv() {
# #     local dir="$2"
# #     local tmp="$2"; tmp="${tmp: -1}"
# #     [ "$tmp" != "/" ] && dir="$(dirname "$2")"
# #     [ -d "$dir" ] ||
# #         mkdir -p "$dir" &&
# #         mv "$@"
# #     }
#
# # historystat() {
# #     history 0 | awk '{print $2}' | sort | uniq -c | sort -n -r | head
# # }
#
# # promptspeed() {
# #     for i in $(seq 1 10); do /usr/bin/time zsh -i -c exit; done
# # }
#
# # ports() {
# #     sudo netstat -tulpn | grep LISTEN | fzf;
# # }
#
# # mnt() {
# #     local FILE="/mnt/external"
# #     if [ ! -z $2 ]; then
# #         FILE=$2
# #     fi
#
# #     if [ ! -z $1 ]; then
# #         sudo mount "$1" "$FILE" -o rw
# #         echo "Device in read/write mounted in $FILE"
# #     fi
#
# #     if [ $# = 0 ]; then
# #         echo "You need to provide the device (/dev/sd*) - use lsblk"
# #     fi
# # }
#
# # umnt() {
# #     local DIRECTORY="/mnt"
# #     if [ ! -z $1 ]; then
# #         DIRECTORY=$1
# #     fi
# #     MOUNTED=$(grep $DIRECTORY /proc/mounts | cut -f2 -d" " | sort -r)
# #     cd "/mnt"
# #     sudo umount $MOUNTED
# #     echo "$MOUNTED unmounted"
# # }
#
# # mntmtp() {
# #     local DIRECTORY="$HOME/mnt"
# #     if [ ! -z $2 ]; then
# #         local DIRECTORY=$2
# #     fi
# #     if [ ! -d $DIRECTORY ]; then
# #         mkdir $DIRECTORY
# #     fi
#
# #     if [ ! -z $1 ]; then
# #         simple-mtpfs --device "$1" "$DIRECTORY"
# #         echo "MTPFS device in read/write mounted in $DIRECTORY"
# #     fi
#
# #     if [ $# = 0 ]; then
# #         echo "You need to provide the device number - use simple-mtpfs -l"
# #     fi
# # }
#
# # umntmtp() {
# #     local DIRECTORY="$HOME/mnt"
# #     if ; then
# #         DIRECTORY=$1
# #     fi
# #     cd $HOME
# #     umount $DIRECTORY
# #     echo "$DIRECTORY with mtp filesystem unmounted"
# # }
#
# # # Silly little script to understand zstyle
# # names() {
# #     local user_name user_surname user_nickname computer_name
#
# #     zstyle -s ':name:' set_user_name user_name || user_name="LEELA"
# #     zstyle -s ':name:surname:' set_user_name user_surname || user_surname="TURANGA"
# #     zstyle -s ':name:nickname::' set_user_name user_nickname || user_nickname="CYCLOPE"
# #     zstyle -s ':name:' set_computer_name computer_name || computer_name="BENDER"
#
# #     echo "You're $user_name $user_surname $user_nickname and you're computer is called $computer_name"
# # }
#
# # # --restrict-filenames replace special characters like spaces in filenames.
# # ydlp() {
# #     if ; then
# #         youtube-dl --restrict-filenames -f 22 -o "%(autonumber)s-%(title)s.%(ext)s" "$1"
# #     else
# #         echo "You need to specify a playlist url as argument"
# #     fi
# # }
#
# # ydl() {
# #     if [ ! -z $1 ]; then
# #         youtube-dl --restrict-filenames -f 22 -o "%(title)s.%(ext)s" "$1"
# #     else
# #         echo "You need to specify a video url as argument"
# #     fi
# # }
#
# # initKondo() {
# #     mkdir .clj-kondo
# #     clj-kondo --lint "$(boot with-cp -w -f -)"
# # }
#
# # vinfo() {
# #     vim -c "Vinfo $1" -c 'silent only'
# # }
#
# # zshcomp() {
# #     for command completion in ${(kv)_comps:#-*(-|-,*)}
# #     do
# #         printf "%-32s %s\n" $command $completion
# #     done | sort
# # }
#
# # wav2flac() {
# #     for file in "$@"; do
# #         local filename=${file%\.*}
# #         local extension="${file##*.}"
# #         ffmpeg -i "$filename.wav" -af aformat=s32:176000 "$filename.flac"
# #     done
# # }
#
# # rmwav2flac() {
# #     for file in "$@"; do
# #         local filename=${file%\.*}
# #         local extension="${file##*.}"
# #         ffmpeg -i "$filename.wav" -af aformat=s32:176000 "$filename.flac"
# #         rm -f $file
# #     done
# # }
#
# # freetouch() {
# #     touch $1.mm
# #     cat <<EOF > $1.mm
# # <map version="1.0.1">
# # <!-- To view this file, download free mind mapping software FreeMind from http://freemind.sourceforge.net -->
# # <node TEXT="Title"/>
# # </map>
# # EOF
# # }
#
# # duckduckgo() {
# #     lynx -vikeys -accept_all_cookies "https://lite.duckduckgo.com/lite/?q=$@"
# # }
#
# # wikipedia() {
# #     lynx -vikeys -accept_all_cookies "https://en.wikipedia.org/wiki?search=$@"
# # }
#
#
#
# # # Count number of words in my blog for a given year
# # blogwc() {
# #     DATE=$(date +"%Y")
# #     if [ ! -z $1 ]; then
# #         DATE=$1
# #     fi
# #     cd ~/workspace/webtechno/content/post && grep -l "date = \"$DATE" *.md | xargs wc && cd -
# # }
#
# # cheat() {
# #     curl cheat.sh/$1
# # }
#
# # touchproject(){
# #     if [ -z $1 ];then
# #         echo "You need to pass a project name"
# #     else
# #         local project=$1
# #         cd "$CLOUD/project_management/"
# #         taskell $project
# #         cd -
# #     fi
# # }
#
# # vimgolf() {
# #     local ID=$1
# #     local key=$2
# #     if [ -z $2 ]; then
# #         key=$VIM_GOLF_KEY
# #     fi
# #     docker run --rm  --net=host -it -e "key=[$VIM_GOLF_KEY]" kramos/vimgolf "$ID"
# # }
#
# # fm() {
# #     local -r file=$1
# #     freemind $file &> /dev/null &
# # }
#
# # back() {
# #     for file in "$@"; do
# #         cp "$file" "$file".bak
# #     done
# # }
#
# # calcul() {
# #     bc -l <<< "$@"
# # }
#
# # jrnl() {
# #     cd "$JRNL" && vim +Jrnl
# # }
#
# # tiny() {
# #     local URL=${1:?}
# #     curl -s "http://tinyurl.com/api-create.php?url=$1"
# # }
#
# # serve() {
# #     local -r PORT=${1:-8888}
# #     python2 -m SimpleHTTPServer "$PORT"
# # }
#
# # kubecfg() {
# #     . "$DOTFILES_CLOUD/kubecfg.sh"
# # }
#
# # scratchpad() {
# #     "$DOTFILES/bash/scripts/scratchpad.sh" "$@"
# # }
#
# # git-jump() {
# #     "$DOTFILES/bash/scripts/git-jump.sh" "$@"
# # }
#
# # # Rename music files automatically depending of their tags (mp3/ogg/flac)
# # mvtag() {
# #     local option=$1
# #     shift
#
# #     lltag --yes "$option" -R --rename-regexp "s/[\'?,\[\]\.\(\):]//" --rename-regexp "s/_-_/-/" --rename-min --rename-sep '_' --rename "%P%n-%t" "$@"
# # }
#
# # reposize() {
# #   url=`echo $1 \
# #     | perl -pe 's#(?:https?://github.com/)([\w\d.-]+\/[\w\d.-]+).*#\1#g' \
# #     | perl -pe 's#git\@github.com:([\w\d.-]+\/[\w\d.-]+)\.git#\1#g'
# #   `
# #   printf "https://github.com/$url => "
# #   curl -s https://api.github.com/repos/$url \
# #   | jq '.size' \
# #   | numfmt --to=iec --from-unit=1024
# # }
#
# # # Disable the native keyboard for my TUXEDO laptop
# # -keyb() {
# #     xinput disable $(xinput list | grep -i "at translated set" | awk '{print $7}' | sed 's/id=//')
# # }
#
# # # Enable the native keyboard for my TUXEDO laptop
# # keyb() {
# #     xinput enable $(xinput list | grep -i "at translated set" | awk '{print $7}' | sed 's/id=//')
# # }
#
# # # Enable native pad for my Tuxedo laptop
# # pad() {
# #     xinput enable $(xinput list | grep -i "touchpad" | awk '{print $6}' | sed 's/id=//')
# # }
#
# # # Disable native pad for my Tuxedo laptop
# # -pad() {
# #     xinput disable $(xinput list | grep -i "touchpad" | awk '{print $6}' | sed 's/id=//')
# # }
#
# # # Launch a program in a terminal without getting any output,
# # # and detache the process from terminal
# # # (can then close the terminal without terminating process)
# # -echo() {
# #     "$@" &> /dev/null & disown
# # }
#
# # # Generate a password - default 20 characters
# # pass() {
# #     local size=${1:-20}
# #     cat /dev/random | tr -dc '[:graph:]' | head -c$size
# # }
#
# # # Generate a m3u files with same filename as directories passed as arguments.
# # # The file is written with all files in each arg.
# # # Example: cm3u Xenogears
# # # Create a file 'Xenogears.m3u' and inside for example 'Xenogears/Xenogears The Game.bin'
# # cm3u() {
# #     for file in "$@"
# #     do
# #         if [ -d $file ]; then
# #             m3u="$file.m3u"
# #             find "$file" -type f > "$m3u"
# #         else
# #             echo "'$file' should be the directory where all your files are"
# #         fi
# #     done
# # }
#
# # backup() {
# #     "$DOTFILES/bash/scripts/backup/backup.sh" "-x" "$@" "$DOTFILES_CLOUD/backup/dir.csv"
# # }
#
# # # Transfer all ROMS to my rg35xx handheld console
# # roms2gb() {
# #     "$DOTFILES/bash/scripts/backup/backup.sh" "$@" "$DOTFILES_CLOUD/backup/roms.csv"
# #     cp /home/hypnos/Games/emulators/console/nes/roms/hacks/* /run/media/hypnos/ROMS/FC
# #     cp /home/hypnos/Games/emulators/console/snes/roms/hacks/* /run/media/hypnos/ROMS/SFC
# #     cp /home/hypnos/Games/emulators/console/megadrive/roms/hacks/* /run/media/hypnos/ROMS/MD
# #     cp /home/hypnos/Games/emulators/console/gba/roms/hacks/* /run/media/hypnos/ROMS/GBA
# #     cp /home/hypnos/Games/emulators/console/gb/roms/hacks/* /run/media/hypnos/ROMS/GB
# # }
#
# # gitam() {
# #     LC_ALL=C GIT_COMMITTER_DATE="$(date)" git commit --amend --no-edit --date "$(date)"
# # }
#
# # pom() {
# #     local -r HOURS=${1:?}
# #     local -r MINUTES=${2:-0}
# #     local -r POMODORO_DURATION=${3:-25}
#
# #     bc <<< "(($HOURS * 60) + $MINUTES) / $POMODORO_DURATION"
# # }
#
#
#
#
#
# #############################################
# # TODO: scripts + aliases + refactor FZF
# #############################################
#
# #
# # EXAMPLES
# #        abbr gco="git checkout"
# #
# #               "gco" will be expanded as "git checkout" when it is the first word in the command, in all open and future sessions.
# #
# #        abbr -g gco="git checkout"
# #
# #               "gco" will be replaced with "git checkout" anywhere on the line, in all open and future sessions.
# #
# #        abbr -g -S gco="git checkout"
# #
# #               "gco" will be replaced with "git checkout" anywhere on the line, in the current session.
# #
# #        abbr e -S -g gco;
# #
# #               Erase the global session abbreviation "gco". Note that because expansion is triggered by [SPACE] and [ENTER], the semicolon (;) is necessary to prevent expansion when
# #               operating on global abbreviations.
# #
# #        abbr e -g gco;
# #
# #               Erase the global user abbreviation "gco".
# #
# #        abbr e gco
# #
# #               Erase the regular user abbrevation "gco".
# #
# #        abbr R -g gco gch
# #
# #               Rename an existing global user abbreviation from "gco" to "gch".
#
# # # +-----+
# # # | Git |
# # # +-----+
#
# # function fgf() {
# # 	local -r prompt_add="Add > "
# # 	local -r prompt_reset="Reset > "
#
# # 	local -r git_root_dir=$(git rev-parse --show-toplevel)
# # 	local -r git_unstaged_files="git ls-files --modified --deleted --other --exclude-standard --deduplicate $git_root_dir"
#
# # 	local git_staged_files='git status --short | grep "^[A-Z]" | awk "{print \$NF}"'
#
# # 	local -r git_reset="git reset -- {+}"
# # 	local -r enter_cmd="($git_unstaged_files | grep {} && git add {+}) || $git_reset"
#
# # 	local -r preview_status_label="[ Status ]"
# # 	local -r preview_status="git status --short"
#
# # 	local -r header=$(cat <<-EOF
# # 		> CTRL-S to switch between Add Mode and Reset mode
# # 		> CTRL_T for status preview | CTRL-F for diff preview | CTRL-B for blame preview
# # 		> ALT-E to open files in your editor
# # 		> ALT-C to commit | ALT-A to append to the last commit
# # 		EOF
# # 	)
#
# # 	local -r add_header=$(cat <<-EOF
# # 		$header
# # 		> ENTER to add files
# # 		> ALT-P to add patch
# # 	EOF
# # 	)
#
# # 	local -r reset_header=$(cat <<-EOF
# # 		$header
# # 		> ENTER to reset files
# # 		> ALT-D to reset and checkout files
# # 	EOF
# # 	)
#
# # 	local -r mode_reset="change-prompt($prompt_reset)+reload($git_staged_files)+change-header($reset_header)+unbind(alt-p)+rebind(alt-d)"
# # 	local -r mode_add="change-prompt($prompt_add)+reload($git_unstaged_files)+change-header($add_header)+rebind(alt-p)+unbind(alt-d)"
#
# # 	eval "$git_unstaged_files" | fzf \
# # 	--multi \
# # 	--reverse \
# # 	--no-sort \
# # 	--prompt="Add > " \
# # 	--preview-label="$preview_status_label" \
# # 	--preview="$preview_status" \
# # 	--header "$add_header" \
# # 	--header-first \
# # 	--bind='start:unbind(alt-d)' \
# # 	--bind="ctrl-t:change-preview-label($preview_status_label)" \
# # 	--bind="ctrl-t:+change-preview($preview_status)" \
# # 	--bind='ctrl-f:change-preview-label([ Diff ])' \
# # 	--bind='ctrl-f:+change-preview(git diff --color=always {} | sed "1,4d")' \
# # 	--bind='ctrl-b:change-preview-label([ Blame ])' \
# # 	--bind='ctrl-b:+change-preview(git blame --color-by-age {})' \
# # 	--bind="ctrl-s:transform:[[ \$FZF_PROMPT =~ '$prompt_add' ]] && echo '$mode_reset' || echo '$mode_add'" \
# # 	--bind="enter:execute($enter_cmd)" \
# # 	--bind="enter:+reload([[ \$FZF_PROMPT =~ '$prompt_add' ]] && $git_unstaged_files || $git_staged_files)" \
# # 	--bind="enter:+refresh-preview" \
# # 	--bind='alt-p:execute(git add --patch {+})' \
# # 	--bind="alt-p:+reload($git_unstaged_files)" \
# # 	--bind="alt-d:execute($git_reset && git checkout {+})" \
# # 	--bind="alt-d:+reload($git_staged_files)" \
# # 	--bind='alt-c:execute(git commit)+abort' \
# # 	--bind='alt-a:execute(git commit --amend)+abort' \
# # 	--bind='alt-e:execute(${EDITOR:-vim} {+})' \
# # 	--bind='f1:toggle-header' \
# # 	--bind='f2:toggle-preview' \
# # 	--bind='ctrl-y:preview-up' \
# # 	--bind='ctrl-e:preview-down' \
# # 	--bind='ctrl-u:preview-half-page-up' \
# # 	--bind='ctrl-d:preview-half-page-down'
# # }
#
# # function fgc() {
# # 	local -r git_log=$(cat <<-EOF
# # 		git log --graph --color --format="%C(white)%h - %C(green)%cs - %C(blue)%s%C(red)%d"
# # 	EOF
# # 	)
#
# # 	local -r git_log_all=$(cat <<-EOF
# # 		git log --all --graph --color --format="%C(white)%h - %C(green)%cs - %C(blue)%s%C(red)%d"
# # 	EOF
# # 	)
#
#
# # 	local get_hash
# # 	read -r -d '' get_hash <<-'EOF'
# # 		echo {} | grep -o "[a-f0-9]\{7\}" | sed -n "1p"
# # 	EOF
#
# # 	local -r git_show="[[ \$($get_hash) != '' ]] && git show --color \$($get_hash)"
# # 	local -r git_show_subshell=$(cat <<-EOF
# # 		[[ \$($get_hash) != '' ]] && sh -c "git show --color \$($get_hash) | less -R"
# # 	EOF
# # 	)
#
# # 	local -r git_checkout="[[ \$($get_hash) != '' ]] && git checkout \$($get_hash)"
# # 	local -r git_reset="[[ \$($get_hash) != '' ]] && git reset \$($get_hash)"
# # 	local -r git_rebase_interactive="[[ \$($get_hash) != '' ]] && git rebase --interactive \$($get_hash)"
# # 	local -r git_cherry_pick="[[ \$($get_hash) != '' ]] && git cherry-pick \$($get_hash)"
#
# # 	local -r header=$(cat <<-EOF
# # 		> ENTER to display the diff with less
# # 	EOF
# # 	)
#
# # 	local -r header_branch=$(cat <<-EOF
# # 		$header
# # 		> CTRL-S to switch to All Commits mode
# # 		> ALT-C to checkout the commit | ALT-R to reset to the commit
# # 		> ALT-I to rebase interactively until the commit
# # 	EOF
# # 	)
#
# # 	local -r header_all=$(cat <<-EOF
# # 		$header
# # 		> CTRL-S to switch to Branch Commits mode
# # 		> ALT-P to cherry pick
# # 	EOF
# # 	)
#
# # 	local -r reset_header=$(cat <<-EOF
# # 		$header
# # 		> ENTER to reset files
# # 		> ALT-D to reset and checkout files
# # 	EOF
# # 	)
#
# # 	local -r branch_prompt='Branch > '
# # 	local -r all_prompt='All > '
#
# # 	local -r mode_all="change-prompt($all_prompt)+reload($git_log_all)+change-header($header_all)+unbind(alt-c)+unbind(alt-r)+unbind(alt-i)+rebind(alt-p)"
# # 	local -r mode_branch="change-prompt($branch_prompt)+reload($git_log)+change-header($header_branch)+rebind(alt-c)+rebind(alt-r)+rebind(alt-i)+unbind(alt-p)"
#
# # 	eval "$git_log" | fzf \
# # 		--ansi \
# # 		--reverse \
# # 		--no-sort \
# # 		--prompt="$branch_prompt" \
# # 		--header-first \
# # 		--header="$header_branch" \
# # 		--preview="$git_show" \
# # 		--bind='start:unbind(alt-p)' \
# # 		--bind="ctrl-s:transform:[[ \$FZF_PROMPT =~ '$branch_prompt' ]] && echo '$mode_all' || echo '$mode_branch'" \
# # 		--bind="enter:execute($git_show_subshell)" \
# # 		--bind="alt-c:execute($git_checkout)+abort" \
# # 		--bind="alt-r:execute($git_reset)+abort" \
# # 		--bind="alt-i:execute($git_rebase_interactive)+abort" \
# # 		--bind="alt-p:execute($git_cherry_pick)+abort" \
# # 		--bind='f1:toggle-header' \
# # 		--bind='f2:toggle-preview' \
# # 		--bind='ctrl-y:preview-up' \
# # 		--bind='ctrl-e:preview-down' \
# # 		--bind='ctrl-u:preview-half-page-up' \
# # 		--bind='ctrl-d:preview-half-page-down'
# # }
#
#
# # function fgb() {
# # 	local -r git_branches="git branch --all --color --format=$'%(HEAD) %(color:yellow)%(refname:short)\t%(color:green)%(committerdate:short)\t%(color:blue)%(subject)' | column --table --separator=$'\t'"
# # 	local -r get_selected_branch='echo {} | sed "s/^[* ]*//" | awk "{print \$1}"'
# # 	local -r git_log="git log \$($get_selected_branch) --graph --color --format='%C(white)%h - %C(green)%cs - %C(blue)%s%C(red)%d'"
# # 	local -r git_diff='git diff --color $(git branch --show-current)..$(echo {} | sed "s/^[* ]*//" | awk "{print \$1}")'
# # 	local -r git_show_subshell=$(cat <<-EOF
# # 		[[ \$($get_selected_branch) != '' ]] && sh -c "git show --color \$($get_selected_branch) | less -R"
# # 	EOF
# # 	)
# # 	local -r header=$(cat <<-EOF
# # 	> ALT-M to merge with current * branch | ALT-R to rebase with current * branch
# # 	> ALT-C to checkout the branch
# # 	> ALT-D to delete the merged local branch | ALT-X to force delete the local branch
# # 	> ENTER to open the diff with less
# # 	EOF
# # 	)
#
# # 	eval "$git_branches" \
# # 	| fzf \
# # 		--ansi \
# # 		--reverse \
# # 		--no-sort \
# # 		--preview-label '[ Commits ]' \
# # 		--preview "$git_log" \
# # 		--header-first \
# # 		--header="$header" \
# # 		--bind="alt-c:execute(git checkout \$($get_selected_branch))" \
# # 		--bind="alt-c:+reload($git_branches)" \
# # 		--bind="alt-m:execute(git merge \$($get_selected_branch))" \
# # 		--bind="alt-r:execute(git rebase \$($get_selected_branch))" \
# # 		--bind="alt-d:execute(git branch --delete \$($get_selected_branch))" \
# # 		--bind="alt-d:+reload($git_branches)" \
# # 		--bind="alt-x:execute(git branch --delete --force \$($get_selected_branch))" \
# # 		--bind="alt-x:+reload($git_branches)" \
# # 		--bind="enter:execute($git_show_subshell)" \
# # 		--bind='ctrl-f:change-preview-label([ Diff ])' \
# # 		--bind="ctrl-f:+change-preview($git_diff)" \
# # 		--bind='ctrl-i:change-preview-label([ Commits ])' \
# # 		--bind="ctrl-i:+change-preview($git_log)" \
# # 		--bind='f1:toggle-header' \
# # 		--bind='f2:toggle-preview' \
# # 		--bind='ctrl-y:preview-up' \
# # 		--bind='ctrl-e:preview-down' \
# # 		--bind='ctrl-u:preview-half-page-up' \
# # 		--bind='ctrl-d:preview-half-page-down'
# # }
#
# # # +--------+
# # # | Pacman |
# # # +--------+
#
# # # TODO can improve that with a bind to switch to what was installed
# # fpac() {
# #     pacman -Slq | fzf --multi --reverse --preview 'pacman -Si {1}' | xargs -ro sudo pacman -S
# # }
#
# # fyay() {
# #     yay -Slq | fzf --multi --reverse --preview 'yay -Si {1}' | xargs -ro yay -S
# # }
#
# # # +------+
# # # | tmux |
# # # +------+
#
# # fmux() {
# #     prj=$(find $XDG_CONFIG_HOME/tmuxp/ -execdir bash -c 'basename "${0%.*}"' {} ';' | sort | uniq | nl | fzf | cut -f 2)
# #     echo $prj
# #     [ -n "$prj" ] && tmuxp load $prj
# # }
#
# # # ftmuxp - propose every possible tmuxp session
# # ftmuxp() {
# #     if [[ -n $TMUX ]]; then
# #         return
# #     fi
#
# #     # get the IDs
# #     ID="$(ls $XDG_CONFIG_HOME/tmuxp | sed -e 's/\.yml$//')"
# #     if [[ -z "$ID" ]]; then
# #         tmux new-session
# #     fi
#
# #     create_new_session="Create New Session"
#
# #     ID="${create_new_session}\n$ID"
# #     ID="$(echo $ID | fzf | cut -d: -f1)"
#
# #     if [[ "$ID" = "${create_new_session}" ]]; then
# #         tmux new-session
# #     elif [[ -n "$ID" ]]; then
# #         # Change name of urxvt tab to session name
# #         printf '\033]777;tabbedx;set_tab_name;%s\007' "$ID"
# #         tmuxp load "$ID"
# #     fi
# # }
#
# # # ftmux - help you choose tmux sessions
# # ftmux() {
# #     if [[ ! -n $TMUX ]]; then
# #         # get the IDs
# #         ID="`tmux list-sessions`"
# #         if [[ -z "$ID" ]]; then
# #             tmux new-session
# #         fi
# #         create_new_session="Create New Session"
# #         ID="$ID\n${create_new_session}:"
# #         ID="`echo $ID | fzf | cut -d: -f1`"
# #         if [[ "$ID" = "${create_new_session}" ]]; then
# #             tmux new-session
# #         elif [[ -n "$ID" ]]; then
# #             printf '\033]777;tabbedx;set_tab_name;%s\007' "$ID"
# #             tmux attach-session -t "$ID"
# #         else
# #             :  # Start terminal normally
# #         fi
# #     fi
# # }
#
# # # +-------+
# # # | Other |
# # # +-------+
#
# # # List install files for dotfiles
# # fdot() {
# #     file=$(find "$DOTFILES/install" -exec basename {} ';' | sort | uniq | nl | fzf | cut -f 2)
# #     [ -n "$file" ] && "$EDITOR" "$DOTFILES/install/$file"
# # }
#
# # # List projects
# # fwork() {
# #     result=$(find ~/workspace/* -type d -prune -exec basename {} ';' | sort | uniq | nl | fzf | cut -f 2)
# #     [ -n "$result" ] && cd ~/workspace/$result
# # }
#
# # # Open pdf with Zathura
# # fpdf() {
# #     result=$(find -type f -name '*.pdf' | fzf --bind "ctrl-r:reload(find -type f -name '*.pdf')" --preview "pdftotext {} - | less")
# #     [ -n "$result" ] && nohup zathura "$result" &> /dev/null & disown
# # }
#
# # # Open epubs with Zathura
# # fepub() {
# #     result=$(find -type f -name '*.epub' | fzf --bind "ctrl-r:reload(find -type f -name '*.epub')")
# #     [ -n "$result" ] && nohup zathura "$result" &> /dev/null & disown
# # }
#
# # # Open freemind mindmap
# # fmind() {
# #     local folders=("$CLOUD/knowledge_base" "$WORKSPACE/alexandria")
#
# #     files=""
# #     for root in ${folders[@]}; do
# #         files="$files $(find $root -name '*.mm')"
# #     done
# #     result=$(echo "$files" | fzf -m --height 60% --border sharp | tr -s "\n" " ")
# #     [ -n "$result" ] && nohup freemind $(echo $result) &> /dev/null & disown
# # }
#
# # # List tracking spreadsheets (productivity, money ...)
# # ftrack() {
# #     file=$(ls $CLOUD/tracking/**/*.{ods,csv} | fzf) || return
# #     [ -n "$file" ] && libreoffice "$file" &> /dev/null &
# # }
#
# # # Search and find directories in the dir stack
# # fpop() {
# #     # Only work with alias d defined as:
#     
# #     # alias d='dirs -v'
# #     # for index ({1..9}) alias "$index"="cd +${index}"; unset index
#
# #     d | fzf --height="20%" | cut -f 1 | source /dev/stdin
# # }
#
# # # Find in File using ripgrep
# # fif() {
# #   if [ ! "$#" -gt 0 ]; then return 1; fi
# #   rg --files-with-matches --no-messages "$1" \
# #       | fzf --preview "highlight -O ansi -l {} 2> /dev/null \
# #       | rg --colors 'match:bg:yellow' --ignore-case --pretty --context 10 '$1' \
# #       || rg --ignore-case --pretty --context 10 '$1' {}"
# # }
#
# # # Find in file using ripgrep-all
# # fifa() {
# #     if [ ! "$#" -gt 0 ]; then return 1; fi
# #     local file
# #     file="$(rga --max-count=1 --ignore-case --files-with-matches --no-messages "$*" \
# #         | fzf-tmux -p +m --preview="rga --ignore-case --pretty --context 10 '"$*"' {}")" \
# #         && print -z "./$file" || return 1;
# # }
#
# # # Search through all man pages
# # function fman() {
# #     man -k . | fzf -q "$1" --prompt='man> '  --preview $'echo {} | tr -d \'()\' | awk \'{printf "%s ", $2} {print $1}\' | xargs -r man' | tr -d '()' | awk '{printf "%s ", $2} {print $1}' | xargs -r man
# # }
#
#
#
# # zsh
# #############
# # oh-my-zsh NOTES
# #
# # Set personal aliases, overriding those provided by Oh My Zsh libs,
# # plugins, and themes. Aliases can be placed here, though Oh My Zsh
# # users are encouraged to define aliases within a top-level file in
# # the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# # - $ZSH_CUSTOM/aliases.zsh
# # - $ZSH_CUSTOM/macos.zsh
# # For a full list of active aliases, run `alias`.
# #
# # Example aliases
# # alias zshconfig="mate ~/.zshrc"
# #############################################
#
,#######################
# Docs - https://ghostty.org/docs/
#
# The syntax is "key = value". The whitespace around the equals doesn't matter.
# Comments start with a `#` and are only valid on their own line.
# Blank lines are ignored!
# Empty values reset the configuration to the default value (font-family = )
########################
# To view default configuration with documentation:
# $ ghostty +show-config --default --docs
########################

###########################
# General
###########################

# Default theme. (can be separated light/dark -> light:nord-light,dark:nord)
# favorites - [zenbones, nord, nord-light, catppuccin-frappe]
theme = catppuccin-frappe

# Automatically download updates.
auto-update = download

# Font size in points.
font-size = 12

# Start new windows in fullscreen.
fullscreen = false

# Map macOS Option key as Alt.
macos-option-as-alt = true

# Enable non-native macOS fullscreen.
macos-non-native-fullscreen = true

# Save window state persistently.
window-save-state = always

# New windows inherit the working directory.
window-inherit-working-directory = true

# Disable confirmation prompt when closing.
confirm-close-surface = false

# Disable hiding the mouse while typing.
mouse-hide-while-typing = false

# Allow clipboard read access.
clipboard-read = allow

# Allow clipboard write access.
clipboard-write = allow

###########################
# Window Appearance
###########################
# Disable window decorations.
window-decoration = false

# Horizontal window padding.
window-padding-x = 12

# Vertical window padding.
window-padding-y = 12

###########################
# Cursor Settings
###########################
# Cursor style: block, underline, or beam.
cursor-style = block

# Disable cursor blinking.
cursor-style-blink = false

###########################
# Quick Terminal Settings
###########################
# Quick terminal position: center, top, bottom, left, right.
quick-terminal-position = center

# Screen where the quick terminal appears.
quick-terminal-screen = main

# Animation duration for quick terminal (in seconds).
quick-terminal-animation-duration = 0

###########################
# Shell Integration
###########################
# Shell integration with Zsh.
shell-integration = zsh

# Enable cursor features for shell integration.
shell-integration-features = cursor

###########################
# Keybindings
###########################
# Format: keybind = trigger=action
# Full list of mappable keys: https://github.com/ghostty-org/ghostty/blob/d6e76858164d52cff460fedc61ddf2e560912d71/src/input/key.zig#L255

# Open configuration file.
keybind = cmd+comma=open_config

# Reload configuration file.
keybind = cmd+shift+comma=reload_config

# Toggle inspector.
keybind = cmd+opt+i=inspector:toggle

# Toggle fullscreen mode.
keybind = cmd+enter=toggle_fullscreen

# Toggle quick terminal globally.
keybind = global:cmd+=toggle_quick_terminal

# Toggle quick terminal.
keybind = cmd+period=toggle_quick_terminal

###########################
# Additional Notes
###########################
# Available themes:
# Light: zenbones, nord-light
# Dark: catppuccin-frappe, nord
# Example: theme = light:nord-light,dark:nord
########################
//
// THIS FILE WAS AUTOGENERATED BY ZELLIJ, THE PREVIOUS FILE AT THIS LOCATION WAS COPIED TO: /Users/hank/.config/zellij/config.kdl.bak
//

keybinds clear-defaults=true {
    locked {
        bind "Ctrl g" { SwitchToMode "normal"; }
    }
    pane {
        bind "left" { MoveFocus "left"; }
        bind "down" { MoveFocus "down"; }
        bind "up" { MoveFocus "up"; }
        bind "right" { MoveFocus "right"; }
        bind "c" { SwitchToMode "renamepane"; PaneNameInput 0; }
        bind "d" { NewPane "down"; SwitchToMode "normal"; }
        bind "e" { TogglePaneEmbedOrFloating; SwitchToMode "normal"; }
        bind "f" { ToggleFocusFullscreen; SwitchToMode "normal"; }
        bind "h" { MoveFocus "left"; }
        bind "j" { MoveFocus "down"; }
        bind "k" { MoveFocus "up"; }
        bind "l" { MoveFocus "right"; }
        bind "n" { NewPane; SwitchToMode "normal"; }
        bind "p" { SwitchFocus; }
        bind "Ctrl p" { SwitchToMode "normal"; }
        bind "r" { NewPane "right"; SwitchToMode "normal"; }
        bind "w" { ToggleFloatingPanes; SwitchToMode "normal"; }
        bind "z" { TogglePaneFrames; SwitchToMode "normal"; }
    }
    tab {
        bind "left" { GoToPreviousTab; }
        bind "down" { GoToNextTab; }
        bind "up" { GoToPreviousTab; }
        bind "right" { GoToNextTab; }
        bind "1" { GoToTab 1; SwitchToMode "normal"; }
        bind "2" { GoToTab 2; SwitchToMode "normal"; }
        bind "3" { GoToTab 3; SwitchToMode "normal"; }
        bind "4" { GoToTab 4; SwitchToMode "normal"; }
        bind "5" { GoToTab 5; SwitchToMode "normal"; }
        bind "6" { GoToTab 6; SwitchToMode "normal"; }
        bind "7" { GoToTab 7; SwitchToMode "normal"; }
        bind "8" { GoToTab 8; SwitchToMode "normal"; }
        bind "9" { GoToTab 9; SwitchToMode "normal"; }
        bind "[" { BreakPaneLeft; SwitchToMode "normal"; }
        bind "]" { BreakPaneRight; SwitchToMode "normal"; }
        bind "b" { BreakPane; SwitchToMode "normal"; }
        bind "h" { GoToPreviousTab; }
        bind "j" { GoToNextTab; }
        bind "k" { GoToPreviousTab; }
        bind "l" { GoToNextTab; }
        bind "n" { NewTab; SwitchToMode "normal"; }
        bind "r" { SwitchToMode "renametab"; TabNameInput 0; }
        bind "s" { ToggleActiveSyncTab; SwitchToMode "normal"; }
        bind "Ctrl t" { SwitchToMode "normal"; }
        bind "x" { CloseTab; SwitchToMode "normal"; }
        bind "tab" { ToggleTab; }
    }
    resize {
        bind "left" { Resize "Increase left"; }
        bind "down" { Resize "Increase down"; }
        bind "up" { Resize "Increase up"; }
        bind "right" { Resize "Increase right"; }
        bind "+" { Resize "Increase"; }
        bind "-" { Resize "Decrease"; }
        bind "=" { Resize "Increase"; }
        bind "H" { Resize "Decrease left"; }
        bind "J" { Resize "Decrease down"; }
        bind "K" { Resize "Decrease up"; }
        bind "L" { Resize "Decrease right"; }
        bind "h" { Resize "Increase left"; }
        bind "j" { Resize "Increase down"; }
        bind "k" { Resize "Increase up"; }
        bind "l" { Resize "Increase right"; }
        bind "Ctrl n" { SwitchToMode "normal"; }
    }
    move {
        bind "left" { MovePane "left"; }
        bind "down" { MovePane "down"; }
        bind "up" { MovePane "up"; }
        bind "right" { MovePane "right"; }
        bind "h" { MovePane "left"; }
        bind "Ctrl h" { SwitchToMode "normal"; }
        bind "j" { MovePane "down"; }
        bind "k" { MovePane "up"; }
        bind "l" { MovePane "right"; }
        bind "n" { MovePane; }
        bind "p" { MovePaneBackwards; }
        bind "tab" { MovePane; }
    }
    scroll {
        bind "Alt left" { MoveFocusOrTab "left"; SwitchToMode "normal"; }
        bind "Alt down" { MoveFocus "down"; SwitchToMode "normal"; }
        bind "Alt up" { MoveFocus "up"; SwitchToMode "normal"; }
        bind "Alt right" { MoveFocusOrTab "right"; SwitchToMode "normal"; }
        bind "e" { EditScrollback; SwitchToMode "normal"; }
        bind "Alt h" { MoveFocusOrTab "left"; SwitchToMode "normal"; }
        bind "Alt j" { MoveFocus "down"; SwitchToMode "normal"; }
        bind "Alt k" { MoveFocus "up"; SwitchToMode "normal"; }
        bind "Alt l" { MoveFocusOrTab "right"; SwitchToMode "normal"; }
        bind "s" { SwitchToMode "entersearch"; SearchInput 0; }
    }
    search {
        bind "c" { SearchToggleOption "CaseSensitivity"; }
        bind "n" { Search "down"; }
        bind "o" { SearchToggleOption "WholeWord"; }
        bind "p" { Search "up"; }
        bind "w" { SearchToggleOption "Wrap"; }
    }
    session {
        bind "c" {
            LaunchOrFocusPlugin "configuration" {
                floating true
                move_to_focused_tab true
            }
            SwitchToMode "normal"
        }
        bind "Ctrl o" { SwitchToMode "normal"; }
        bind "p" {
            LaunchOrFocusPlugin "plugin-manager" {
                floating true
                move_to_focused_tab true
            }
            SwitchToMode "normal"
        }
        bind "w" {
            LaunchOrFocusPlugin "session-manager" {
                floating true
                move_to_focused_tab true
            }
            SwitchToMode "normal"
        }
    }
    shared_except "locked" {
        bind "Alt +" { Resize "Increase"; }
        bind "Alt -" { Resize "Decrease"; }
        bind "Alt =" { Resize "Increase"; }
        bind "Alt [" { PreviousSwapLayout; }
        bind "Alt ]" { NextSwapLayout; }
        bind "Alt f" { ToggleFloatingPanes; }
        bind "Ctrl g" { SwitchToMode "locked"; }
        bind "Alt i" { MoveTab "left"; }
        bind "Alt n" { NewPane; }
        bind "Alt o" { MoveTab "right"; }
        bind "Ctrl q" { Quit; }
    }
    shared_except "locked" "move" {
        bind "Ctrl h" { SwitchToMode "move"; }
    }
    shared_except "locked" "session" {
        bind "Ctrl o" { SwitchToMode "session"; }
    }
    shared_except "locked" "scroll" {
        bind "Alt left" { MoveFocusOrTab "left"; }
        bind "Alt down" { MoveFocus "down"; }
        bind "Alt up" { MoveFocus "up"; }
        bind "Alt right" { MoveFocusOrTab "right"; }
        bind "Alt h" { MoveFocusOrTab "left"; }
        bind "Alt j" { MoveFocus "down"; }
        bind "Alt k" { MoveFocus "up"; }
        bind "Alt l" { MoveFocusOrTab "right"; }
    }
    shared_except "locked" "scroll" "search" "tmux" {
        bind "Ctrl b" { SwitchToMode "tmux"; }
    }
    shared_except "locked" "scroll" "search" {
        bind "Ctrl s" { SwitchToMode "scroll"; }
    }
    shared_except "locked" "tab" {
        bind "Ctrl t" { SwitchToMode "tab"; }
    }
    shared_except "locked" "pane" {
        bind "Ctrl p" { SwitchToMode "pane"; }
    }
    shared_except "locked" "resize" {
        bind "Ctrl n" { SwitchToMode "resize"; }
    }
    shared_except "normal" "locked" "entersearch" {
        bind "enter" { SwitchToMode "normal"; }
    }
    shared_except "normal" "locked" "entersearch" "renametab" "renamepane" {
        bind "esc" { SwitchToMode "normal"; }
    }
    shared_among "pane" "tmux" {
        bind "x" { CloseFocus; SwitchToMode "normal"; }
    }
    shared_among "scroll" "search" {
        bind "PageDown" { PageScrollDown; }
        bind "PageUp" { PageScrollUp; }
        bind "left" { PageScrollUp; }
        bind "down" { ScrollDown; }
        bind "up" { ScrollUp; }
        bind "right" { PageScrollDown; }
        bind "Ctrl b" { PageScrollUp; }
        bind "Ctrl c" { ScrollToBottom; SwitchToMode "normal"; }
        bind "d" { HalfPageScrollDown; }
        bind "Ctrl f" { PageScrollDown; }
        bind "h" { PageScrollUp; }
        bind "j" { ScrollDown; }
        bind "k" { ScrollUp; }
        bind "l" { PageScrollDown; }
        bind "Ctrl s" { SwitchToMode "normal"; }
        bind "u" { HalfPageScrollUp; }
    }
    entersearch {
        bind "Ctrl c" { SwitchToMode "scroll"; }
        bind "esc" { SwitchToMode "scroll"; }
        bind "enter" { SwitchToMode "search"; }
    }
    renametab {
        bind "esc" { UndoRenameTab; SwitchToMode "tab"; }
    }
    shared_among "renametab" "renamepane" {
        bind "Ctrl c" { SwitchToMode "normal"; }
    }
    renamepane {
        bind "esc" { UndoRenamePane; SwitchToMode "pane"; }
    }
    shared_among "session" "tmux" {
        bind "d" { Detach; }
    }
    tmux {
        bind "left" { MoveFocus "left"; SwitchToMode "normal"; }
        bind "down" { MoveFocus "down"; SwitchToMode "normal"; }
        bind "up" { MoveFocus "up"; SwitchToMode "normal"; }
        bind "right" { MoveFocus "right"; SwitchToMode "normal"; }
        bind "space" { NextSwapLayout; }
        bind "\"" { NewPane "down"; SwitchToMode "normal"; }
        bind "%" { NewPane "right"; SwitchToMode "normal"; }
        bind "," { SwitchToMode "renametab"; }
        bind "[" { SwitchToMode "scroll"; }
        bind "Ctrl b" { Write 2; SwitchToMode "normal"; }
        bind "c" { NewTab; SwitchToMode "normal"; }
        bind "h" { MoveFocus "left"; SwitchToMode "normal"; }
        bind "j" { MoveFocus "down"; SwitchToMode "normal"; }
        bind "k" { MoveFocus "up"; SwitchToMode "normal"; }
        bind "l" { MoveFocus "right"; SwitchToMode "normal"; }
        bind "n" { GoToNextTab; SwitchToMode "normal"; }
        bind "o" { FocusNextPane; }
        bind "p" { GoToPreviousTab; SwitchToMode "normal"; }
        bind "z" { ToggleFocusFullscreen; SwitchToMode "normal"; }
    }
}

// Plugin aliases - can be used to change the implementation of Zellij
// changing these requires a restart to take effect
plugins {
    compact-bar location="zellij:compact-bar"
    configuration location="zellij:configuration"
    filepicker location="zellij:strider" {
        cwd "/"
    }
    plugin-manager location="zellij:plugin-manager"
    session-manager location="zellij:session-manager"
    status-bar location="zellij:status-bar"
    strider location="zellij:strider"
    tab-bar location="zellij:tab-bar"
    welcome-screen location="zellij:session-manager" {
        welcome_screen true
    }
}

// Plugins to load in the background when a new session starts
// eg. "file:/path/to/my-plugin.wasm"
// eg. "https://example.com/my-plugin.wasm"
load_plugins {
}
 
// Use a simplified UI without special fonts (arrow glyphs)
// Options:
//   - true
//   - false (Default)
// 
// simplified_ui true
 
// Choose the theme that is specified in the themes section.
// Default: default
// 
// theme "dracula"
 
// Choose the base input mode of zellij.
// Default: normal
// 
default_mode "normal"
 
// Choose the path to the default shell that zellij will use for opening new panes
// Default: $SHELL
// 
// default_shell "fish"
 
// Choose the path to override cwd that zellij will use for opening new panes
// 
// default_cwd "/tmp"
 
// The name of the default layout to load on startup
// Default: "default"
// 
// default_layout "compact"
 
// The folder in which Zellij will look for layouts
// (Requires restart)
// 
// layout_dir "/tmp"
 
// The folder in which Zellij will look for themes
// (Requires restart)
// 
// theme_dir "/tmp"
 
// Toggle enabling the mouse mode.
// On certain configurations, or terminals this could
// potentially interfere with copying text.
// Options:
//   - true (default)
//   - false
// 
// mouse_mode false
 
// Toggle having pane frames around the panes
// Options:
//   - true (default, enabled)
//   - false
// 
// pane_frames false
 
// When attaching to an existing session with other users,
// should the session be mirrored (true)
// or should each user have their own cursor (false)
// (Requires restart)
// Default: false
// 
// mirror_session true
 
// Choose what to do when zellij receives SIGTERM, SIGINT, SIGQUIT or SIGHUP
// eg. when terminal window with an active zellij session is closed
// (Requires restart)
// Options:
//   - detach (Default)
//   - quit
// 
// on_force_close "quit"
 
// Configure the scroll back buffer size
// This is the number of lines zellij stores for each pane in the scroll back
// buffer. Excess number of lines are discarded in a FIFO fashion.
// (Requires restart)
// Valid values: positive integers
// Default value: 10000
// 
// scroll_buffer_size 10000
 
// Provide a command to execute when copying text. The text will be piped to
// the stdin of the program to perform the copy. This can be used with
// terminal emulators which do not support the OSC 52 ANSI control sequence
// that will be used by default if this option is not set.
// Examples:
//
// copy_command "xclip -selection clipboard" // x11
// copy_command "wl-copy"                    // wayland
// copy_command "pbcopy"                     // osx
// 
// copy_command "pbcopy"
 
// Choose the destination for copied text
// Allows using the primary selection buffer (on x11/wayland) instead of the system clipboard.
// Does not apply when using copy_command.
// Options:
//   - system (default)
//   - primary
// 
// copy_clipboard "primary"
 
// Enable automatic copying (and clearing) of selection when releasing mouse
// Default: true
// 
// copy_on_select true
 
// Path to the default editor to use to edit pane scrollbuffer
// Default: $EDITOR or $VISUAL
// scrollback_editor "/usr/bin/vim"
 
// A fixed name to always give the Zellij session.
// Consider also setting `attach_to_session true,`
// otherwise this will error if such a session exists.
// Default: <RANDOM>
// 
// session_name "My singleton session"
 
// When `session_name` is provided, attaches to that session
// if it is already running or creates it otherwise.
// Default: false
// 
// attach_to_session true
 
// Toggle between having Zellij lay out panes according to a predefined set of layouts whenever possible
// Options:
//   - true (default)
//   - false
// 
// auto_layout false
 
// Whether sessions should be serialized to the cache folder (including their tabs/panes, cwds and running commands) so that they can later be resurrected
// Options:
//   - true (default)
//   - false
// 
// session_serialization false
 
// Whether pane viewports are serialized along with the session, default is false
// Options:
//   - true
//   - false (default)
// 
// serialize_pane_viewport false
 
// Scrollback lines to serialize along with the pane viewport when serializing sessions, 0
// defaults to the scrollback size. If this number is higher than the scrollback size, it will
// also default to the scrollback size. This does nothing if `serialize_pane_viewport` is not true.
// 
// scrollback_lines_to_serialize 10000
 
// Enable or disable the rendering of styled and colored underlines (undercurl).
// May need to be disabled for certain unsupported terminals
// (Requires restart)
// Default: true
// 
// styled_underlines false
 
// How often in seconds sessions are serialized
// 
// serialization_interval 10000
 
// Enable or disable writing of session metadata to disk (if disabled, other sessions might not know
// metadata info on this session)
// (Requires restart)
// Default: false
// 
// disable_session_metadata false
 
// Enable or disable support for the enhanced Kitty Keyboard Protocol (the host terminal must also support it)
// (Requires restart)
// Default: true (if the host terminal supports it)
// 
// support_kitty_keyboard_protocol false
-- -- Reload config
-- hs.hotkey.bind({"cmd", "alt", "ctrl"}, "R", function()
--   hs.reload()
-- end)

-- -- Initialize variables
-- local lastShiftPressTime = 0
-- local shiftDoublePressPeriod = 0.3
-- local fnPressed = false

-- -- Function to simulate keypress
-- local function keyStroke(modifiers, key)
--   hs.eventtap.keyStroke(modifiers, key, 0)
-- end

-- -- Fn + HJKL for window/tab navigation
-- local fnHJKL = hs.eventtap.new({hs.eventtap.event.types.keyDown}, function(event)
--   local keyCode = event:getKeyCode()
--   local flags = event:getFlags()
  
--   if flags.fn then
--     -- Map fn + h/l to ctrl+shift+tab / ctrl+tab (switch tabs)
--     if keyCode == hs.keycodes.map['h'] then
--       keyStroke({'ctrl', 'shift'}, 'tab')
--       return true
--     elseif keyCode == hs.keycodes.map['l'] then
--       keyStroke({'ctrl'}, 'tab')
--       return true
--     -- Map fn + j/k to cmd+shift+` / cmd+` (switch windows)
--     elseif keyCode == hs.keycodes.map['j'] then
--       keyStroke({'cmd', 'shift'}, '`')
--       return true
--     elseif keyCode == hs.keycodes.map['k'] then
--       keyStroke({'cmd'}, '`')
--       return true
--     end
--   end
--   return false
-- end)
-- fnHJKL:start()

-- -- Double tap left shift to type ~/
-- local leftShiftTap = hs.eventtap.new({hs.eventtap.event.types.flagsChanged}, function(event)
--   local flags = event:getFlags()
--   local currentTime = hs.timer.secondsSinceEpoch()
  
--   if flags.shift and not flags.cmd and not flags.ctrl and not flags.alt then
--     if (currentTime - lastShiftPressTime) < shiftDoublePressPeriod then
--       hs.eventtap.keyStrokes("~/")
--       lastShiftPressTime = 0
--       return true
--     end
--     lastShiftPressTime = currentTime
--   end
--   return false
-- end)
-- leftShiftTap:start()

-- -- Right Command + V to open Karabiner EventViewer
-- hs.hotkey.bind({"rightcmd"}, "v", function()
--   hs.application.launchOrFocus("/Applications/Karabiner-EventViewer.app")
-- end)

-- -- Control + H to delete
-- hs.hotkey.bind({"ctrl"}, "h", function()
--   keyStroke({}, "delete")
-- end)

-- -- Caps Lock handler (requires Karabiner for the initial mapping)
-- -- Note: The actual Caps Lock to Esc (tap) + Ctrl (hold) needs to be configured in Karabiner
-- -- as Hammerspoon cannot distinguish between tap and hold events for modifier keys

-- -- Mission Control on double-tap right shift
-- -- Note: This is better handled by Karabiner due to the need for variable state tracking

-- -- Equal + Delete to Forward Delete
-- local equalDeleteTap = hs.eventtap.new({hs.eventtap.event.types.keyDown}, function(event)
--   local flags = event:getFlags()
--   local keyCode = event:getKeyCode()
  
--   if keyCode == hs.keycodes.map['delete'] and flags.shift then
--     keyStroke({}, "forwarddelete")
--     return true
--   end
--   return false
-- end)
-- equalDeleteTap:start()

-- -- Fn + Quote/Semicolon to cycle through applications
-- local fnQuoteSemicolon = hs.eventtap.new({hs.eventtap.event.types.keyDown}, function(event)
--   local keyCode = event:getKeyCode()
--   local flags = event:getFlags()
  
--   if flags.fn then
--     if keyCode == hs.keycodes.map["'"] then
--       keyStroke({'cmd'}, 'tab')
--       return true
--     elseif keyCode == hs.keycodes.map[';'] then
--       keyStroke({'cmd', 'shift'}, 'tab')
--       return true
--     end
--   end
--   return false
-- end)
-- fnQuoteSemicolon:start()

-- -- Print message to console to confirm config loaded
-- print("Hammerspoon config loaded")

-- -- Note: Some Karabiner features cannot be perfectly replicated in Hammerspoon:
-- -- 1. Modifier key tap vs hold distinctions (like Caps Lock behavior)
-- -- 2. Complex variable state tracking for double-tap behaviors
-- -- 3. Device-specific configurations
-- -- These should remain in Karabiner while using Hammerspoon for other functionality
{
    "global": { "show_profile_name_in_menu_bar": true },
    "profiles": [
        {
            "complex_modifications": {
                "rules": [
                    {
                        "description": "Hyper Key: Right Command → Hyper (right modifiers ⌃⇧⌥⌘)",
                        "enabled": false,
                        "manipulators": [
                            {
                                "from": {
                                    "key_code": "right_command",
                                    "modifiers": { "optional": ["any"] }
                                },
                                "to": [
                                    {
                                        "set_variable": {
                                            "name": "hyper_right_option",
                                            "value": 1
                                        }
                                    },
                                    {
                                        "key_code": "right_control",
                                        "modifiers": ["right_shift", "right_option", "right_command"]
                                    }
                                ],
                                "to_after_key_up": [
                                    {
                                        "set_variable": {
                                            "name": "hyper_right_command",
                                            "value": 0
                                        }
                                    }
                                ],
                                "type": "basic"
                            }
                        ]
                    },
                    {
                        "description": "Open Karabiner EventViewer by right command + v",
                        "enabled": false,
                        "manipulators": [
                            {
                                "from": {
                                    "key_code": "v",
                                    "modifiers": {
                                        "mandatory": ["right_command"],
                                        "optional": ["caps_lock"]
                                    }
                                },
                                "to": [{ "software_function": { "open_application": { "file_path": "/Applications/Karabiner-EventViewer.app" } } }],
                                "type": "basic"
                            }
                        ]
                    },
                    {
                        "description": "Change right_shift to sticky modifier",
                        "enabled": false,
                        "manipulators": [
                            {
                                "from": {
                                    "key_code": "right_shift",
                                    "modifiers": { "optional": ["any"] }
                                },
                                "to": [{ "key_code": "right_shift" }],
                                "to_if_alone": [{ "sticky_modifier": { "right_shift": "toggle" } }],
                                "type": "basic"
                            }
                        ]
                    },
                    {
                        "description": "Use fn+;/' to cycle through running applications (like command+tab).",
                        "enabled": false,
                        "manipulators": [
                            {
                                "from": {
                                    "key_code": "quote",
                                    "modifiers": { "mandatory": ["fn"] }
                                },
                                "to": [
                                    {
                                        "key_code": "tab",
                                        "modifiers": ["left_command"]
                                    }
                                ],
                                "type": "basic"
                            },
                            {
                                "from": {
                                    "key_code": "semicolon",
                                    "modifiers": { "mandatory": ["fn"] }
                                },
                                "to": [
                                    {
                                        "key_code": "tab",
                                        "modifiers": ["left_command", "left_shift"]
                                    }
                                ],
                                "type": "basic"
                            }
                        ]
                    },
                    {
                        "description": "Use fn+h/l to switch tabs in an application.",
                        "enabled": false,
                        "manipulators": [
                            {
                                "from": {
                                    "key_code": "l",
                                    "modifiers": { "mandatory": ["fn"] }
                                },
                                "to": [
                                    {
                                        "key_code": "tab",
                                        "modifiers": ["left_control"]
                                    }
                                ],
                                "type": "basic"
                            },
                            {
                                "from": {
                                    "key_code": "h",
                                    "modifiers": { "mandatory": ["fn"] }
                                },
                                "to": [
                                    {
                                        "key_code": "tab",
                                        "modifiers": ["left_control", "left_shift"]
                                    }
                                ],
                                "type": "basic"
                            }
                        ]
                    },
                    {
                        "description": "Use fn+j/k to switch windows of the foreground application .",
                        "enabled": false,
                        "manipulators": [
                            {
                                "from": {
                                    "key_code": "k",
                                    "modifiers": { "mandatory": ["fn"] }
                                },
                                "to": [
                                    {
                                        "key_code": "grave_accent_and_tilde",
                                        "modifiers": ["left_command"]
                                    }
                                ],
                                "type": "basic"
                            },
                            {
                                "from": {
                                    "key_code": "j",
                                    "modifiers": { "mandatory": ["fn"] }
                                },
                                "to": [
                                    {
                                        "key_code": "grave_accent_and_tilde",
                                        "modifiers": ["left_command", "left_shift"]
                                    }
                                ],
                                "type": "basic"
                            }
                        ]
                    },
                    {
                        "description": "Disable the accidental keystroke prevention of Caps Lock",
                        "enabled": false,
                        "manipulators": [
                            {
                                "from": {
                                    "key_code": "caps_lock",
                                    "modifiers": { "optional": ["any"] }
                                },
                                "to": [
                                    {
                                        "hold_down_milliseconds": 100,
                                        "key_code": "caps_lock"
                                    },
                                    { "key_code": "vk_none" }
                                ],
                                "type": "basic"
                            }
                        ]
                    },
                    {
                        "description": "Change equal+delete to forward_delete if these keys are pressed simultaneously",
                        "enabled": false,
                        "manipulators": [
                            {
                                "from": {
                                    "modifiers": { "optional": ["any"] },
                                    "simultaneous": [
                                        { "key_code": "equal_sign" },
                                        { "key_code": "delete_or_backspace" }
                                    ]
                                },
                                "to": [{ "key_code": "delete_forward" }],
                                "type": "basic"
                            }
                        ]
                    },
                    {
                        "description": "Change control-h to delete",
                        "enabled": false,
                        "manipulators": [
                            {
                                "from": {
                                    "key_code": "h",
                                    "modifiers": {
                                        "mandatory": ["control"],
                                        "optional": ["caps_lock", "option"]
                                    }
                                },
                                "to": [{ "key_code": "delete_or_backspace" }],
                                "type": "basic"
                            }
                        ]
                    },
                    {
                        "description": "Change right_shift x2 to mission_control",
                        "enabled": false,
                        "manipulators": [
                            {
                                "conditions": [
                                    {
                                        "name": "right_shift pressed",
                                        "type": "variable_if",
                                        "value": 1
                                    }
                                ],
                                "from": {
                                    "key_code": "right_shift",
                                    "modifiers": { "optional": ["any"] }
                                },
                                "to": [
                                    { "apple_vendor_keyboard_key_code": "mission_control" },
                                    { "key_code": "vk_none" }
                                ],
                                "type": "basic"
                            },
                            {
                                "from": {
                                    "key_code": "right_shift",
                                    "modifiers": { "optional": ["any"] }
                                },
                                "to": [
                                    {
                                        "set_variable": {
                                            "name": "right_shift pressed",
                                            "value": 1
                                        }
                                    },
                                    { "key_code": "right_shift" }
                                ],
                                "to_delayed_action": {
                                    "to_if_canceled": [
                                        {
                                            "set_variable": {
                                                "name": "right_shift pressed",
                                                "value": 0
                                            }
                                        }
                                    ],
                                    "to_if_invoked": [
                                        {
                                            "set_variable": {
                                                "name": "right_shift pressed",
                                                "value": 0
                                            }
                                        }
                                    ]
                                },
                                "type": "basic"
                            }
                        ]
                    },
                    {
                        "description": "Saves you from having to reset the computer if e.g. a program has captured the screen and hangs. It does so by sending the SIGKILL signal to the frontmost application. Note: Macos already has a similar keybinding: Press Shift+Ctrl+Cmd+Esc for three seconds. However the built-in keybinding only sends SIGTERM, which doesn't always work, for instance if the program has a signal handler or runs in a debugger.",
                        "enabled": false,
                        "manipulators": [
                            {
                                "from": {
                                    "key_code": "f12",
                                    "modifiers": { "mandatory": ["left_shift", "left_option", "left_command"] }
                                },
                                "to": [{ "shell_command": "killall -9 \"$(osascript -e 'tell application \"System Events\" to (name of (first process whose frontmost is true))')\"" }],
                                "type": "basic"
                            }
                        ]
                    },
                    {
                        "description": "Change cmd+backslach to cmd+f11 if pressed in VSCode or Cursor",
                        "enabled": false,
                        "manipulators": [
                            {
                                "conditions": [
                                    {
                                        "bundle_identifiers": [
                                            "com\\.microsoft\\.VSCode",
                                            "com\\.microsoft\\.VSCodeInsiders"
                                        ],
                                        "type": "frontmost_application_if"
                                    }
                                ],
                                "from": {
                                    "key_code": "backslash",
                                    "modifiers": {
                                        "mandatory": ["left_gui"],
                                        "optional": ["any"]
                                    }
                                },
                                "to": [
                                    {
                                        "key_code": "f11",
                                        "modifiers": ["left_gui"]
                                    }
                                ],
                                "type": "basic"
                            },
                            {
                                "conditions": [
                                    {
                                        "file_paths": ["/Cursor.app$", "/Cursor$"],
                                        "type": "frontmost_application_if"
                                    }
                                ],
                                "from": {
                                    "key_code": "backslash",
                                    "modifiers": {
                                        "mandatory": ["left_gui"],
                                        "optional": ["any"]
                                    }
                                },
                                "to": [
                                    {
                                        "key_code": "f11",
                                        "modifiers": ["left_gui"]
                                    }
                                ],
                                "type": "basic"
                            }
                        ]
                    },
                    {
                        "description": "Double tap left-shift to return ~/",
                        "enabled": false,
                        "manipulators": [
                            {
                                "conditions": [
                                    {
                                        "name": "left_shift pressed",
                                        "type": "variable_if",
                                        "value": 1
                                    }
                                ],
                                "from": {
                                    "key_code": "left_shift",
                                    "modifiers": { "optional": ["any"] }
                                },
                                "to": [
                                    {
                                        "key_code": "grave_accent_and_tilde",
                                        "modifiers": ["shift"]
                                    },
                                    { "key_code": "slash" }
                                ],
                                "type": "basic"
                            },
                            {
                                "from": {
                                    "key_code": "left_shift",
                                    "modifiers": { "optional": ["any"] }
                                },
                                "to": [
                                    {
                                        "set_variable": {
                                            "name": "left_shift pressed",
                                            "value": 1
                                        }
                                    },
                                    { "key_code": "left_shift" }
                                ],
                                "to_delayed_action": {
                                    "to_if_canceled": [
                                        {
                                            "set_variable": {
                                                "name": "left_shift pressed",
                                                "value": 0
                                            }
                                        }
                                    ],
                                    "to_if_invoked": [
                                        {
                                            "set_variable": {
                                                "name": "left_shift pressed",
                                                "value": 0
                                            }
                                        }
                                    ]
                                },
                                "type": "basic"
                            }
                        ]
                    },
                    {
                        "description": "TODO (fn key hold + hjkl = arrow keys) Navigation (fn+hjkl -> arrow keys)",
                        "enabled": false,
                        "manipulators": [
                            {
                                "from": {
                                    "key_code": "h",
                                    "modifiers": { "mandatory": ["fn"] }
                                },
                                "to": [{ "key_code": "left_arrow" }],
                                "type": "basic"
                            },
                            {
                                "from": {
                                    "key_code": "j",
                                    "modifiers": { "mandatory": ["fn"] }
                                },
                                "to": [{ "key_code": "down_arrow" }],
                                "type": "basic"
                            },
                            {
                                "from": {
                                    "key_code": "k",
                                    "modifiers": { "mandatory": ["fn"] }
                                },
                                "to": [{ "key_code": "up_arrow" }],
                                "type": "basic"
                            },
                            {
                                "from": {
                                    "key_code": "l",
                                    "modifiers": { "mandatory": ["fn"] }
                                },
                                "to": [{ "key_code": "right_arrow" }],
                                "type": "basic"
                            }
                        ]
                    },
                    {
                        "description": "CapsLock -> esc (tap) + left_control (hold)",
                        "manipulators": [
                            {
                                "from": {
                                    "key_code": "caps_lock",
                                    "modifiers": { "optional": ["any"] }
                                },
                                "to": [
                                    {
                                        "key_code": "left_control",
                                        "lazy": true
                                    }
                                ],
                                "to_if_alone": [{ "key_code": "escape" }],
                                "type": "basic"
                            }
                        ]
                    }
                ]
            },
            "devices": [
                {
                    "identifiers": {
                        "is_keyboard": true,
                        "is_pointing_device": true,
                        "product_id": 1760,
                        "vendor_id": 13364
                    },
                    "ignore": false,
                    "manipulate_caps_lock_led": false
                },
                {
                    "identifiers": {
                        "is_keyboard": true,
                        "product_id": 1760,
                        "vendor_id": 13364
                    },
                    "manipulate_caps_lock_led": false
                },
                {
                    "identifiers": {
                        "is_keyboard": true,
                        "is_pointing_device": true,
                        "product_id": 45081,
                        "vendor_id": 1133
                    },
                    "ignore": false,
                    "manipulate_caps_lock_led": false
                }
            ],
            "name": "Keychron Q14 profile",
            "selected": true,
            "simple_modifications": [
                {
                    "from": { "key_code": "f20" },
                    "to": [{ "apple_vendor_top_case_key_code": "keyboard_fn" }]
                }
            ],
            "virtual_hid_keyboard": { "keyboard_type_v2": "ansi" }
        },
        {
            "complex_modifications": {
                "rules": [
                    {
                        "description": "RIGHT_SHIFT (tap : raycast) + (hold : hyperkey) - TODO use right_left trigger - TODO launchpad/charmstone/switcher",
                        "manipulators": [
                            {
                                "from": {
                                    "key_code": "right_shift",
                                    "modifiers": { "optional": ["any"] }
                                },
                                "to": [
                                    {
                                        "key_code": "left_shift",
                                        "modifiers": ["left_command", "left_control", "left_option"]
                                    }
                                ],
                                "to_if_alone": [
                                    {
                                        "key_code": "spacebar",
                                        "modifiers": ["right_command"]
                                    }
                                ],
                                "type": "basic"
                            }
                        ]
                    },
                    {
                        "description": "Caps Lock to Esc (tap) + Ctrl (hold)",
                        "manipulators": [
                            {
                                "description": "Caps Lock to Esc (tap) + Ctrl (hold)",
                                "from": { "key_code": "caps_lock" },
                                "to": [{ "key_code": "left_control" }],
                                "to_if_alone": [{ "key_code": "escape" }],
                                "type": "basic"
                            }
                        ]
                    },
                    {
                        "description": "Fn (tap : raycast) + (hold : hyperkey) - needs keychron map num_lock->fn key - TODO use right_left trigger - TODO launchpad/charmstone/switcher",
                        "manipulators": [
                            {
                                "from": {
                                    "key_code": "locking_num_lock",
                                    "modifiers": { "optional": ["any"] }
                                },
                                "to": [
                                    {
                                        "key_code": "left_shift",
                                        "modifiers": ["left_command", "left_control", "left_option"]
                                    }
                                ],
                                "to_if_alone": [
                                    {
                                        "key_code": "spacebar",
                                        "modifiers": ["right_command"]
                                    }
                                ],
                                "type": "basic"
                            }
                        ]
                    },
                    {
                        "description": "R_CMD -> switch input languages + RGH/home -> same",
                        "manipulators": [
                            {
                                "from": { "key_code": "right_gui" },
                                "to": [
                                    {
                                        "key_code": "spacebar",
                                        "lazy": true,
                                        "modifiers": ["left_control", "left_alt"],
                                        "repeat": false
                                    }
                                ],
                                "type": "basic"
                            },
                            {
                                "description": "RGH/Home -> input switch",
                                "from": { "key_code": "home" },
                                "to": [
                                    {
                                        "key_code": "spacebar",
                                        "modifiers": ["left_option", "left_control"]
                                    }
                                ],
                                "type": "basic"
                            }
                        ]
                    }
                ]
            },
            "devices": [
                {
                    "identifiers": {
                        "is_keyboard": true,
                        "is_pointing_device": true,
                        "product_id": 1760,
                        "vendor_id": 13364
                    },
                    "ignore": false,
                    "manipulate_caps_lock_led": false,
                    "treat_as_built_in_keyboard": true
                },
                {
                    "identifiers": {
                        "is_pointing_device": true,
                        "product_id": 24717,
                        "vendor_id": 6127
                    },
                    "ignore": false
                },
                {
                    "identifiers": {
                        "is_keyboard": true,
                        "is_pointing_device": true,
                        "product_id": 45081,
                        "vendor_id": 1133
                    },
                    "ignore": false,
                    "manipulate_caps_lock_led": false
                },
                {
                    "disable_built_in_keyboard_if_exists": true,
                    "identifiers": {
                        "is_keyboard": true,
                        "product_id": 1760,
                        "vendor_id": 13364
                    },
                    "manipulate_caps_lock_led": false
                },
                {
                    "identifiers": {
                        "is_pointing_device": true,
                        "product_id": 45108,
                        "vendor_id": 1133
                    },
                    "ignore": false
                }
            ],
            "name": "MBP profile",
            "virtual_hid_keyboard": { "keyboard_type_v2": "ansi" }
        }
    ]
}format = """
[░▒▓](#a3aed2)\
[  ](bg:#a3aed2 fg:#090c0c)\
[](bg:#769ff0 fg:#a3aed2)\
$directory\
[](fg:#769ff0 bg:#394260)\
$git_branch\
$git_status\
[](fg:#394260 bg:#212736)\
$nodejs\
$rust\
$golang\
$php\
[](fg:#212736 bg:#1d2230)\
$time\
[ ](fg:#1d2230)\
\n$character"""

[directory]
style = "fg:#e3e5e5 bg:#769ff0"
format = "[ $path ]($style)"
truncation_length = 3
truncation_symbol = "…/"

[directory.substitutions]
"Documents" = "󰈙 "
"Downloads" = " "
"Music" = " "
"Pictures" = " "

[git_branch]
symbol = ""
style = "bg:#394260"
format = '[[ $symbol $branch ](fg:#769ff0 bg:#394260)]($style)'

[git_status]
style = "bg:#394260"
format = '[[($all_status$ahead_behind )](fg:#769ff0 bg:#394260)]($style)'

[nodejs]
symbol = ""
style = "bg:#212736"
format = '[[ $symbol ($version) ](fg:#769ff0 bg:#212736)]($style)'

[rust]
symbol = ""
style = "bg:#212736"
format = '[[ $symbol ($version) ](fg:#769ff0 bg:#212736)]($style)'

[golang]
symbol = ""
style = "bg:#212736"
format = '[[ $symbol ($version) ](fg:#769ff0 bg:#212736)]($style)'

[php]
symbol = ""
style = "bg:#212736"
format = '[[ $symbol ($version) ](fg:#769ff0 bg:#212736)]($style)'

[time]
disabled = false
time_format = "%R" # Hour:Minute Format
style = "bg:#1d2230"
format = '[[  $time ](fg:#a0a9cb bg:#1d2230)]($style)'
eval "$(/opt/homebrew/bin/brew shellenv)"
```