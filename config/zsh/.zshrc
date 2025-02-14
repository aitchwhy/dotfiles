# ============================================================================ #
# .zshrc
# ============================================================================ #

# ====== Core Shell Options ======
setopt AUTO_CD              # Change directory without cd
setopt EXTENDED_GLOB        # Extended globbing
setopt NOTIFY              # Report status of background jobs immediately
setopt PROMPT_SUBST        # Enable parameter expansion in prompts
setopt INTERACTIVE_COMMENTS # Allow comments in interactive shells

# History options
setopt HIST_IGNORE_DUPS    # Don't record duplicated entries in history
setopt HIST_REDUCE_BLANKS  # Remove unnecessary blanks from history
setopt HIST_VERIFY         # Don't execute immediately upon history expansion
setopt SHARE_HISTORY       # Share history between sessions


# ====== Vi Mode Configuration ======
bindkey -v
export KEYTIMEOUT=1

# Maintain some emacs-style bindings in vi mode
bindkey '^P' up-line-or-history
bindkey '^N' down-line-or-history
bindkey '^E' end-of-line
bindkey '^A' beginning-of-line
bindkey '^?' backward-delete-char

# ====== Completion System ======


# Load plugins and tools
_load_brew_plugin() {
    local plugin_name="$1"
    local plugin_path="$(brew --prefix)/share/${plugin_name}/${plugin_name}.zsh"
    if [[ -f "$plugin_path" ]]; then
        source "$plugin_path"
    else
        echo "Warning: Plugin $plugin_name not found at $plugin_path"
    fi
}

# Load essential plugins
_load_brew_plugin "zsh-syntax-highlighting"
_load_brew_plugin "zsh-autosuggestions"

# source $(brew --prefix)/share/zsh/site-functions/_todoist_fzf




# Source aliases and functions
source "$HOME/dotfiles/config/zsh/aliases.zsh"
source "$HOME/dotfiles/config/zsh/functions.zsh"
source "$HOME/dotfiles/config/zsh/fzf.zsh"


# Initialize tools if installed
# (( $+commands[fzf] )) && eval "$( init zsh)" + fzf -> https://junegunn.github.io/fzf/shell-integration/

# (( $+commands[fzf] )) && eval "$(starship init zsh)"
(( $+commands[fzf] )) && source <(fzf --zsh) # eval "$(starship init zsh)"


# Initialize starship prompt if installed
(( $+commands[starship] )) && eval "$(starship init zsh)"

# Initialize atuin if installed (with up arrow disabled due to vi mode)
# (( $+commands[atuin] )) && eval "$(atuin init zsh --disable-up-arrow)"
# (( $+commands[atuin] )) && eval "$(atuin init zsh --disable-ctrl-r)"
(( $+commands[atuin] )) && eval "$(atuin init zsh)"

# Initialize zsh-abbr if installed
(( $+commands[abbr] )) && eval "$(abbr init zsh)"

(( $+commands[zoxide] )) && eval "$(zoxide init zsh)"


# (( $+commands[fnm] )) && eval "$(fnm env --use-on-cd)"

# Initialize zellij if installed and not already in a session
# if (( $+commands[zellij] )) && [[ -z "$ZELLIJ" ]]; then
#     eval "$(zellij setup --generate-auto-start zsh)"
# fi

# pyenv
# (( $+commands[pyenv] )) && eval "$(pyenv init -)"

# uv
# (( $+commands[uv] ))  && eval "$(uv generate-shell-completion zsh)"


# # Python (pyenv)
# if command -v pyenv >/dev/null; then
#     eval "$(pyenv init -)"
# fi





# zprof  # End profiling

