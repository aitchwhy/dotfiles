# Additional FZF Functions and Utilities

# FZF Git utilities
# Enhanced git checkout branch with preview
fgb() {
    local branches branch
    branches=$(git branch --all --color=always | grep -v HEAD) &&
    branch=$(echo "$branches" | fzf --ansi \
        --preview='git log --oneline --graph --date=short --color=always --pretty="format:%C(auto)%cd %h%d %s" $(sed s/^..// <<< {} | cut -d" " -f1)' \
        --preview-window=right:60% \
        --bind='ctrl-/:toggle-preview' \
        --header='Checkout git branch') &&
    git checkout $(echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")
}

# Git stash operations
fstash() {
    local out q k sha
    while out=$(
        git stash list --pretty="%C(yellow)%h %>(14)%Cgreen%cr %C(blue)%gs" |
        fzf --ansi \
            --no-sort \
            --query="$q" \
            --preview='git stash show --color=always -p $(cut -d" " -f1 <<< {})' \
            --preview-window=right:60% \
            --bind='ctrl-/:toggle-preview' \
            --header='Git stash operations' \
            --print-query \
            --expect=ctrl-a,ctrl-p,ctrl-d);
    do
        q=$(head -1 <<< "$out")
        k=$(head -2 <<< "$out" | tail -1)
        sha=$(grep -o '[a-f0-9]\{7\}' <<< "$out" | head -1)
        [ -z "$sha" ] && continue
        case "$k" in
            ctrl-a) git stash apply $sha ;;
            ctrl-p) git stash pop $sha ;;
            ctrl-d) git stash drop $sha ;;
        esac
    done
}

# Advanced git log browser
fglog() {
    local filter
    if [ -n "$1" ]; then
        filter="--author=$1"
    fi
    git log --graph --color=always --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" $filter |
    fzf --ansi --no-sort --reverse --tiebreak=index \
        --preview 'f() { set -- $(echo -- "$@" | grep -o "[a-f0-9]\{7\}"); [ $# -eq 0 ] || git show --color=always $1; }; f {}' \
        --preview-window=right:60% \
        --bind='ctrl-/:toggle-preview' \
        --header='Browse git log' \
        --bind='enter:execute:
            (grep -o "[a-f0-9]\{7\}" | head -1 |
            xargs -I % sh -c "git show --color=always % | less -R") <<< {}'
}

# NPM script runner
fnr() {
    local script
    script=$(cat package.json | jq -r '.scripts | to_entries | .[] | .key' |
        fzf --preview 'cat package.json | jq -r .scripts.{}' \
            --preview-window=right:60% \
            --bind='ctrl-/:toggle-preview' \
            --header='Run npm script')
    if [ -n "$script" ]; then
        echo "Running 'npm run $script'..."
        npm run "$script"
    fi
}

# Enhanced man page viewer
fman() {
    man -k . | fzf --prompt='Man> ' \
        --preview 'echo {} | cut -d" " -f1 | xargs -I% man %' \
        --preview-window=right:70% \
        --bind='ctrl-/:toggle-preview' \
        --header='View man pages' |
    awk '{print $1}' | xargs -r man
}

# Homebrew cask installer
fcask() {
    local token
    token=$(brew search --casks | fzf --preview 'brew info --cask {}' \
        --preview-window=right:60% \
        --bind='ctrl-/:toggle-preview' \
        --header='Install Homebrew cask')
    if [ -n "$token" ]; then
        echo "Installing cask $token..."
        brew install --cask "$token"
    fi
}

# Directory history navigation
fz() {
    local dir
    dir=$(z -l | awk '{print $2}' | fzf --preview 'tree -C {} | head -200' \
        --preview-window=right:60% \
        --bind='ctrl-/:toggle-preview' \
        --header='Jump to directory from history')
    if [ -n "$dir" ]; then
        cd "$dir"
    fi
}

# VSCode workspace selector
fvscode() {
    local workspace
    workspace=$(fd -e code-workspace . "$HOME/Development" | 
        fzf --preview 'cat {}' \
            --preview-window=right:60% \
            --bind='ctrl-/:toggle-preview' \
            --header='Open VSCode workspace')
    if [ -n "$workspace" ]; then
        code "$workspace"
    fi
}

# Environment variable explorer
fenv() {
    local var
    var=$(env | sort | fzf --preview 'echo {}' \
        --preview-window=down:3:wrap \
        --bind='ctrl-/:toggle-preview' \
        --header='Explore environment variables')
    if [ -n "$var" ]; then
        echo "$var" | pbcopy
        echo "Copied to clipboard: $var"
    fi
}

# Port process killer
fport() {
    local port_pid
    port_pid=$(lsof -i -P -n | grep LISTEN | 
        fzf --preview 'echo {}' \
            --preview-window=down:3:wrap \
            --bind='ctrl-/:toggle-preview' \
            --header='Kill process on port' | 
        awk '{print $2}')
    if [ -n "$port_pid" ]; then
        echo "Killing process $port_pid..."
        kill -9 "$port_pid"
    fi
}

# Kubernetes context switcher
fkctx() {
    local context
    context=$(kubectl config get-contexts --no-headers | 
        fzf --preview 'kubectl config get-contexts {}' \
            --preview-window=right:60% \
            --bind='ctrl-/:toggle-preview' \
            --header='Switch Kubernetes context' |
        awk '{print $1}')
    if [ -n "$context" ]; then
        kubectl config use-context "$context"
    fi
}

# Dotfiles editor
fdot() {
    local file
    file=$(fd --type f . "$DOTFILES/config" | 
        fzf --preview 'bat --style=numbers --color=always {}' \
            --preview-window=right:60% \
            --bind='ctrl-/:toggle-preview' \
            --header='Edit dotfiles')
    if [ -n "$file" ]; then
        ${EDITOR:-nvim} "$file"
    fi
}

# HTTP status code lookup
fhttp() {
    local code
    code=$(cat "$DOTFILES/config/zsh/data/http_status_codes.txt" |
        fzf --preview 'echo {}' \
            --preview-window=down:3:wrap \
            --bind='ctrl-/:toggle-preview' \
            --header='HTTP status codes')
    if [ -n "$code" ]; then
        echo "$code" | pbcopy
        echo "Copied to clipboard: $code"
    fi
}

# Color picker
fcolor() {
    local color
    color=$(cat "$DOTFILES/config/zsh/data/colors.txt" |
        fzf --preview 'echo {}' \
            --preview-window=down:3:wrap \
            --bind='ctrl-/:toggle-preview' \
            --header='Color codes')
    if [ -n "$color" ]; then
        echo "$color" | pbcopy
        echo "Copied to clipboard: $color"
    fi
}

# Enhanced file search with rg and preview
frg() {
    local file line
    read -r file line <<<"$(rg --line-number --no-heading --color=always --smart-case "$@" |
        fzf --ansi \
            --color "hl:-1:underline,hl+:-1:underline:reverse" \
            --delimiter : \
            --preview "bat --style=numbers --color=always --highlight-line {2} {1}" \
            --preview-window "right,60%,border-left,+{2}+3/3,~3" \
            --bind='ctrl-/:toggle-preview' \
            --header='Search in files with ripgrep')"
    if [ -n "$file" ]; then
        ${EDITOR:-nvim} "$file" +"$line"
    fi
}
