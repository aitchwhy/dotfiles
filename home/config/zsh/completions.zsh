

# -----------------------------------------------------
# Completion system configuration
# -----------------------------------------------------
# ~/dotfiles/home/zsh/completions.zsh - Completion system
# Load completion system
autoload -Uz compinit
if [[ -n ${ZDOTDIR}/.zcompdump(#qN.mh+24) ]]; then
    compinit -d "${ZDOTDIR}/.zcompdump"
else
    compinit -C -d "${ZDOTDIR}/.zcompdump"
fi

# Add Homebrew completions to fpath
fpath=(
    ${HOMEBREW_PREFIX}/share/zsh/site-functions
    ${HOMEBREW_PREFIX}/share/zsh-completions
    $fpath
)

# Completion styles
zstyle ':completion:*' menu select
zstyle ':completion:*' group-name ''
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME}/zsh/zcompcache"