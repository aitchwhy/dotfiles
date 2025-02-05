# Load custom functions
source "${ZDOTDIR}/functions.zsh"

# History settings
HISTSIZE=50000
SAVEHIST=10000
setopt extended_history
setopt hist_expire_dups_first
setopt hist_ignore_dups
setopt hist_ignore_space
setopt hist_verify
setopt inc_append_history
setopt share_history

# Directory options
setopt auto_cd
setopt auto_pushd
setopt pushd_ignore_dups
setopt pushd_minus

# Load configurations
for conf in "${ZDOTDIR}"/{env,aliases,completions}.zsh; do
    source "${conf}"
done

# Initialize antidote
source ${ZDOTDIR}/.antidote/antidote.zsh
antidote load ${ZDOTDIR}/plugins.txt

# Load tool configurations
load_if_exists "starship" "starship init zsh"
load_if_exists "direnv" "direnv hook zsh"
load_if_exists "atuin" "atuin init zsh"
load_if_exists "zoxide" "zoxide init zsh"

# Keybindings
bindkey -e  # emacs key bindings
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word

# Load optional configurations
load_config_if_exists "${ZDOTDIR}/.fzf.zsh"
load_config_if_exists "${ZDOTDIR}/local.zsh"





# # -----------------------------------------------------
# # Key Bindings
# # -----------------------------------------------------
# bindkey -v  # Vi mode
# bindkey '^[[1;5C' forward-word
# bindkey '^[[1;5D' backward-word
# bindkey '^H' backward-kill-word
# bindkey '^[[3;5~' kill-word

# # -----------------------------------------------------
# # Aliases
# # -----------------------------------------------------
# # Modern CLI replacements
# has_command bat && alias cat='bat --paging=never'
# has_command eza && {
#     alias ls='eza --icons --group-directories-first'
#     alias ll='eza -l --git --icons --group-directories-first'
#     alias la='eza -la --git --icons --group-directories-first'
#     alias lt='eza --tree --icons --group-directories-first'
# }
# has_command rg && alias grep='rg'
# has_command fd && alias find='fd'
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

# # Editor
# alias v='nvim'
# alias vc='nvim ~/.config/nvim/'

# # -----------------------------------------------------
# # Tool Initialization (Early)
# # -----------------------------------------------------
# # Initialize starship first for prompt
# if [[ -x "$(command -v starship)" ]]; then
#     eval "$(starship init zsh)"
# else
#     echo "Warning: starship not found. Please install with 'brew install starship'"
# fi

# # Other tool initializations
# eval "$(zoxide init zsh)"
# eval "$(atuin init zsh)"
# eval "$(direnv hook zsh)"

# # -----------------------------------------------------
# # Plugin System
# # -----------------------------------------------------
# # Load plugins if they exist
# local plugins=(
#     "/opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
#     "/opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
#     "/opt/homebrew/share/zsh-abbr/zsh-abbr.zsh"
# )

# for plugin in $plugins; do
#     [[ -f $plugin ]] && source $plugin
# done

# # -----------------------------------------------------
# # Load Custom Functions
# # -----------------------------------------------------
# [[ -f "${ZDOTDIR}/functions.zsh" ]] && source "${ZDOTDIR}/functions.zsh"

# # -----------------------------------------------------
# # Local Configuration
# # -----------------------------------------------------
# # Load local overrides if they exist
# [[ -f "${ZDOTDIR}/local.zsh" ]] && source "${ZDOTDIR}/local.zsh"

