# Load tool if it exists
load_if_exists() {
    local cmd="$1"
    local setup_cmd="$2"
    
    if command -v "$cmd" > /dev/null; then
        eval "$setup_cmd"
    fi
}

# Load optional config file
load_config_if_exists() {
    local config="$1"
    [[ -f "$config" ]] && source "$config"
}



# Update dotfiles
update_dotfiles() {
    local dotfiles_dir="$HOME/dotfiles"
    if [[ -d "$dotfiles_dir/.git" ]]; then
        (cd "$dotfiles_dir" && git pull && ./init.sh)
    fi
}


# -----------------------------------------------------
# Directory management
# -----------------------------------------------------

# Make directory and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Path manipulation
path_append() {
    if [ -d "$1" ] && [[ ":$PATH:" != *":$1:"* ]]; then
        PATH="${PATH:+"$PATH:"}$1"
    fi
}

path_prepend() {
    if [ -d "$1" ] && [[ ":$PATH:" != *":$1:"* ]]; then
        PATH="$1${PATH:+":$PATH"}"
    fi
}



# -----------------------------------------------------
# Directory Management
# -----------------------------------------------------

# Create and enter directory
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# -----------------------------------------------------
# Archive Management
# -----------------------------------------------------

# Extract various archive types
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

# -----------------------------------------------------
# Process Management
# -----------------------------------------------------

# Interactive process killer using fzf
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