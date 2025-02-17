# Shell Options
setopt AUTO_CD              # Change directory without cd
setopt AUTO_PUSHD          # Push directory to stack on cd
setopt PUSHD_IGNORE_DUPS   # Don't store duplicates in stack
setopt PUSHD_SILENT        # Don't print stack after pushd/popd
setopt EXTENDED_GLOB       # Extended globbing
setopt INTERACTIVE_COMMENTS # Allow comments in interactive shells
setopt NO_CASE_GLOB        # Case insensitive globbing

# History Options
setopt EXTENDED_HISTORY       # Record timestamp
setopt HIST_EXPIRE_DUPS_FIRST # Delete duplicates first
setopt HIST_IGNORE_DUPS       # Don't record duplicates
setopt HIST_VERIFY           # Don't execute immediately upon history expansion
setopt SHARE_HISTORY         # Share history between sessions
setopt HIST_IGNORE_SPACE     # Don't record commands starting with space

# Completion styling
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
_comp_options+=(globdots)   # Include hidden files
