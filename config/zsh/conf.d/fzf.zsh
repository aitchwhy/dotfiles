
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
fbrew() {
    local packages
    packages=$(brew search | \
        fzf --multi \
            --preview 'brew info {}' \
            --header 'Install packages')
    
    [ -n "$packages" ] && echo "$packages" | xargs brew install
}

# Interactive brew uninstall
fbrewrm() {
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

# Load fzf completion and key bindings
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

##################### END
#
# # Base FZF configuration
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
#
# # File preview configuration
# export FZF_PREVIEW_COMMAND="bat --style=numbers,changes --color=always --line-range :500 {}"
#
# # Directory preview
# export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
# export FZF_ALT_C_OPTS="
#     --preview 'tree -C {} | head -200'
#     --bind 'ctrl-/:toggle-preview'
#     --header 'Jump to directory'
# "
#
# # File search configuration
# export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
# export FZF_CTRL_T_OPTS="
#     --preview '$FZF_PREVIEW_COMMAND'
#     --bind 'ctrl-/:toggle-preview'
#     --header 'Select files'
# "
#
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
#
# # FZF Functions
#
# # Enhanced file search
# ff() {
#     local file
#     file=$(fd --type f --hidden --follow --exclude .git | \
#         fzf --preview "$FZF_PREVIEW_COMMAND" \
#             --header 'Open file in editor')
#
#     [ -n "$file" ] && ${EDITOR:-nvim} "$file"
# }
#
# # Enhanced directory search
# fd() {
#     local dir
#     dir=$(fd --type d --hidden --follow --exclude .git | \
#         fzf --preview 'tree -C {} | head -200' \
#             --header 'Change directory')
#
#     [ -n "$dir" ] && cd "$dir"
# }
#
# # Git functions
# # Interactive git add
# fga() {
#     local files
#     files=$(git status -s | \
#         fzf --multi \
#             --preview 'git diff --color=always {2}' \
#             --header 'Stage files' | \
#         awk '{print $2}')
#
#     [ -n "$files" ] && echo "$files" | xargs git add
# }
#
# # Interactive git checkout file
# fgco() {
#     local files
#     files=$(git ls-files -m | \
#         fzf --multi \
#             --preview 'git diff --color=always {}' \
#             --header 'Checkout files' )
#
#     [ -n "$files" ] && echo "$files" | xargs git checkout
# }
#
# # Git log browser
# fgl() {
#     git log --graph --color=always \
#         --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" |
#     fzf --ansi --no-sort --reverse --tiebreak=index \
#         --preview 'f() { set -- $(echo -- "$@" | grep -o "[a-f0-9]\{7\}"); [ $# -eq 0 ] || git show --color=always $1; }; f {}' \
#         --header 'Browse git log' \
#         --bind "ctrl-m:execute:
#                 (grep -o '[a-f0-9]\{7\}' | head -1 |
#                 xargs -I % sh -c 'git show --color=always % | less -R') << 'FZF-EOF'
#                 {}
#                 FZF-EOF"
# }
#
# # Process management
# fkill() {
#     local pid
#     pid=$(ps -ef | sed 1d | \
#         fzf --multi \
#             --preview 'echo {}' \
#             --header 'Kill processes' | \
#         awk '{print $2}')
#
#     [ -n "$pid" ] && echo "$pid" | xargs kill -${1:-9}
# }
#
# # Homebrew functions
# # Interactive brew install
# fbrew() {
#     local packages
#     packages=$(brew search | \
#         fzf --multi \
#             --preview 'brew info {}' \
#             --header 'Install packages')
#
#     [ -n "$packages" ] && echo "$packages" | xargs brew install
# }
#
# # Interactive brew uninstall
# fbrewrm() {
#     local packages
#     packages=$(brew leaves | \
#         fzf --multi \
#             --preview 'brew info {}' \
#             --header 'Remove packages')
#
#     [ -n "$packages" ] && echo "$packages" | xargs brew uninstall
# }
#
# # Docker functions
# # Container management
# fdocker() {
#     local container
#     container=$(docker ps --format "{{.Names}}" | \
#         fzf --preview 'docker stats --no-stream {}' \
#             --header 'Select container')
#
#     [ -n "$container" ] && docker exec -it "$container" bash
# }
#
# # VSCode projects
# fcode() {
#     local dir
#     dir=$(fd --type d --max-depth 3 --exclude node_modules --exclude .git | \
#         fzf --preview 'tree -C {} | head -200' \
#             --header 'Open in VSCode')
#
#     [ -n "$dir" ] && code "$dir"
# }
#
# # Chrome bookmarks search
# fbm() {
#     local bookmarks_path="$HOME/Library/Application Support/Google/Chrome/Default/Bookmarks"
#
#     if [[ ! -f "$bookmarks_path" ]]; then
#         echo "Chrome Bookmarks file not found"
#         return 1
#     fi
#
#     local jq_script='
#         def ancestors: while(. | length >= 2; del(.[-1,-2]));
#         . as $root | paths(try .url catch false) as $path | $path | . as $p |
#         $root | getpath($p) | {name,url, path: [$p[0:-2] | ancestors as $a | $root | getpath($a) | .name?] | reverse | join("/") } | .path + "/" + .name + "\t" + .url
#     '
#
#     local bookmark_url=$(jq -r "$jq_script" < "$bookmarks_path" | \
#         sed -E 's/\t/│/g' | \
#         fzf --delimiter='│' \
#             --with-nth=1 \
#             --preview-window=hidden \
#             --header 'Open bookmark' | \
#         cut -d'│' -f2)
#
#     [ -n "$bookmark_url" ] && open "$bookmark_url"
# }
#
# # Load fzf completion and key bindings
# [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
#
# #############################
# # Additional FZF Functions and Utilities
# # FZF Git utilities
# # Enhanced git checkout branch with preview
# fgb() {
#     local branches branch
#     branches=$(git branch --all --color=always | grep -v HEAD) &&
#     branch=$(echo "$branches" | fzf --ansi \
#         --preview='git log --oneline --graph --date=short --color=always --pretty="format:%C(auto)%cd %h%d %s" $(sed s/^..// <<< {} | cut -d" " -f1)' \
#         --preview-window=right:60% \
#         --bind='ctrl-/:toggle-preview' \
#         --header='Checkout git branch') &&
#     git checkout $(echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")
# }
#
# # Git stash operations
# fstash() {
#     local out q k sha
#     while out=$(
#         git stash list --pretty="%C(yellow)%h %>(14)%Cgreen%cr %C(blue)%gs" |
#         fzf --ansi \
#             --no-sort \
#             --query="$q" \
#             --preview='git stash show --color=always -p $(cut -d" " -f1 <<< {})' \
#             --preview-window=right:60% \
#             --bind='ctrl-/:toggle-preview' \
#             --header='Git stash operations' \
#             --print-query \
#             --expect=ctrl-a,ctrl-p,ctrl-d);
#     do
#         q=$(head -1 <<< "$out")
#         k=$(head -2 <<< "$out" | tail -1)
#         sha=$(grep -o '[a-f0-9]\{7\}' <<< "$out" | head -1)
#         [ -z "$sha" ] && continue
#         case "$k" in
#             ctrl-a) git stash apply $sha ;;
#             ctrl-p) git stash pop $sha ;;
#             ctrl-d) git stash drop $sha ;;
#         esac
#     done
# }
#
# # Advanced git log browser
# fglog() {
#     local filter
#     if [ -n "$1" ]; then
#         filter="--author=$1"
#     fi
#     git log --graph --color=always --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" $filter |
#     fzf --ansi --no-sort --reverse --tiebreak=index \
#         --preview 'f() { set -- $(echo -- "$@" | grep -o "[a-f0-9]\{7\}"); [ $# -eq 0 ] || git show --color=always $1; }; f {}' \
#         --preview-window=right:60% \
#         --bind='ctrl-/:toggle-preview' \
#         --header='Browse git log' \
#         --bind='enter:execute:
#             (grep -o "[a-f0-9]\{7\}" | head -1 |
#             xargs -I % sh -c "git show --color=always % | less -R") <<< {}'
# }
#
# # NPM script runner
# fnr() {
#     local script
#     script=$(cat package.json | jq -r '.scripts | to_entries | .[] | .key' |
#         fzf --preview 'cat package.json | jq -r .scripts.{}' \
#             --preview-window=right:60% \
#             --bind='ctrl-/:toggle-preview' \
#             --header='Run npm script')
#     if [ -n "$script" ]; then
#         echo "Running 'npm run $script'..."
#         npm run "$script"
#     fi
# }
#
# # Enhanced man page viewer
# fman() {
#     man -k . | fzf --prompt='Man> ' \
#         --preview 'echo {} | cut -d" " -f1 | xargs -I% man %' \
#         --preview-window=right:70% \
#         --bind='ctrl-/:toggle-preview' \
#         --header='View man pages' |
#     awk '{print $1}' | xargs -r man
# }
#
# # Homebrew cask installer
# fcask() {
#     local token
#     token=$(brew search --casks | fzf --preview 'brew info --cask {}' \
#         --preview-window=right:60% \
#         --bind='ctrl-/:toggle-preview' \
#         --header='Install Homebrew cask')
#     if [ -n "$token" ]; then
#         echo "Installing cask $token..."
#         brew install --cask "$token"
#     fi
# }
#
# # Directory history navigation
# fz() {
#     local dir
#     dir=$(z -l | awk '{print $2}' | fzf --preview 'tree -C {} | head -200' \
#         --preview-window=right:60% \
#         --bind='ctrl-/:toggle-preview' \
#         --header='Jump to directory from history')
#     if [ -n "$dir" ]; then
#         cd "$dir"
#     fi
# }
#
# # VSCode workspace selector
# fvscode() {
#     local workspace
#     workspace=$(fd -e code-workspace . "$HOME/Development" | 
#         fzf --preview 'cat {}' \
#             --preview-window=right:60% \
#             --bind='ctrl-/:toggle-preview' \
#             --header='Open VSCode workspace')
#     if [ -n "$workspace" ]; then
#         code "$workspace"
#     fi
# }
#
# # Environment variable explorer
# fenv() {
#     local var
#     var=$(env | sort | fzf --preview 'echo {}' \
#         --preview-window=down:3:wrap \
#         --bind='ctrl-/:toggle-preview' \
#         --header='Explore environment variables')
#     if [ -n "$var" ]; then
#         echo "$var" | pbcopy
#         echo "Copied to clipboard: $var"
#     fi
# }
#
# # Port process killer
# fport() {
#     local port_pid
#     port_pid=$(lsof -i -P -n | grep LISTEN | 
#         fzf --preview 'echo {}' \
#             --preview-window=down:3:wrap \
#             --bind='ctrl-/:toggle-preview' \
#             --header='Kill process on port' | 
#         awk '{print $2}')
#     if [ -n "$port_pid" ]; then
#         echo "Killing process $port_pid..."
#         kill -9 "$port_pid"
#     fi
# }
#
# # Kubernetes context switcher
# fkctx() {
#     local context
#     context=$(kubectl config get-contexts --no-headers | 
#         fzf --preview 'kubectl config get-contexts {}' \
#             --preview-window=right:60% \
#             --bind='ctrl-/:toggle-preview' \
#             --header='Switch Kubernetes context' |
#         awk '{print $1}')
#     if [ -n "$context" ]; then
#         kubectl config use-context "$context"
#     fi
# }
#
# # Dotfiles editor
# fdot() {
#     local file
#     file=$(fd --type f . "$DOTFILES/config" | 
#         fzf --preview 'bat --style=numbers --color=always {}' \
#             --preview-window=right:60% \
#             --bind='ctrl-/:toggle-preview' \
#             --header='Edit dotfiles')
#     if [ -n "$file" ]; then
#         ${EDITOR:-nvim} "$file"
#     fi
# }
#
# # HTTP status code lookup
# fhttp() {
#     local code
#     code=$(cat "$DOTFILES/config/zsh/data/http_status_codes.txt" |
#         fzf --preview 'echo {}' \
#             --preview-window=down:3:wrap \
#             --bind='ctrl-/:toggle-preview' \
#             --header='HTTP status codes')
#     if [ -n "$code" ]; then
#         echo "$code" | pbcopy
#         echo "Copied to clipboard: $code"
#     fi
# }
#
# # Color picker
# fcolor() {
#     local color
#     color=$(cat "$DOTFILES/config/zsh/data/colors.txt" |
#         fzf --preview 'echo {}' \
#             --preview-window=down:3:wrap \
#             --bind='ctrl-/:toggle-preview' \
#             --header='Color codes')
#     if [ -n "$color" ]; then
#         echo "$color" | pbcopy
#         echo "Copied to clipboard: $color"
#     fi
# }
#
# # Enhanced file search with rg and preview
# frg() {
#     local file line
#     read -r file line <<<"$(rg --line-number --no-heading --color=always --smart-case "$@" |
#         fzf --ansi \
#             --color "hl:-1:underline,hl+:-1:underline:reverse" \
#             --delimiter : \
#             --preview "bat --style=numbers --color=always --highlight-line {2} {1}" \
#             --preview-window "right,60%,border-left,+{2}+3/3,~3" \
#             --bind='ctrl-/:toggle-preview' \
#             --header='Search in files with ripgrep')"
#     if [ -n "$file" ]; then
#         ${EDITOR:-nvim} "$file" +"$line"
#     fi
# }
#
#
# ###################### END
#
# # # Enhanced FZF utilities
# #
# # # Base FZF configuration
# # # default command for fzf
# # export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
# # # export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git --exclude node_modules --exclude .venv'
# # # export FZF_DEFAULT_COMMAND='fd --type f  --hidden --follow --exclude .git --exclude node_modules --exclude target'
# # # export FZF_DEFAULT_COMMAND='rg --files --no-ignore-vcs --hidden'
# # export FZF_DEFAULT_OPTS="
# #     --height 80% 
# #     --layout=reverse 
# #     --border sharp
# # #   --preview 'bat --style=numbers,changes --color=always --line-range :500 {}' 
# #     --preview-window='right:60%:border-left'
# #     --bind='ctrl-/:toggle-preview'
# #     --bind='ctrl-y:execute-silent(echo {} | pbcopy)'
# #     --bind='ctrl-e:execute(nvim {} < /dev/tty > /dev/tty)'
# #     --bind='ctrl-f:preview-page-down'
# #     --bind='ctrl-b:preview-page-up'
# #     --bind='ctrl-a:select-all'
# #     --bind='ctrl-d:deselect-all'
# #     --color=fg:#c0caf5,bg:#1a1b26,hl:#bb9af7
# # "
# #
# #
# # # fzf completion options -> https://github.com/junegunn/fzf?tab=readme-ov-file#fuzzy-completion-for-bash-and-zsh
# # # Options to fzf command
# # export FZF_COMPLETION_OPTS='--border --info=inline'
# #
# # # Options for path completion (e.g. vim **<TAB>)
# # export FZF_COMPLETION_PATH_OPTS='--walker file,dir,follow,hidden'
# #
# # # Options for directory completion (e.g. cd **<TAB>)
# # export FZF_COMPLETION_DIR_OPTS='--walker dir,follow'
# #
# # # File preview configuration
# # export FZF_PREVIEW_COMMAND="bat --style=numbers,changes --color=always --line-range :500 {}"
# #
# #
# # #############
# # # Directory navigation (ALT-C) (cd into the selected directory)
# # #
# # # The list is generated using --walker dir,follow,hidden option
# # # Set FZF_ALT_C_COMMAND to override the default command
# # # Or you can set --walker-* options in FZF_ALT_C_OPTS
# # # Set FZF_ALT_C_OPTS to pass additional options to fzf
# # #
# # # Print tree structure in the preview window
# # #############
# # # Directory preview
# # export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git --exclude node_modules'
# # export FZF_ALT_C_OPTS="
# #   --preview 'tree -C {} | head -200'
# #   --border-label='cd -> dir Search'"
# #
# # # export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git --exclude node_modules --exclude target'
# # # export FZF_ALT_C_OPTS="
# # #   --walker-skip .git,node_modules,target,.cache
# # #   --preview 'tree -C {} | head -200'
# # #   --border-label='Directories'"
# #
# #
# #
# # #############
# # # Dir+File search (CTRL-T)
# # # Preview file content using bat (https://github.com/sharkdp/bat)
# # #
# # # Paste the selected files and directories onto the command-line
# # #
# # # The list is generated using --walker file,dir,follow,hidden option
# # # You can override the behavior by setting FZF_CTRL_T_COMMAND to a custom command that generates the desired list
# # # Or you can set --walker* options in FZF_CTRL_T_OPTS
# # # Set FZF_CTRL_T_OPTS to pass additional options to fzf
# # #############
# #
# # # CTRL-T configuration
# # export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
# # export FZF_CTRL_T_OPTS="
# #   --preview '$FZF_PREVIEW_COMMAND'
# #   --border-label='File'"
# # # export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
# # # export FZF_CTRL_T_OPTS="
# # #   --walker-skip .git,node_modules,target,.cache
# # #   --preview 'bat -n --color=always {}'
# # #   --bind 'ctrl-/:change-preview-window(down|hidden|)'
# # #   --border-label='Files'"
# #
# # # # Default options
# # # export FZF_DEFAULT_OPTS="
# # #   --height 80% 
# # #   --layout=reverse 
# # #   --border sharp
# # #   --preview 'bat --style=numbers,changes --color=always --line-range :500 {}' 
# # #   --preview-window='right:60%:border-left'
# # #   --bind='ctrl-/:toggle-preview'
# # #   --bind='ctrl-y:execute-silent(echo {} | pbcopy)'
# # #   --bind='ctrl-e:execute(nvim {} < /dev/tty > /dev/tty)'
# # #   --bind='ctrl-f:preview-page-down'
# # #   --bind='ctrl-b:preview-page-up'
# # #   --color=fg:#c0caf5,bg:#1a1b26,hl:#bb9af7
# # #   --color=fg+:#c0caf5,bg+:#292e42,hl+:#7dcfff
# # #   --color=info:#7aa2f7,prompt:#7dcfff,pointer:#7dcfff
# # #   --color=marker:#9ece6a,spinner:#9ece6a,header:#9ece6a
# # # "
# #
# # #############
# # # History search (CTRL-R) + atuin
# # # Paste the selected command from history onto the command-line
# # #
# # # If you want to see the commands in chronological order, press CTRL-R again which toggles sorting by relevance
# # # Press CTRL-/ to toggle line wrapping and see the whole command
# # #
# # # Set FZF_CTRL_R_OPTS to pass additional options to fzf
# # # CTRL-Y to copy the command into clipboard using pbcopy
# # #############
# #
# # # History search (CTRL-R) - Integrated with Atuin
# # # export FZF_CTRL_R_OPTS="
# # #   --preview 'echo {}' --preview-window down:3:hidden:wrap --bind '?:toggle-preview'
# # #   --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'
# # #   --color header:italic
# # #   --header 'CTRL-Y: Copy | CTRL-R: Toggle sort'
# # #   --border-label='Command History'"
# #
# #
# # # History search
# # export FZF_CTRL_R_OPTS="
# #     --preview 'echo {}' 
# #     --preview-window=down:3:wrap
# #     --bind='?:toggle-preview'
# #     --bind='ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'
# #     --header='CTRL-Y: Copy Command | ?: Toggle Preview'
# #     --border-label='Command History'
# # "
# # # Load fzf keybindings
# # # source "$(brew --prefix)/opt/fzf/shell/key-bindings.zsh"
# #
# #
# # ####################################
# # # Utils
# # ####################################
# # ####################################
# #
# # # ~/.config/zsh/functions/fzf-utils.zsh
# # # Dependencies: fzf, ripgrep (rg), git (optional), docker (optional), brew (optional)
# #
# #
# # # Enhanced file search
# # ff() {
# #     local file
# #     file=$(fd --type f --hidden --follow --exclude .git | \
# #         fzf --preview "$FZF_PREVIEW_COMMAND")
# #     [[ -n "$file" ]] && ${EDITOR:-nvim} "$file"
# # }
# #
# # # Enhanced directory search
# # fd() {
# #     local dir
# #     dir=$(fd --type d --hidden --follow --exclude .git | \
# #         fzf --preview 'tree -C {} | head -200')
# #     [[ -n "$dir" ]] && cd "$dir"
# # }
# #
# # # Homebrew FZF integration
# # fbrew() {
# #     local inst=$(brew search | fzf -m --preview 'brew info {}')
# #     if [[ $inst ]]; then
# #         for prog in $(echo $inst); do
# #             brew install $prog
# #         done
# #     fi
# # }
# #
# # fbd() {
# #   local inst=$(brew list | fzf -m)
# #   if [[ -n "$inst" ]]; then
# #     for prog in $(echo "$inst"); do
# #       brew uninstall "$prog"
# #     done
# #   fi
# # }
# #
# # # Git FZF integrations
# # # Checkout git branch
# # fgb() {
# #     local branches branch
# #     branches=$(git branch -a --color=always | grep -v '/HEAD\s') &&
# #     branch=$(echo "$branches" |
# #         fzf --ansi --preview-window=right:70% \
# #             --preview 'git log --oneline --graph --date=short --color=always --pretty="format:%C(auto)%cd %h%d %s" $(sed s/^..// <<< {} | cut -d" " -f1)' |
# #         sed 's/^..//' | cut -d' ' -f1)
# #     [[ -n "$branch" ]] && git checkout $(echo "$branch" | sed "s#remotes/[^/]*/##")
# # }
# #
# # # Git status files
# # fgs() {
# #     local files
# #     files=$(git status -s | fzf --multi --preview 'git diff --color=always {2}' | awk '{print $2}')
# #     [[ -n "$files" ]] && echo "$files" | xargs git add
# # }
# #
# # # Git log browser
# # fgl() {
# #     git log --graph --color=always \
# #         --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" |
# #     fzf --ansi --no-sort --reverse --tiebreak=index \
# #         --preview 'f() { set -- $(echo -- "$@" | grep -o "[a-f0-9]\{7\}"); [ $# -eq 0 ] || git show --color=always $1; }; f {}' \
# #         --bind "ctrl-m:execute:
# #                 (grep -o '[a-f0-9]\{7\}' | head -1 |
# #                 xargs -I % sh -c 'git show --color=always % | less -R') << 'FZF-EOF'
# #                 {}
# # FZF-EOF"
# # }
# #
# # # VSCode project search
# # fcode() {
# #     local dir
# #     dir=$(fd --type d --max-depth 3 --exclude node_modules --exclude .git | \
# #         fzf --preview 'tree -C {} | head -200')
# #     [[ -n "$dir" ]] && code "$dir"
# # }
# #
# # # Enhanced process killer
# # fkill() {
# #     local pid
# #     pid=$(ps -ef | sed 1d | fzf -m --preview 'echo {}' | awk '{print $2}')
# #     if [ "x$pid" != "x" ]; then
# #         echo $pid | xargs kill -${1:-9}
# #     fi
# # }
# #
# # # Docker container management
# # fdocker() {
# #     local container
# #     container=$(docker ps --format '{{.Names}}' | \
# #         fzf --preview 'docker stats --no-stream {}')
# #     if [[ -n "$container" ]]; then
# #         docker exec -it "$container" bash
# #     fi
# # }
# #
# # # Search and edit configuration files
# # fcf() {
# #     local config_dirs=(
# #         "$XDG_CONFIG_HOME"
# #         "$HOME/.config"
# #         "$HOME/dotfiles/config"
# #     )
# #     local file
# #     file=$(fd . "${config_dirs[@]}" --type f --hidden --exclude .git | \
# #         fzf --preview "$FZF_PREVIEW_COMMAND")
# #     [[ -n "$file" ]] && ${EDITOR:-nvim} "$file"
# # }
# #
# # # Chrome bookmark search
# # fbm() {
# #     local bookmarks_path="$HOME/Library/Application Support/Google/Chrome/Default/Bookmarks"
# #
# #     if [[ ! -f "$bookmarks_path" ]]; then
# #         echo "Chrome Bookmarks file not found"
# #         return 1
# #     fi
# #
# #     local jq_script='
# #         def ancestors: while(. | length >= 2; del(.[-1,-2]));
# #         . as $root | paths(try .url catch false) as $path | $path | . as $p |
# #         $root | getpath($p) | {name,url, path: [$p[0:-2] | ancestors as $a | $root | getpath($a) | .name?] | reverse | join("/") } | .path + "/" + .name + "\t" + .url
# #     '
# #
# #     local bookmark_url=$(jq -r "$jq_script" < "$bookmarks_path" | \
# #         sed -E 's/\t/│/g' | \
# #         fzf --delimiter='│' --with-nth=1 --preview-window=hidden | \
# #         cut -d'│' -f2)
# #
# #     [[ -n "$bookmark_url" ]] && open "$bookmark_url"
# # }
# #
# # # Man page search
# # fman() {
# #     man -k . | fzf --preview "echo {} | cut -d' ' -f1 | xargs -I% man %" | \
# #         cut -d' ' -f1 | xargs -I% man %
# # }
# #
# # # Load FZF completion and key bindings
# # [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
# #
# #
# # ############## END
# #
# # # # Docker container management functions
# # # function dattach() {
# # #   local container=$(docker ps | sed 1d | fzf -q "$1" | awk '{print $1}')
# # #   if [[ -n "$container" ]]; then
# # #     docker attach "$container"
# # #   fi
# # # }
# # #
# # # function dstop() 
# #
# # # Define source -> destination mappings (source:destination pairs)
# # declare -a CONFIG_MAP=(
# # # Add more file or directory mappings as needed:
# # # "$DOTFILES/<app>:<target_path>"
# # "$DOTFILES/Brewfile:$HOME/.Brewfile"
# # "$DOTFILES/config/zsh:$XDG_CONFIG_HOME/zsh"
# # # "$DOTFILES/config/zsh/.zshrc:$XDG_CONFIG_HOME/zsh/.zshrc"
# # # "$DOTFILES/config/zsh/.zprofile:$XDG_CONFIG_HOME/zsh/.zprofile"
# # # "$DOTFILES/config/zsh/functions.zsh:$XDG_CONFIG_HOME/zsh/functions.zsh"
# # # "$DOTFILES/config/zsh/aliases.zsh:$XDG_CONFIG_HOME/zsh/aliases.zsh"
# # # "$DOTFILES/config/zsh/fzf.zsh:$XDG_CONFIG_HOME/zsh/fzf.zsh"
# # # "$DOTFILES/config/zsh/fzf.zsh:$XDG_CONFIG_HOME/zsh/fzf.zsh"
# #
# # "$DOTFILES/config/git/config:$XDG_CONFIG_HOME/git/config"
# # "$DOTFILES/config/git/ignore:$XDG_CONFIG_HOME/git/ignore"
# #
# # "$DOTFILES/config/atuin/config.toml:$XDG_CONFIG_HOME/atuin/config.toml"
# # "$DOTFILES/config/karabiner/karabiner.json:$XDG_CONFIG_HOME/karabiner/karabiner.json"
# # "$DOTFILES/config/ghostty/config:$XDG_CONFIG_HOME/ghostty/config"
# # "$DOTFILES/config/bat/config:$XDG_CONFIG_HOME/bat/config"
# # "$DOTFILES/config/starship/starship.toml:$XDG_CONFIG_HOME/starship/starship.toml"
# # "$DOTFILES/config/nvim:$XDG_CONFIG_HOME/nvim"
# #
# # "$DOTFILES/config/hammerspoon:$XDG_CONFIG_HOME/hammerspoon"
# #
# # "$DOTFILES/config/yazi:$XDG_CONFIG_HOME/yazi"
# # "$DOTFILES/config/zed:$XDG_CONFIG_HOME/zed"
# # "$DOTFILES/config/snippety:$XDG_CONFIG_HOME/snippety"
# #
# # "$DOTFILES/config/zsh-abbr/user-abbreviations:$XDG_CONFIG_HOME/zsh-abbr/user-abbreviations"
# #
# # "$DOTFILES/config/zellij/config.kdl:$XDG_CONFIG_HOME/zellij/config.kdl"
# # "$DOTFILES/config/zellij/layouts:$XDG_CONFIG_HOME/zellij/layouts"
# # "$DOTFILES/config/zellij/plugins:$XDG_CONFIG_HOME/zellij/plugins"
# #
# # "$DOTFILES/config/todoist/config.json:$XDG_CONFIG_HOME/todoist/config.json"
# #
# # "$DOTFILES/config/espanso:$XDG_CONFIG_HOME/espanso"
# #
# # "$DOTFILES/config/aide/keybindings.json:$HOME/Library/Application Support/Aide/User/keybindings.json"
# # "$DOTFILES/config/aide/settings.json:$HOME/Library/Application Support/Aide/User/settings.json"
# # "$DOTFILES/config/cursor/keybindings.json:$HOME/Library/Application Support/Cursor/User/keybindings.json"
# # "$DOTFILES/config/cursor/settings.json:$HOME/Library/Application Support/Cursor/User/settings.json"
# # "$DOTFILES/config/vscode/keybindings.json:$HOME/Library/Application Support/Code/User/keybindings.json"
# # "$DOTFILES/config/vscode/settings.json:$HOME/Library/Application Support/Code/User/settings.json"
# #
# # "$DOTFILES/ai/claude/claude_desktop_config.json:$HOME/Library/Application Support/Claude/claude_desktop_config.json"
# # "$DOTFILES/ai/config:$XDG_CONFIG_HOME/ai/config"
# # "$DOTFILES/ai/prompts:$XDG_CONFIG_HOME/ai/prompts"
# #
# # )
# # #   local container=$(docker ps | sed 1d | fzf -q "$1" | awk '{print $1}')
# # #   if [[ -n "$container" ]]; then
# # #     docker stop "$container"
# # #   fi
# # # }
# # #
# # # function drm() {
# # #   local container=$(docker ps -a | sed 1d | fzf -q "$1" | awk '{print $1}')
# # #   if [[ -n "$container" ]]; then
# # #     docker rm "$container"
# # #   fi
# # # }
# # #
# # # function drmi() {
# # #   local image=$(docker images | sed 1d | fzf -q "$1" | awk '{print $3}')
# # #   if [[ -n "$image" ]]; then
# # #     docker rmi "$image"
# # #   fi
# # # }
# # #
# # # # File search and edit functions
# # # function fse() {
# # #   if [ ! "$#" -gt 0 ]; then
# # #     echo "Need a string to search for!"
# # #     return 1
# # #   fi
# # #   rg --files-with-matches --no-messages "$1" | fzf --preview "highlight -O ansi -l {} 2> /dev/null | rg --colors 'match:bg:yellow' --ignore-case --pretty --context 10 '$1' || rg --ignore-case --pretty --context 10 '$1' {}"
# # # }
# #
# # # function fe() {
# # #   local file=$(fzf --preview 'bat --style=numbers --color=always --line-range :500 {}')
# # #   if [[ -n "$file" ]]; then
# # #     $EDITOR "$file"
# # #   fi
# # # }
# # #
# # # function fgrepe() {
# # #   if [[ $# == 0 ]]; then
# # #     echo 'Error: search term was not provided.'
# # #     return 1
# # #   fi
# # #   local match=$(rg --color=never --line-number "$1" | fzf --delimiter : \
# # #     --preview "bat --style=numbers --color=always --highlight-line {2} {1}" \
# # #     --preview-window=up,60%)
# # #   if [[ -n "$match" ]]; then
# # #     local file=$(echo "$match" | cut -d: -f1)
# # #     $EDITOR "$file" +$(echo "$match" | cut -d: -f2)
# # #   fi
# # # }
# # #
# # # # Git utilities
# # # function fgbr() {
# # #   git rev-parse HEAD > /dev/null 2>&1 || return
# # #
# # #   local branch=$(git branch --color=always | \
# # #     grep -v '/HEAD\s' | \
# # #     fzf --height 40% --ansi --preview-window right:70% \
# # #     --preview 'git log --oneline --graph --date=short --color=always --pretty="format:%C(auto)%cd %h%d %s" $(sed s/^..// <<< {} | cut -d" " -f1)' | \
# # #     sed 's/^..//' | cut -d' ' -f1)
# # #
# # #   if [[ -n "$branch" ]]; then
# # #     echo "$branch"
# # #   fi
# # # }
# # #
# # # function fgco() {
# # #   local branch=$(fzf-git-branch)
# # #   if [[ -n "$branch" ]]; then
# # #     git checkout "$branch"
# # #   fi
# # # }
# # # # VSCode integration
# # # function fcode() {
# # #   local file=$(rg --files | fzf --preview 'bat --style=numbers --color=always --line-range :500 {}')
# # #   if [[ -n "$file" ]]; then
# # #     code "$file"
# # #   fi
# # # }
# # # #!/usr/bin/env zsh
# # #
# # # # fzf-brew - Browse and install Homebrew formulae using fzf
# # # function fb() {
# # #   local inst=$(brew search | eval "fzf ${FZF_DEFAULT_OPTS} -m --header='[brew:install]'")
# # #
# # #   if [[ $inst ]]; then
# # #     for prog in $(echo $inst)
# # #     do brew install $prog
# # #     done
# # #   fi
# # # }
# # #
# # # # fzf-browse - Browse and cd into selected directory using fzf
# # # function fdir() {
# # #   local dir
# # #   dir=$(find ${1:-.} -path '*/\.*' -prune \
# # #                   -o -type d -print 2> /dev/null | fzf +m) &&
# # #   cd "$dir"
# # # }
# # #
# # # # fzf-find - Find files using fzf and fd/find
# # # function ffile() {
# # #   local file
# # #
# # #   file="$(
# # #     if type fd > /dev/null 2>&1; then
# # #       fd --type f --hidden --follow --exclude .git 2> /dev/null | fzf
# # #     else
# # #       find . -type f -not -path '*/\.git/*' 2> /dev/null | fzf
# # #     fi
# # #   )"
# # #
# # #   if [[ -n $file ]]; then
# # #     ${EDITOR:-vim} "$file"
# # #   fi
# # # }
