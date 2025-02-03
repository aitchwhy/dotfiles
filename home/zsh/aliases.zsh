

# -----------------------------------------------------
# Command aliases
# -----------------------------------------------------

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


# # Check if command exists helper
# has_command() { command -v "$1" >/dev/null; }

# ## Enhanced ls (if eza available)
# #has_command eza && {
# #  alias ll='eza -l --git --icons --group-directories-first'
# #  alias la='eza -la --git --icons --group-directories-first'
# #  alias lt='eza --tree --icons --group-directories-first'
# #  alias l='eza -F --icons --group-directories-first'
# #}

# # Modern CLI replacements
# has_command bat && alias cat='bat --paging=never'
# has_command eza && alias ls='eza --icons --group-directories-first'
# has_command rg && alias grep='rg'
# has_command fd && alias find='fd'
# has_command bottom && alias top='btm'
# has_command dust && alias du='dust'
# has_command duf && alias df='duf'
# has_command zoxide && alias cd='z'

# # Git shortcuts
# alias gs='git status'
# alias ga='git add'
# alias gc='git commit'
# alias gp='git push'
# alias gl='git pull'
# has_command lazygit && alias lg='lazygit'

# # Navigation
# alias ..='cd ..'
# alias ...='cd ../..'
# alias ....='cd ../../..'
# alias -- -='cd -'

# # Package management
# alias brewup='brew update && brew upgrade && brew cleanup'
# alias npmi='npm install --cache ${XDG_CACHE_HOME}/npm'

# # Navigation
# alias j='z'  # zoxide
# alias jh='z -'  # jump back
# alias jc='z -c' # constrained search

# # Editor
# alias v='nvim'
# alias vc='nvim ~/.config/nvim/'

# # System
# alias ls='eza --group-directories-first --icons'
# alias ll='eza -l --git --icons --group-directories-first'
# alias tree='eza --tree --level=2 --icons'
# alias cat='bat --pager "less -FR"'
# alias grep='rg --smart-case'
# alias find='fd'


# # Process Management
# alias k9='k9s --readonly'

# # Terminal Multiplexing
# alias zj='zellij -l ~/.config/zellij/layouts/default.kdl'

# # Documentation
# alias cht='cheat'
# alias tldr='tldr --color always'

# # Network
# alias http='xh'
# alias https='xh --https'
