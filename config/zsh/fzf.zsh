
# Base FZF configuration
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

# FZF Functions

# Enhanced file search
ff() {
    local file
    file=$(fd --type f --hidden --follow --exclude .git | \
        fzf --preview "$FZF_PREVIEW_COMMAND" \
            --header 'Open file in editor')

    [ -n "$file" ] && ${EDITOR:-nvim} "$file"
}

# Enhanced directory search
fd() {
    local dir
    dir=$(fd --type d --hidden --follow --exclude .git | \
        fzf --preview 'tree -C {} | head -200' \
            --header 'Change directory')

    [ -n "$dir" ] && cd "$dir"
}

# aliases
falias() {
    local aliases
    aliases=$(alias | \
        fzf --multi \
            --preview 'git diff --color=always {2}' \
            --header 'Aliases' | \
        awk '{print $0}')

    [ -n "$aliases" ] && echo "$aliases"
}


# Git functions
# Interactive git add
fga() {
    local files
    files=$(git status -s | \
        fzf --multi \
            --preview 'git diff --color=always {2}' \
            --header 'Stage files' | \
        awk '{print $2}')

    [ -n "$files" ] && echo "$files" | xargs git add
}


# Interactive git checkout file
fgco() {
    local files
    files=$(git ls-files -m | \
        fzf --multi \
            --preview 'git diff --color=always {}' \
            --header 'Checkout files' )

    [ -n "$files" ] && echo "$files" | xargs git checkout
}

# Git log browser
fgl() {
    git log --graph --color=always \
        --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" |
    fzf --ansi --no-sort --reverse --tiebreak=index \
        --preview 'f() { set -- $(echo -- "$@" | grep -o "[a-f0-9]\{7\}"); [ $# -eq 0 ] || git show --color=always $1; }; f {}' \
        --header 'Browse git log' \
        --bind "ctrl-m:execute:
                (grep -o '[a-f0-9]\{7\}' | head -1 |
                xargs -I % sh -c 'git show --color=always % | less -R') << 'FZF-EOF'
                {}
                FZF-EOF"
}

# Process management
fkill() {
    local pid
    pid=$(ps -ef | sed 1d | \
        fzf --multi \
            --preview 'echo {}' \
            --header 'Kill processes' | \
        awk '{print $2}')

    [ -n "$pid" ] && echo "$pid" | xargs kill -${1:-9}
}

# Homebrew functions
# Interactive brew install
fbin() {
    local packages
    packages=$(brew search | \
        fzf --multi \
            --preview 'brew info {}' \
            --header 'Install packages')

    [ -n "$packages" ] && echo "$packages" | xargs brew install
}

# Interactive brew uninstall
fbrm() {
    local packages
    packages=$(brew leaves | \
        fzf --multi \
            --preview 'brew info {}' \
            --header 'Remove packages')

    [ -n "$packages" ] && echo "$packages" | xargs brew uninstall
}

# Docker functions
# Container management
fdocker() {
    local container
    container=$(docker ps --format "{{.Names}}" | \
        fzf --preview 'docker stats --no-stream {}' \
            --header 'Select container')

    [ -n "$container" ] && docker exec -it "$container" bash
}

# VSCode projects
fcode() {
    local dir
    dir=$(fd --type d --max-depth 3 --exclude node_modules --exclude .git | \
        fzf --preview 'tree -C {} | head -200' \
            --header 'Open in VSCode')

    [ -n "$dir" ] && code "$dir"
}

# Chrome bookmarks search
fbm() {
    local bookmarks_path="$HOME/Library/Application Support/Google/Chrome/Default/Bookmarks"

    if [[ ! -f "$bookmarks_path" ]]; then
        echo "Chrome Bookmarks file not found"
        return 1
    fi

    local jq_script='
        def ancestors: while(. | length >= 2; del(.[-1,-2]));
        . as $root | paths(try .url catch false) as $path | $path | . as $p |
        $root | getpath($p) | {name,url, path: [$p[0:-2] | ancestors as $a | $root | getpath($a) | .name?] | reverse | join("/") } | .path + "/" + .name + "\t" + .url
    '

    local bookmark_url=$(jq -r "$jq_script" < "$bookmarks_path" | \
        sed -E 's/\t/│/g' | \
        fzf --delimiter='│' \
            --with-nth=1 \
            --preview-window=hidden \
            --header 'Open bookmark' | \
        cut -d'│' -f2)

    [ -n "$bookmark_url" ] && open "$bookmark_url"
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

# https://github.com/junegunn/fzf/issues/2789
rfv() {
  # rg
  # --field-match-separator ' ' - tell rg to separate the filename and linenumber with
  # spaces to play well with fzf, (when recognizing index variables to use in the fzf
  # preview command, fzf uses a default delimiter of space, see below)

  # fzf
  # --preview window ~8,+{1}-5
  #   this is a fzf feature
  #   ~8 - show first 8 lines (header)
  #   +{2} - fzf delimits the input piped in to it and provides access via index variables {n}.
  #   the default delimiter fzf uses is space but can be specified via --delimiter <delimiter>
  #   pass the second index variable from bat (which is the line number)
  #   the number is signed, you can show eg the +n row or the -n row (the nth row from the bottom)
  #   -5 subtract 5 rows (go up 5 rows) so that you don't show the highlighted line as the first line
  #   since you want to provide context by showing the rows above the highlighted line

  rg --line-number --with-filename . --color=always --field-match-separator ' '\
    | fzf --preview "bat --color=always {1} --highlight-line {2}" \
    --preview-window ~8,+{2}-5
}

# # Load fzf completion and key bindings
# [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

##################### END
