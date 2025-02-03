# Load plugins using built-in ZSH methods
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /opt/homebrew/share/zsh-abbr/zsh-abbr.zsh
source /opt/homebrew/share/zsh-history-substring-search/zsh-history-substring-search.zsh

# Initialize tools
eval "$(zoxide init zsh)"
eval "$(atuin init zsh)"
eval "$(direnv hook zsh)"