# Performance monitoring (uncomment to debug startup time)
# zmodload zsh/zprof

# Shell Options
setopt AUTO_CD              # Change directory without cd
setopt AUTO_PUSHD           # Push directory to stack on cd
setopt PUSHD_IGNORE_DUPS    # Don't store duplicates in stack
setopt PUSHD_SILENT         # Don't print stack after pushd/popd
setopt EXTENDED_GLOB        # Extended globbing
setopt INTERACTIVE_COMMENTS # Allow comments in interactive shells
setopt NO_CASE_GLOB         # Case insensitive globbing

# History Options
setopt EXTENDED_HISTORY       # Record timestamp
setopt HIST_EXPIRE_DUPS_FIRST # Delete duplicates first
setopt HIST_IGNORE_DUPS       # Don't record duplicates
setopt HIST_VERIFY            # Don't execute immediately upon history expansion
setopt SHARE_HISTORY          # Share history between sessions
setopt HIST_IGNORE_SPACE      # Don't record commands starting with space

# Completions
# source "$ZDOTDIR/conf.d/completions.zsh"
autoload -U compinit
compinit

# Vi Mode Configuration
bindkey -v

# (keybindings) Maintain some emacs-style bindings in vi mode
bindkey '^P' up-line-or-history
bindkey '^N' down-line-or-history
bindkey '^E' end-of-line
bindkey '^A' beginning-of-line
bindkey '^?' backward-delete-char


# History configuration
export HISTFILE="$ZDOTDIR/history"
export HISTSIZE=1000000
export SAVEHIST=1000000

# Core paths
export DOTFILES="$HOME/dotfiles"

# Go configuration
export GOPATH="$HOME/go"
export GOBIN="$GOPATH/bin"

export _ZO_DATA_DIR="$XDG_DATA_HOME/zoxide"
export VOLTA_HOME="$HOME/.volta"



# Load plugins if available
# Plugin installation path
source "$DOTFILES/utils.sh"


PLUGIN_DIR="$HOMEBREW_PREFIX/share"
# ensure_dir "$PLUGIN_DIR"
plugins=(
    "zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
    "zsh-autosuggestions/zsh-autosuggestions.zsh"
    # "zsh-abbr/zsh-abbr.zsh"
)
for plugin in $plugins; do
    plugin_path="$PLUGIN_DIR/$plugin"
    if [[ ! -f "$plugin_path" ]]; then
        echo "no zsh plugin file at $plugin_path... skipping..."
    else
        source "$plugin_path"
    fi
done
# source $(brew --prefix)/share/zsh/site-functions/_todoist_fzf

# -----------------------------------------------------------------------------
# Initialize tools if installed
# -----------------------------------------------------------------------------
# (( $+commands[fzf] )) && eval "$( init zsh)" + fzf -> https://junegunn.github.io/fzf/shell-integration/

# setup_zsh() {
#   ensure_dir "$ZDOTDIR"
#   setup_zshenv
#
#   make_link "$DOTFILES/config/zsh/.zshrc" "$ZDOTDIR/.zshrc"
#   make_link "$DOTFILES/config/zsh/.zprofile" "$ZDOTDIR/.zprofile"
#   make_link "$DOTFILES/config/zsh/aliases.zsh" "$ZDOTDIR/aliases.zsh"
#   make_link "$DOTFILES/config/zsh/functions.zsh" "$ZDOTDIR/functions.zsh"
#   make_link "$DOTFILES/config/zsh/fzf.zsh" "$ZDOTDIR/fzf.zsh"
# }

has_command starship && eval "$(starship init zsh)"
has_command atuin && eval "$(atuin init zsh)"
has_command zoxide && eval "$(zoxide init zsh)"
has_command atuin && eval "$(atuin init zsh)"
# has_command uv && eval "$(uv generate-shell-completion zsh)"
# has_command direnv && eval "$(direnv hook zsh)"

# has_command nvim && export EDITOR="nvim"

# Initialize tools if installed
# (( $+commands[fzf] )) && eval "$( init zsh)" + fzf -> https://junegunn.github.io/fzf/shell-integration/
# (( $+commands[fzf] )) && eval "$(starship init zsh)"
# (( $+commands[fzf] )) && source <(fzf --zsh) # eval "$(starship init zsh)"
# (( $+commands[starship] )) && eval "$(starship init zsh)"
# (( $+commands[atuin] )) && eval "$(atuin init zsh --disable-up-arrow)"
# (( $+commands[atuin] )) && eval "$(atuin init zsh --disable-ctrl-r)"
# (( $+commands[atuin] )) && eval "$(atuin init zsh)"
# Initialize zsh-abbr if installed
# (( $+commands[abbr] )) && eval "$(abbr init zsh)"
# (( $+commands[zoxide] )) && eval "$(zoxide init zsh)"
# (( $+commands[fnm] )) && eval "$(fnm env --use-on-cd)"

# pyenv
# (( $+commands[pyenv] )) && eval "$(pyenv init -)"

# uv
# (( $+commands[uv] ))  && eval "$(uv generate-shell-completion zsh)"

# # Python (pyenv)
# if command -v pyenv >/dev/null; then
#     eval "$(pyenv init -)"
# fi

# ruby (https://mac.install.guide/ruby/13)
if [ -d "/opt/homebrew/opt/ruby/bin" ]; then
  export PATH=/opt/homebrew/opt/ruby/bin:$PATH
  export PATH=`gem environment gemdir`/bin:$PATH
fi

# utils
# source "$ZDOTDIR/fzf.zsh"
# source "$ZDOTDIR/functions.zsh"
# source "$ZDOTDIR/aliases.zsh"
