#!/usr/bin/env zsh

# ========================================================================
# FZF Unified Utilities - Modern, consistent FZF integration
# ========================================================================

# Base FZF Configuration
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

# Preview configurations
export FZF_PREVIEW_COMMAND="bat --style=numbers,changes --color=always --line-range :500 {}"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
export FZF_ALT_C_OPTS="--preview 'tree -C {} | head -200' --bind 'ctrl-/:toggle-preview' --header 'Jump to directory'"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="--preview '$FZF_PREVIEW_COMMAND' --bind 'ctrl-/:toggle-preview' --header 'Select files'"
export FZF_CTRL_R_OPTS="--preview 'echo {}' --preview-window=down:3:wrap --bind 'ctrl-/:toggle-preview' --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort' --header 'Search command history' --sort --exact"

# ========================================================================
# Unified FZF Function
# ========================================================================
function f() {
    # Helper functions
    _f_help() {
        echo "Usage: f [command] [args]"
        echo ""
        echo "FZF Utility Commands:"
        grep -E '^\s+[a-z|,-]+\)' <<<"$(declare -f f)" |
            sed 's/)//' | sed 's/|/, /g' |
            sed -E 's/^\s+([a-z, -]+) # (.*)/  \1\t- \2/' |
            sort
    }

    # Perform a fuzzy search with dynamic config
    _f_search() {
        local preview_cmd="$1"
        local header="$2"
        local action_cmd="$3"
        local initial_query="${4:-}"
        local fzf_opts="${5:-}"

        if [[ -z "$action_cmd" ]]; then
            # If no action is specified, just display the selection
            fzf --preview "$preview_cmd" \
                --header "$header" \
                --query "$initial_query" \
                $fzf_opts
        else
            # If an action is specified, execute it
            fzf --preview "$preview_cmd" \
                --header "$header" \
                --query "$initial_query" \
                $fzf_opts | eval "$action_cmd"
        fi
    }

    # Display help if no arguments or help is requested
    if [[ -z "$1" || "$1" == "help" ]]; then
        _f_help
        return 0
    fi

    case "$1" in
    # File and directory navigation
    file | f) # Find files and open selected
        local target="${2:-.}"
        _f_search \
            "$FZF_PREVIEW_COMMAND" \
            "Find files in $target" \
            "${EDITOR:-nvim} {}" \
            "" \
            "--multi"
        ;;

    dir | d) # Find directories
        local target="${2:-.}"
        fd --type d --hidden --follow --exclude .git . "$target" |
            _f_search \
                "tree -C {} | head -200" \
                "Find directories in $target" \
                "cd {}"
        ;;

    edit | e) # Find files and edit with nvim
        local target="${2:-.}"
        find "$target" -type f -not -path "*/node_modules/*" -not -path "*/\.git/*" -not -path "*/.venv/*" 2>/dev/null |
            _f_search \
                "$FZF_PREVIEW_COMMAND" \
                "Open in editor" \
                "${EDITOR:-nvim} {}"
        ;;

    # Search and grep utilities
    grep | g) # Fuzzy grep with ripgrep
        local query="${*:2}"
        local RELOAD='reload:rg --column --color=always --smart-case {q} || :'
        local OPENER='if [[ $FZF_SELECT_COUNT -eq 0 ]]; then
                      ${EDITOR:-nvim} {1} +{2}     # No selection. Open the current line.
                    else
                      ${EDITOR:-nvim} +cw -q {+f}  # Build quickfix list for the selected items.
                    fi'

        fzf --disabled --ansi --multi \
            --bind "start:$RELOAD" --bind "change:$RELOAD" \
            --bind "enter:become:$OPENER" \
            --bind "ctrl-o:execute:$OPENER" \
            --bind 'alt-a:select-all,alt-d:deselect-all,ctrl-/:toggle-preview' \
            --delimiter : \
            --preview 'bat --style=full --color=always --highlight-line {2} {1}' \
            --preview-window '~4,+{2}+4/3,<80(up)' \
            --query "$query"
        ;;

    rg | r) # Enhanced search with ripgrep
        local query="${*:2}"
        rg --line-number --no-heading --color=always --smart-case "$query" |
            fzf --ansi \
                --color "hl:-1:underline,hl+:-1:underline:reverse" \
                --delimiter : \
                --preview "bat --style=numbers --color=always --highlight-line {2} {1}" \
                --preview-window "right,60%,border-left,+{2}+3/3,~3" \
                --bind 'ctrl-/:toggle-preview' \
                --header "Search in files for: $query" |
            awk -F: '{print $1 " +" $2}' |
            xargs -o ${EDITOR:-nvim}
        ;;

    # Git operations
    gco | co) # Git checkout with FZF
        local branches branch
        branches=$(git branch --all | grep -v HEAD) &&
            branch=$(echo "$branches" |
                fzf --no-multi --header "Git checkout branch") &&
            git checkout $(echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")
        ;;

    ga | a) # Git add with FZF
        git -c color.status=always status --short |
            _f_search \
                "git diff --color=always {2}" \
                "Git add files" \
                "cut -c4- | sed 's/.* -> //' | xargs -r git add" \
                "" \
                "--ansi --multi"
        git status --short
        ;;

    glog | log) # Git log browser
        local author="${2:-}"
        local filter=""

        if [[ -n "$author" ]]; then
            filter="--author=$author"
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
        ;;

    # System utilities
    kill | k) # Process killing with FZF
        ps -ef | sed 1d |
            _f_search \
                "echo {}" \
                "Kill process (SIGTERM by default)" \
                "awk '{print \$2}' | xargs -r kill -${2:-15}" \
                "" \
                "--multi"
        ;;

    port | p) # Kill process on port
        lsof -i -P -n | grep LISTEN |
            _f_search \
                "echo {}" \
                "Kill process on port" \
                "awk '{print \$2}' | xargs -r kill -9" \
                "" \
                "--preview-window=down:3:wrap"
        ;;

    # Package management
    brew | b) # Brew operations
        local subcommand="${2:-install}"

        case "$subcommand" in
        install | i)
            brew search |
                _f_search \
                    "brew info {}" \
                    "Install brew packages" \
                    "xargs -r brew install" \
                    "${3:-}" \
                    "--multi"
            ;;
        uninstall | rm)
            brew leaves |
                _f_search \
                    "brew info {}" \
                    "Remove brew packages" \
                    "xargs -r brew uninstall" \
                    "${3:-}" \
                    "--multi"
            ;;
        *)
            echo "Unknown brew subcommand: $subcommand"
            echo "Available: install (i), uninstall (rm)"
            return 1
            ;;
        esac
        ;;

    docker | d) # Docker container management
        docker ps --format "{{.Names}}" |
            _f_search \
                "docker stats --no-stream {}" \
                "Select container" \
                "xargs -r docker exec -it bash"
        ;;

    npm | n) # NPM script runner
        if [[ ! -f package.json ]]; then
            echo "No package.json found in current directory"
            return 1
        fi

        cat package.json | jq -r '.scripts | to_entries | .[] | .key' |
            _f_search \
                "cat package.json | jq -r .scripts.{}" \
                "Run npm script" \
                'xargs -I{} sh -c "echo \"Running npm run {}...\" && npm run {}"'
        ;;

    man | m) # Man page browser
        man -k . |
            _f_search \
                "echo {} | cut -d\" \" -f1 | xargs -I% man %" \
                "Browse man pages" \
                "awk '{print \$1}' | xargs -r man" \
                "${2:-}" \
                ""
        ;;

    # Miscellaneous utilities
    alias | a) # Alias browser
        alias |
            _f_search \
                "echo {}" \
                "Browse aliases" \
                "awk '{print \$0}'" \
                "${2:-}" \
                "--multi"
        ;;

    history | h) # Enhanced history search
        history |
            _f_search \
                "echo {}" \
                "Search command history" \
                "awk '{print substr(\$0, index(\$0, \$2))}' | ${SHELL:-zsh}" \
                "${2:-}" \
                "--sort --exact --preview-window=down:3:wrap"
        ;;

    # Default case - unknown command
    *)
        echo "Unknown command: $1"
        _f_help
        return 1
        ;;
    esac
}

# ========================================================================
# Advanced Search with ripgrep + fzf + nvim
# ========================================================================
function rfv() {
    local RELOAD='reload:rg --column --color=always --smart-case {q} || :'
    local OPENER='if [[ $FZF_SELECT_COUNT -eq 0 ]]; then
                  ${EDITOR:-nvim} {1} +{2}     # No selection. Open the current line in editor.
                else
                  ${EDITOR:-nvim} +cw -q {+f}  # Build quickfix list for the selected items.
                fi'

    fzf --disabled --ansi --multi \
        --bind "start:$RELOAD" --bind "change:$RELOAD" \
        --bind "enter:become:$OPENER" \
        --bind "ctrl-o:execute:$OPENER" \
        --bind 'alt-a:select-all,alt-d:deselect-all,ctrl-/:toggle-preview' \
        --delimiter : \
        --preview 'bat --style=full --color=always --highlight-line {2} {1}' \
        --preview-window '~4,+{2}+4/3,<80(up)' \
        --query "$*"
}

# ========================================================================
# Common Aliases for Quick Access
# ========================================================================
alias fa='f alias'         # Browse aliases
alias fb='f brew'          # Brew operations
alias fbi='f brew install' # Brew install
alias fdir='f dir'         # Find directories
alias fdocker='f docker'   # Docker operations
alias fnvim='f edit'       # Find and edit
alias ff='f file'          # Find files
alias fga='f ga'           # Git add
alias fgco='f gco'         # Git checkout
alias fglog='f glog'       # Git log
alias fgrep='f grep'       # Fuzzy grep
alias fhistory='f history' # Search history
alias fman='f man'         # Man pages
alias fnpm='f npm'         # NPM operations
alias fkill='f kill'       # Kill process
alias fkilllport='f port'  # Kill port
alias f='f search'         # Search in files

# # Load FZF completion and key bindings if available
# [[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh

############################
# # ========================================================================
# # FZF Configuration - Modern, consistent FZF integration
# # ========================================================================

# # ========================================================================
# # Base FZF Configuration
# # ========================================================================
# export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
# export FZF_DEFAULT_OPTS="
#     --height 80%
#     --layout=reverse
#     --border sharp
#     --margin=1
#     --padding=1
#     --info=inline
#     --prompt='❯ '
#     --pointer='▶'
#     --marker='✓'
#     --preview-window='right:60%:border-left'
#     --bind='ctrl-/:toggle-preview'
#     --bind='ctrl-y:execute-silent(echo {} | pbcopy)'
#     --bind='ctrl-e:execute(nvim {} < /dev/tty > /dev/tty)'
#     --bind='ctrl-f:preview-page-down'
#     --bind='ctrl-b:preview-page-up'
#     --bind='ctrl-a:select-all'
#     --bind='ctrl-d:deselect-all'
#     --bind='change:first'
#     --color=fg:#c0caf5,bg:#1a1b26,hl:#bb9af7
#     --color=fg+:#c0caf5,bg+:#292e42,hl+:#7dcfff
#     --color=info:#7aa2f7,prompt:#7dcfff,pointer:#7dcfff
#     --color=marker:#9ece6a,spinner:#9ece6a,header:#9ece6a
# "

# # File preview configuration
# export FZF_PREVIEW_COMMAND="bat --style=numbers,changes --color=always --line-range :500 {}"

# # Directory preview
# export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
# export FZF_ALT_C_OPTS="
#     --preview 'tree -C {} | head -200'
#     --bind 'ctrl-/:toggle-preview'
#     --header 'Jump to directory'
# "

# # File search configuration
# export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
# export FZF_CTRL_T_OPTS="
#     --preview '$FZF_PREVIEW_COMMAND'
#     --bind 'ctrl-/:toggle-preview'
#     --header 'Select files'
# "

# # History search configuration
# export FZF_CTRL_R_OPTS="
#     --preview 'echo {}'
#     --preview-window=down:3:wrap
#     --bind 'ctrl-/:toggle-preview'
#     --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'
#     --header 'Search command history'
#     --sort
#     --exact
# "

# # ========================================================================
# # FZF-Enhanced Functions
# # ========================================================================

# # Show and search aliases
# function falias() {
#     alias | fzf --multi \
#         --preview 'echo {}' \
#         --header 'Aliases' | awk '{print $0}'
# }

# # Git checkout with FZF
# function fgco() {
#     local branches branch
#     branches=$(git branch --all | grep -v HEAD) &&
#         branch=$(echo "$branches" |
#             fzf-tmux -d 15 --no-multi) &&
#         git checkout $(echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")
# }

# # Git add with FZF
# function fga() {
#     local files
#     files=$(git -c color.status=always status --short |
#         fzf --ansi --multi --preview 'git diff --color=always {2}' |
#         cut -c4- |
#         sed 's/.* -> //')

#     if [[ -n "$files" ]]; then
#         git add ${files}
#         git status --short
#     fi
# }

# # Process management with FZF
# function fkill() {
#     local pid
#     pid=$(ps -ef | sed 1d |
#         fzf -m --header='Kill process' |
#         awk '{print $2}')

#     if [[ -n "$pid" ]]; then
#         echo "$pid" | xargs kill -${1:-9}
#         echo "Process(es) killed"
#     fi
# }

# # Find file and open in editor
# function fnvim() {
#     local file
#     file=$(find ${1:-.} -type f -not -path "*/node_modules/*" -not -path "*/\.git/*" -not -path "*/.venv/*" 2>/dev/null |
#         fzf +m --header='Open in editor') &&
#         ${EDITOR:-nvim} "$file"
# }

# # Open man pages with FZF
# function fman() {
#     man -k . |
#         fzf --prompt='Man> ' \
#             --preview 'echo {} | cut -d" " -f1 | xargs -I% man %' \
#             --preview-window=right:70% \
#             --bind='ctrl-/:toggle-preview' \
#             --header='View man pages' |
#         awk '{print $1}' | xargs -r man
# }

# # Docker container management
# function fdocker() {
#     local container
#     container=$(docker ps --format "{{.Names}}" |
#         fzf --preview 'docker stats --no-stream {}' \
#             --header 'Select container')

#     if [[ -n "$container" ]]; then
#         docker exec -it "$container" bash
#     fi
# }

# # Port process killer with FZF
# function fport() {
#     local port_pid
#     port_pid=$(lsof -i -P -n | grep LISTEN |
#         fzf --preview 'echo {}' \
#             --preview-window=down:3:wrap \
#             --bind='ctrl-/:toggle-preview' \
#             --header='Kill process on port' |
#         awk '{print $2}')

#     if [[ -n "$port_pid" ]]; then
#         echo "Killing process $port_pid..."
#         kill -9 "$port_pid"
#     fi
# }

# # Enhanced file search with ripgrep and FZF
# function frg() {
#     local file line
#     read -r file line <<<"$(rg --line-number --no-heading --color=always --smart-case "$@" |
#         fzf --ansi \
#             --color "hl:-1:underline,hl+:-1:underline:reverse" \
#             --delimiter : \
#             --preview "bat --style=numbers --color=always --highlight-line {2} {1}" \
#             --preview-window "right,60%,border-left,+{2}+3/3,~3" \
#             --bind='ctrl-/:toggle-preview' \
#             --header='Search in files with ripgrep')"

#     if [[ -n "$file" ]]; then
#         ${EDITOR:-nvim} "$file" +"$line"
#     fi
# }

# # Interactive brew install with FZF
# function fbin() {
#     local packages
#     packages=$(brew search |
#         fzf --multi \
#             --preview 'brew info {}' \
#             --header 'Install packages')

#     if [[ -n "$packages" ]]; then
#         echo "$packages" | xargs brew install
#     fi
# }

# # Interactive brew uninstall with FZF
# function fbrm() {
#     local packages
#     packages=$(brew leaves |
#         fzf --multi \
#             --preview 'brew info {}' \
#             --header 'Remove packages')

#     if [[ -n "$packages" ]]; then
#         echo "$packages" | xargs brew uninstall
#     fi
# }

# # Advanced git log browser
# function fglog() {
#     local filter
#     if [[ -n "$1" ]]; then
#         filter="--author=$1"
#     fi

#     git log --graph --color=always --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" $filter |
#         fzf --ansi --no-sort --reverse --tiebreak=index \
#             --preview 'f() { set -- $(echo -- "$@" | grep -o "[a-f0-9]\{7\}"); [ $# -eq 0 ] || git show --color=always $1; }; f {}' \
#             --preview-window=right:60% \
#             --bind='ctrl-/:toggle-preview' \
#             --header='Browse git log' \
#             --bind='enter:execute:
#         (grep -o "[a-f0-9]\{7\}" | head -1 |
#         xargs -I % sh -c "git show --color=always % | less -R") <<< {}'
# }

# # NPM script runner
# function fnr() {
#     local script
#     script=$(cat package.json | jq -r '.scripts | to_entries | .[] | .key' |
#         fzf --preview 'cat package.json | jq -r .scripts.{}' \
#             --preview-window=right:60% \
#             --bind='ctrl-/:toggle-preview' \
#             --header='Run npm script')

#     if [[ -n "$script" ]]; then
#         echo "Running 'npm run $script'..."
#         npm run "$script"
#     fi
# }

# # Load FZF completion and key bindings if available
# [[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh
