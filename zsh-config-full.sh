# ~/dotfiles/home/zsh/zshenv - Environment setup




# ~/dotfiles/home/zsh/completions.zsh - Completion system
# Load completion system
autoload -Uz compinit
if [[ -n ${ZDOTDIR}/.zcompdump(#qN.mh+24) ]]; then
    compinit -d "${ZDOTDIR}/.zcompdump"
else
    compinit -C -d "${ZDOTDIR}/.zcompdump"
fi

# Add Homebrew completions to fpath
fpath=(
    ${HOMEBREW_PREFIX}/share/zsh/site-functions
    ${HOMEBREW_PREFIX}/share/zsh-completions
    $fpath
)

# Completion styles
zstyle ':completion:*' menu select
zstyle ':completion:*' group-name ''
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME}/zsh/zcompcache"

# ~/dotfiles/home/zsh/aliases.zsh - Command aliases
# Modern CLI replacements
has_command bat && alias cat='bat --paging=never'
has_command eza && alias ls='eza --icons --group-directories-first'
has_command rg && alias grep='rg'
has_command fd && alias find='fd'
has_command bottom && alias top='btm'
has_command dust && alias du='dust'
has_command duf && alias df='duf'
has_command zoxide && alias cd='z'

# Enhanced ls (if eza available)
has_command eza && {
    alias ll='eza -l --git --icons --group-directories-first'
    alias la='eza -la --git --icons --group-directories-first'
    alias lt='eza --tree --icons --group-directories-first'
    alias l='eza -F --icons --group-directories-first'
}

# Git shortcuts
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
has_command lazygit && alias lg='lazygit'

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias -- -='cd -'

# ~/dotfiles/home/zsh/functions.zsh - Custom functions
# Create and enter directory
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Extract archives
extract() {
    if [ -f $1 ]; then
        case $1 in
            *.tar.bz2)   tar xjf $1     ;;
            *.tar.gz)    tar xzf $1     ;;
            *.bz2)       bunzip2 $1     ;;
            *.rar)       unrar e $1     ;;
            *.gz)        gunzip $1      ;;
            *.tar)       tar xf $1      ;;
            *.tbz2)      tar xjf $1     ;;
            *.tgz)       tar xzf $1     ;;
            *.zip)       unzip $1       ;;
            *.Z)         uncompress $1  ;;
            *.7z)        7z x $1        ;;
            *)          echo "'$1' cannot be extracted" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Process killer
fkill() {
    local pid
    if [ "$UID" != "0" ]; then
        pid=$(ps -f -u $UID | sed 1d | fzf -m | awk '{print $2}')
    else
        pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')
    fi

    if [ "x$pid" != "x" ]; then
        echo $pid | xargs kill -${1:-9}
    fi
}

# Quick edit configs
conf() {
    local config_files=(
        "$ZDOTDIR/zshrc"
        "${XDG_CONFIG_HOME}/nvim/init.lua"
        "${XDG_CONFIG_HOME}/starship.toml"
    )
    ${EDITOR:-nvim} ${config_files[@]}
}

# ~/dotfiles/home/zsh/macos.zsh - macOS specific settings
# M-Series optimizations
export HOMEBREW_PREFIX="/opt/homebrew"
export PATH="${HOMEBREW_PREFIX}/bin:${PATH}"

# Metal/Neural Engine
export METAL_DEVICE_WRAPPER_TYPE=1
export TF_ENABLE_METAL=1

# macOS aliases
alias flushdns="sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder"
alias showhidden="defaults write com.apple.finder AppleShowAllFiles YES; killall Finder"