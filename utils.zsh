# ========================================================================
# Installation & Update Utilities
# ========================================================================

# ========================================================================
# Logging Functions
# ========================================================================
function info() {
    printf '%s[INFO]%s %s\n' "${BLUE:-}" "${RESET:-}" "$*"
}

function success() {
    printf '%s[SUCCESS]%s %s\n' "${GREEN:-}" "${RESET:-}" "$*"
}

function warn() {
    printf '%s[WARNING]%s %s\n' "${YELLOW:-}" "${RESET:-}" "$*" >&2
}

function error() {
    printf '%s[ERROR]%s %s\n' "${RED:-}" "${RESET:-}" "$*" >&2
}

# ========================================================================
# System Detection
# ========================================================================
function is_macos() {
    [[ "$(uname -s)" == "Darwin" ]]
}

function is_apple_silicon() {
    [[ "$(uname -m)" == "arm64" ]]
}

function has_command() {
    command -v "$1" &>/dev/null
}

# ========================================================================
# File & Directory Operations
# ========================================================================
function ensure_dir() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
        success "Created directory: $dir"
    fi
}

function backup_file() {
    local file="$1"
    if [[ -e "$file" ]]; then
        local backup_dir="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"
        ensure_dir "$backup_dir"
        mv "$file" "$backup_dir/"
        success "Backed up $file to $backup_dir"
    fi
}

# ========================================================================
# System & macOS Utilities
# ========================================================================
function sys() {
    case "$1" in
    env | env-grep)
        echo "======== env vars =========="
        if [ -z "$2" ]; then
            printenv | sort | awk -F= '{ printf "%-30s %s\n", $1, $2 }'
        else
            printenv | sort | grep -i "$2" | awk -F= '{ printf "%-30s %s\n", $1, $2 }'
        fi
        echo "============================" # Search environment variables
        ;;

    hidden | toggle-hidden)
        local current
        current=$(defaults read com.apple.finder AppleShowAllFiles)
        defaults write com.apple.finder AppleShowAllFiles $((!current))
        killall Finder
        echo "Finder hidden files: $((!current))" # Toggle macOS hidden files
        ;;

    ql | quick-look)
        if [ -z "$2" ]; then
            echo "Usage: sys ql <file>"
            return 1
        fi
        qlmanage -p "${@:2}" &>/dev/null # Quick Look files from terminal
        ;;

    weather | wttr)
        local city="${2:-}"
        curl -s "wttr.in/$city?format=v2" # Get weather information
        ;;

    killport | kill-port)
        local port="$2"
        if [[ -z "$port" ]]; then
            echo "Please specify a port number"
            return 1
        fi

        local pid
        pid=$(lsof -i ":$port" | awk 'NR!=1 {print $2}')

        if [[ -z "$pid" ]]; then
            echo "No process found on port $port"
            return 1
        fi

        echo "Killing process(es) on port $port: $pid"
        echo "$pid" | xargs kill -9
        echo "Process(es) killed" # Kill process on specified port
        ;;

    ducks | top-files)
        local count="${2:-10}"
        du -sh * | sort -rh | head -"$count" # Show largest files in directory
        ;;

    man | batman)
        MANPAGER="sh -c 'col -bx | bat -l man -p'" man "${@:2}" # Improved man pages with bat
        ;;

    ports | listening)
        sudo lsof -iTCP -sTCP:LISTEN -n -P # Show all listening ports
        ;;

    space | disk)
        df -h # Check disk space usage
        ;;

    cpu)
        top -l 1 | grep -E "^CPU" # Show CPU usage
        ;;

    mem | memory)
        vm_stat | perl -ne '/page size of (\d+)/ and $size=$1; /Pages\s+([^:]+)[^\d]+(\d+)/ and printf("%-16s % 16.2f MB\n", "$1:", $2 * $size / 1048576);' # Show memory usage
        ;;

    path)
        echo $PATH | tr ':' '\n' | nl # List PATH entries
        ;;

    ip | myip)
        echo "Public IP: $(curl -s https://ipinfo.io/ip)"
        echo "Local IP: $(ipconfig getifaddr en0)" # Show IP addresses
        ;;

    help | *)
        if [[ "$1" != "help" && ! -z "$1" ]]; then
            echo "Unknown command: $1"
        fi

        echo "Usage: sys [command]"
        echo ""
        echo "Commands:"
        echo "  env [pattern]      - Display environment variables, optionally filtered"
        echo "  hidden             - Toggle hidden files in Finder"
        echo "  ql <file>          - Quick Look a file"
        echo "  weather [city]     - Show weather information"
        echo "  killport <port>    - Kill process running on specified port"
        echo "  ducks [count]      - Show largest files in current directory"
        echo "  man <command>      - Show man pages with syntax highlighting"
        echo "  ports              - Show all listening ports"
        echo "  space              - Check disk space usage"
        echo "  cpu                - Show CPU usage"
        echo "  mem                - Show memory usage"
        echo "  path               - List PATH entries"
        echo "  ip                 - Show public and local IP addresses"
        ;;
    esac
}
# ####################
# # Keep commonly used aliases for convenience
# alias penv='sys env'
# alias weather='sys weather'
# alias ql='sys ql'
# alias batman='sys man'
# alias ducks='sys ducks'

# declare -A DOTFILES_TO_SYMLINK_MAP=(
#     ["$DOTFILES/config/git/gitconfig"]="$HOME/.gitconfig"
#     ["$DOTFILES/config/git/gitignore"]="$HOME/.gitignore"
#     ["$DOTFILES/config/starship.toml"]="$XDG_CONFIG_HOME/starship.toml"
#     ["$DOTFILES/config/karabiner/karabiner.json"]="$XDG_CONFIG_HOME/karabiner/karabiner.json"
#     ["$DOTFILES/config/nvim"]="$XDG_CONFIG_HOME/nvim"
#     ["$DOTFILES/config/ghostty"]="$XDG_CONFIG_HOME/ghostty"
#     ["$DOTFILES/config/atuin"]="$XDG_CONFIG_HOME/atuin"
#     ["$DOTFILES/config/bat"]="$XDG_CONFIG_HOME/bat"
#     ["$DOTFILES/config/lazygit"]="$XDG_CONFIG_HOME/lazygit"
#     ["$DOTFILES/config/zellij"]="$XDG_CONFIG_HOME/zellij"
#     ["$DOTFILES/config/espanso"]="$XDG_CONFIG_HOME/espanso"
#     ["$DOTFILES/config/vscode/settings.json"]="$HOME/Library/Application Support/Code/User/settings.json"
#     ["$DOTFILES/config/vscode/keybindings.json"]="$HOME/Library/Application Support/Code/User/keybindings.json"
#     ["$DOTFILES/config/cursor/settings.json"]="$HOME/Library/Application Support/Cursor/User/settings.json"
#     ["$DOTFILES/config/cursor/keybindings.json"]="$HOME/Library/Application Support/Cursor/User/keybindings.json"
#     ["$DOTFILES/config/hammerspoon"]="$HOME/.hammerspoon"
#     ["$DOTFILES/config/ai/claude/claude_desktop_config.json"]="$HOME/Library/Application Support/Claude/claude_desktop_config.json"
# )
