
# Performance monitoring (uncomment to debug startup time)
# zmodload zsh/zprof

# Load core configurations
source "$ZDOTDIR/conf.d/options.zsh"
source "$ZDOTDIR/conf.d/keybindings.zsh"
source "$ZDOTDIR/conf.d/aliases.zsh"
source "$ZDOTDIR/conf.d/functions.zsh"
source "$ZDOTDIR/conf.d/keybindings.zsh"
source "$ZDOTDIR/conf.d/fzf.zsh"
source "$ZDOTDIR/conf.d/fzf-extended.zsh"
source "$ZDOTDIR/conf.d/completions.zsh"

# Initialize completion system
autoload -Uz compinit
if [[ -n ${ZDOTDIR}/.zcompdump(#qN.mh+24) ]]; then
    compinit -d "$XDG_CACHE_HOME/zsh/zcompdump-$ZSH_VERSION";
else
    compinit -C -d "$XDG_CACHE_HOME/zsh/zcompdump-$ZSH_VERSION";
fi;

# Initialize tools if installed
(( $+commands[starship] )) && eval "$(starship init zsh)"
(( $+commands[atuin] )) && eval "$(atuin init zsh)"
(( $+commands[zoxide] )) && eval "$(zoxide init zsh)"
(( $+commands[direnv] )) && eval "$(direnv hook zsh)"
(( $+commands[zsh-abbr] )) && eval "$(zsh-abbr init)"

# Load Homebrew completions
if type brew &>/dev/null; then
    FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
fi

# Load plugins (via Homebrew)
source "$(/opt/homebrew/bin/brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
source "$(/opt/homebrew/bin/brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"

# Performance monitoring (uncomment to debug startup time)
# zprof

########################## END

# #
# # # ============================================================================ #
# # # .zshenv
# # # ============================================================================ #
# # export XDG_CONFIG_HOME="$HOME/.config"
# # export XDG_CACHE_HOME="$HOME/.cache"
# # export XDG_DATA_HOME="$HOME/.local/share"
# # export XDG_STATE_HOME="$HOME/.local/state"
#
# # # Ensure directories exist
# # mkdir -p "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME/zsh"
#
# export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
# export DOTFILES="$HOME/dotfiles"
# export CONFIGS="$XDG_CONFIG_HOME"
#
# # Starhip Config file https://starship.rs/config/#config-file-location
# export STARSHIP_CONFIG="$XDG_CONFIG_HOME/starship.toml"
#
# # starship logging
# export STARSHIP_CACHE="$XDG_CONFIG_HOME/cache"
# export ATUIN_CONFIG_DIR="$XDG_CONFIG_HOME/atuin"
# export ZELLIJ_CONFIG_DIR="$XDG_CONFIG_HOME/zellij"
#
# # export VOLTA_HOME="$HOME/.volta"
# export BAT_CONFIG_PATH="$XDG_CONFIG_HOME/bat/config"
# export RIPGREP_CONFIG_PATH="$XDG_CONFIG_HOME/ripgrep/config"
#
# # History configuration
# export HISTFILE="$XDG_STATE_HOME/zsh/history"
# export HISTSIZE=10000
# export SAVEHIST=10000
#
# # # Metal acceleration for ML/TensorFlow
# # export METAL_DEVICE_WRAPPER_TYPE=1
# # export TF_ENABLE_METAL=1
#
# # Zoxide data location
# export _ZO_DATA_DIR="$XDG_DATA_HOME/zoxide"
#
# # Homebrew
# export HOMEBREW_BUNDLE_INSTALL_CLEANUP=1
# export HOMEBREW_BUNDLE_DUMP_DESCRIBE=0
#
#
# export EDITOR=nvim
# export PAGER=bat
# export MANPAGER=bat
#
# # ============================================================================ #
# # .zprofile
# # ============================================================================ #
# # ====== Path Configuration ======
# # # Initialize Homebrew (this also sets up PATH)
# # if [[ -x /opt/homebrew/bin/brew ]]; then
# #     eval "$(/opt/homebrew/bin/brew shellenv)"
# #     # Use /opt/homebrew if on Apple Silicon
# #     # export HOMEBREW_PREFIX="/opt/homebrew"
# #     # export PATH="$HOMEBREW_PREFIX/bin:$PATH"
# # fi
# # # Brew bundle - https://docs.brew.sh/Manpage#bundle-subcommand
# # # global bundle file location
# # export HOMEBREW_BUNDLE_FILE="~/.Brewfile"
# # export HOMEBREW_BUNDLE_INSTALL_CLEANUP=1
# # export HOMEBREW_BUNDLE_DUMP_DESCRIBE=0
# # # Additional PATH entries (only add if they exist and aren't already in PATH)
# # typeset -U path  # Ensure unique entries
# # local additional_paths=(
# #     "$HOME/.local/bin"
# #     # "/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
# #     "$CARGO_HOME/bin"
# #     "$GOPATH/bin"
# #     "$PYENV_ROOT/bin"
# #     "$HOMEBREW_PREFIX/rustup/bin"
# # )
# # # export PATH="/opt/homebrew/opt/rustup/bin:$PATH"
# # for p in $additional_paths; do
# #     if [[ -d "$p" ]] && [[ ":$PATH:" != *":$p:"* ]]; then
# #         path+=("$p")
# #     fi
# # done
#
# # ============================================================================ #
# # .zshrc
# # ============================================================================ #
#
# autoload -Uz compinit
# compinit
#
# # ====== Core Shell Options ======
# setopt AUTO_CD              # Change directory without cd
# setopt EXTENDED_GLOB        # Extended globbing
# setopt NOTIFY              # Report status of background jobs immediately
# setopt PROMPT_SUBST        # Enable parameter expansion in prompts
# setopt INTERACTIVE_COMMENTS # Allow comments in interactive shells
#
# # History options
# setopt HIST_IGNORE_DUPS    # Don't record duplicated entries in history
# setopt HIST_REDUCE_BLANKS  # Remove unnecessary blanks from history
# setopt HIST_VERIFY         # Don't execute immediately upon history expansion
# setopt SHARE_HISTORY       # Share history between sessions
#
#
# # ====== Vi Mode Configuration ======
# bindkey -v
# export KEYTIMEOUT=1
#
# # Maintain some emacs-style bindings in vi mode
# # bindkey '^P' up-line-or-history
# # bindkey '^N' down-line-or-history
# bindkey '^A' beginning-of-line
# bindkey '^E' end-of-line
# # bindkey '^?' backward-delete-char
#
# # ====== Completion System ======
#
#
# # Load plugins and tools
# _load_brew_plugin() {
#     local plugin_name="$1"
#     local plugin_path="$(brew --prefix)/share/${plugin_name}/${plugin_name}.zsh"
#     if [[ -f "$plugin_path" ]]; then
#         source "$plugin_path"
#     else
#         echo "Warning: Plugin $plugin_name not found at $plugin_path"
#     fi
# }
#
# # Load essential plugins
# _load_brew_plugin "zsh-syntax-highlighting"
# _load_brew_plugin "zsh-autosuggestions"
#
# # source $(brew --prefix)/share/zsh/site-functions/_todoist_fzf
#
#
#
# # Source aliases and functions
# source "$HOME/dotfiles/config/zsh/aliases.zsh"
# source "$HOME/dotfiles/config/zsh/functions.zsh"
# source "$HOME/dotfiles/config/zsh/fzf.zsh"
#
#
# # Initialize tools if installed
# # (( $+commands[fzf] )) && eval "$( init zsh)" + fzf -> https://junegunn.github.io/fzf/shell-integration/
#
# # (( $+commands[fzf] )) && eval "$(starship init zsh)"
# (( $+commands[fzf] )) && source <(fzf --zsh) # eval "$(starship init zsh)"
#
#
#
#
# # Initialize starship prompt if installed
# (( $+commands[starship] )) && eval "$(starship init zsh)"
#
# # Initialize atuin if installed (with up arrow disabled due to vi mode)
# # (( $+commands[atuin] )) && eval "$(atuin init zsh --disable-up-arrow)"
# # (( $+commands[atuin] )) && eval "$(atuin init zsh --disable-ctrl-r)"
# (( $+commands[atuin] )) && eval "$(atuin init zsh)"
#
# # Initialize zsh-abbr if installed
# (( $+commands[abbr] )) && eval "$(abbr init zsh)"
#
# (( $+commands[zoxide] )) && eval "$(zoxide init zsh)"
#
#
# # (( $+commands[fnm] )) && eval "$(fnm env --use-on-cd)"
#
# # Initialize zellij if installed and not already in a session
# # if (( $+commands[zellij] )) && [[ -z "$ZELLIJ" ]]; then
# #     eval "$(zellij setup --generate-auto-start zsh)"
# # fi
#
# # pyenv
# # (( $+commands[pyenv] )) && eval "$(pyenv init -)"
#
# # uv
# (( $+commands[uv] ))  && eval "$(uv generate-shell-completion zsh)"
#
#
# # # Python (pyenv)
# # if command -v pyenv >/dev/null; then
# #     eval "$(pyenv init -)"
# # fi
#
#
#



