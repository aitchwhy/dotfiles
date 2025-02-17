# Use vi mode
bindkey -v
export KEYTIMEOUT=1

# Emacs-style bindings even in vi mode
bindkey '^A' beginning-of-line
bindkey '^E' end-of-line
bindkey '^K' kill-line
bindkey '^U' backward-kill-line
bindkey '^W' backward-kill-word
bindkey '^Y' yank
bindkey '^?' backward-delete-char
bindkey '^H' backward-delete-char
bindkey '^[[3~' delete-char

# History navigation
bindkey '^P' up-history
bindkey '^N' down-history
bindkey '^R' history-incremental-search-backward

# Menu completion
bindkey '^I' expand-or-complete-prefix
bindkey '^[[Z' reverse-menu-complete

# Edit command in editor
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line

# Quote current argument
autoload -Uz quote-word
zle -N quote-word
bindkey '\e"' quote-word

# URL quote magic
autoload -Uz url-quote-magic
zle -N self-insert url-quote-magic

# Better word navigation
export WORDCHARS='*?_-.[]~=&;!#$%^(){}<>'
bindkey '^[[1;5D' backward-word
bindkey '^[[1;5C' forward-word

# Incremental search with arrows
bindkey '^[[A' history-beginning-search-backward
bindkey '^[[B' history-beginning-search-forward

# Directory navigation
bindkey -s '^O' 'lfcd\n'
bindkey -s '^G' 'fzf-cd-widget\n'

# Additional utility bindings
bindkey -s '^F' 'ff\n'       # File search
bindkey -s '^B' 'fbm\n'      # Bookmark search
bindkey -s '^V' 'fcode\n'    # VSCode project search
######### END

# # Use vi mode
# bindkey -v
# export KEYTIMEOUT=1
#
# # Use modern completion system
# autoload -Uz compinit
# compinit
#
# # Emacs-style bindings even in vi mode
# bindkey '^A' beginning-of-line
# bindkey '^E' end-of-line
# bindkey '^?' backward-delete-char
# bindkey '^w' backward-kill-word
# bindkey '^h' backward-delete-char
# bindkey '^r' history-incremental-search-backward
#
# # Edit command in editor
# autoload -Uz edit-command-line
# zle -N edit-command-line
# bindkey '^x^e' edit-command-line
