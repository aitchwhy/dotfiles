# Navigation
alias j='z'  # zoxide
alias jh='z -'  # jump back
alias jc='z -c' # constrained search

# Editor
alias v='nvim'
alias vc='nvim ~/.config/nvim/'

# System
alias ls='eza --group-directories-first --icons'
alias ll='eza -l --git --icons --group-directories-first'
alias tree='eza --tree --level=2 --icons'
alias cat='bat --pager "less -FR"'
alias grep='rg --smart-case'
alias find='fd'

# Git
alias g='git'
alias ga='git add'
alias gc='git commit'
alias gs='git status -sb'
alias gl='git pull'
alias gp='git push'
alias gd='git diff'
alias lg='lazygit'

# Package Management
alias brewup='brew update && brew upgrade && brew cleanup'
alias npmi='npm install --cache ${XDG_CACHE_HOME}/npm'

# Process Management
alias k9='k9s --readonly'

# Terminal Multiplexing
alias zj='zellij -l ~/.config/zellij/layouts/default.kdl'

# Documentation
alias cht='cheat'
alias tldr='tldr --color always'

# Network
alias http='xh'
alias https='xh --https'