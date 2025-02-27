#!/usr/bin/env zsh

# ========================================================================
# FZF Configuration - Modern, consistent FZF integration
# ========================================================================

# ========================================================================
# Base FZF Configuration
# ========================================================================
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS="
    --height 80%
    --layout=reverse
    --border sharp
    --margin=1
    --padding=1
    --info=inline
    --prompt='❯ '
    --pointer='▶'
    --marker='✓'
    --preview-window='right:60%:border-left'
    --bind='ctrl-/:toggle-preview'
    --bind='ctrl-y:execute-silent(echo {} | pbcopy)'
    --bind='ctrl-e:execute(nvim {} < /dev/tty > /dev/tty)'
    --bind='ctrl-f:preview-page-down'
    --bind='ctrl-b:preview-page-up'
    --bind='ctrl-a:select-all'
    --bind='ctrl-d:deselect-all'
    --bind='change:first'
    --color=fg:#c0caf5,bg:#1a1b26,hl:#bb9af7
    --color=fg+:#c0caf5,bg+:#292e42,hl+:#7dcfff
    --color=info:#7aa2f7,prompt:#7dcfff,pointer:#7dcfff
    --color=marker:#9ece6a,spinner:#9ece6a,header:#9ece6a
"

# File preview configuration
export FZF_PREVIEW_COMMAND="bat --style=numbers,changes --color=always --line-range :500 {}"

# Directory preview
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
export FZF_ALT_C_OPTS="
    --preview 'tree -C {} | head -200'
    --bind 'ctrl-/:toggle-preview'
    --header 'Jump to directory'
"

# File search configuration
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="
    --preview '$FZF_PREVIEW_COMMAND'
    --bind 'ctrl-/:toggle-preview'
    --header 'Select files'
"

# History search configuration
export FZF_CTRL_R_OPTS="
    --preview 'echo {}'
    --preview-window=down:3:wrap
    --bind 'ctrl-/:toggle-preview'
    --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'
    --header 'Search command history'
    --sort
    --exact
"

# ========================================================================
# FZF-Enhanced Functions
# ========================================================================

# Show and search aliases
function falias() {
    alias | fzf --multi \
        --preview 'echo {}' \
        --header 'Aliases' | awk '{print $0}'
}

# Git checkout with FZF
function fgco() {
    local branches branch
    branches=$(git branch --all | grep -v HEAD) &&
        branch=$(echo "$branches" |
            fzf-tmux -d 15 --no-multi) &&
        git checkout $(echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")
}

# Git add with FZF
function fga() {
    local files
    files=$(git -c color.status=always status --short |
        fzf --ansi --multi --preview 'git diff --color=always {2}' |
        cut -c4- |
        sed 's/.* -> //')

    if [[ -n "$files" ]]; then
        git add ${files}
        git status --short
    fi
}

# Process management with FZF
function fkill() {
    local pid
    pid=$(ps -ef | sed 1d |
        fzf -m --header='Kill process' |
        awk '{print $2}')

    if [[ -n "$pid" ]]; then
        echo "$pid" | xargs kill -${1:-9}
        echo "Process(es) killed"
    fi
}

# Find file and open in editor
function fnvim() {
    local file
    file=$(find ${1:-.} -type f -not -path "*/node_modules/*" -not -path "*/\.git/*" -not -path "*/.venv/*" 2>/dev/null |
        fzf +m --header='Open in editor') &&
        ${EDITOR:-nvim} "$file"
}

# Open man pages with FZF
function fman() {
    man -k . |
        fzf --prompt='Man> ' \
            --preview 'echo {} | cut -d" " -f1 | xargs -I% man %' \
            --preview-window=right:70% \
            --bind='ctrl-/:toggle-preview' \
            --header='View man pages' |
        awk '{print $1}' | xargs -r man
}

# Docker container management
function fdocker() {
    local container
    container=$(docker ps --format "{{.Names}}" |
        fzf --preview 'docker stats --no-stream {}' \
            --header 'Select container')

    if [[ -n "$container" ]]; then
        docker exec -it "$container" bash
    fi
}

# Port process killer with FZF
function fport() {
    local port_pid
    port_pid=$(lsof -i -P -n | grep LISTEN |
        fzf --preview 'echo {}' \
            --preview-window=down:3:wrap \
            --bind='ctrl-/:toggle-preview' \
            --header='Kill process on port' |
        awk '{print $2}')

    if [[ -n "$port_pid" ]]; then
        echo "Killing process $port_pid..."
        kill -9 "$port_pid"
    fi
}

# Enhanced file search with ripgrep and FZF
function frg() {
    local file line
    read -r file line <<<"$(rg --line-number --no-heading --color=always --smart-case "$@" |
        fzf --ansi \
            --color "hl:-1:underline,hl+:-1:underline:reverse" \
            --delimiter : \
            --preview "bat --style=numbers --color=always --highlight-line {2} {1}" \
            --preview-window "right,60%,border-left,+{2}+3/3,~3" \
            --bind='ctrl-/:toggle-preview' \
            --header='Search in files with ripgrep')"

    if [[ -n "$file" ]]; then
        ${EDITOR:-nvim} "$file" +"$line"
    fi
}

# Interactive brew install with FZF
function fbin() {
    local packages
    packages=$(brew search |
        fzf --multi \
            --preview 'brew info {}' \
            --header 'Install packages')

    if [[ -n "$packages" ]]; then
        echo "$packages" | xargs brew install
    fi
}

# Interactive brew uninstall with FZF
function fbrm() {
    local packages
    packages=$(brew leaves |
        fzf --multi \
            --preview 'brew info {}' \
            --header 'Remove packages')

    if [[ -n "$packages" ]]; then
        echo "$packages" | xargs brew uninstall
    fi
}

# Advanced git log browser
function fglog() {
    local filter
    if [[ -n "$1" ]]; then
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
function fnr() {
    local script
    script=$(cat package.json | jq -r '.scripts | to_entries | .[] | .key' |
        fzf --preview 'cat package.json | jq -r .scripts.{}' \
            --preview-window=right:60% \
            --bind='ctrl-/:toggle-preview' \
            --header='Run npm script')

    if [[ -n "$script" ]]; then
        echo "Running 'npm run $script'..."
        npm run "$script"
    fi
}

# Load FZF completion and key bindings if available
[[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh
