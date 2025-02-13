############################
# Consolidated Zsh configuration for interactive shells
# Organized for performance and clarity
############################

# source "$HOME/dotfiles/scripts/utils.sh"


# # Helper functions
# _load_if_exists() 
#     local cmd="$1"
#     local setup_cmd="$2"
#
#     if command -v "$cmd" > /dev/null; then
#         eval "$setup_cmd"
#     fi
# }
#
# _load_config_if_exists() {
#     local config="$1"
#     [[ -f "$config" ]] && source "$config"
# }

# ============================================================================ #
# .zshenv
# ============================================================================ #

# # ====== Environment Variables ======
# # XDG Base Directory Specification
# export XDG_CONFIG_HOME="$HOME/.config"
# export XDG_CACHE_HOME="$HOME/.cache"
# export XDG_DATA_HOME="$HOME/.local/share"
# export XDG_STATE_HOME="$HOME/.local/state"

# # Ensure directories exist
# mkdir -p "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME/zsh"

# # Tool configurations
# export LANG=en_US.UTF-8
# export EDITOR="nvim"
# export VISUAL="nvim"

# export STARSHIP_CONFIG="$XDG_CONFIG_HOME/starship/starship.toml"
# export ATUIN_CONFIG_DIR="$XDG_CONFIG_HOME/atuin"
# export ZELLIJ_CONFIG_DIR="$XDG_CONFIG_HOME/zellij"
# # export VOLTA_HOME="$HOME/.volta"

# # export BAT_CONFIG_PATH="$XDG_CONFIG_HOME/bat/config"
# # export RIPGREP_CONFIG_PATH="$XDG_CONFIG_HOME/ripgrep/config"
# # default command for fzf
# export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git --exclude node_modules --exclude target'
# # export FZF_DEFAULT_COMMAND='rg --files --no-ignore-vcs --hidden'

# # Default options
# export FZF_DEFAULT_OPTS="
#   --height 80% 
#   --layout=reverse 
#   --border sharp
#   --preview 'bat --style=numbers,changes --color=always --line-range :500 {}' 
#   --preview-window='right:60%:border-left'
#   --bind='ctrl-/:toggle-preview'
#   --bind='ctrl-y:execute-silent(echo {} | pbcopy)'
#   --bind='ctrl-e:execute(nvim {} < /dev/tty > /dev/tty)'
#   --bind='ctrl-f:preview-page-down'
#   --bind='ctrl-b:preview-page-up'
#   --color=fg:#c0caf5,bg:#1a1b26,hl:#bb9af7
#   --color=fg+:#c0caf5,bg+:#292e42,hl+:#7dcfff
#   --color=info:#7aa2f7,prompt:#7dcfff,pointer:#7dcfff
#   --color=marker:#9ece6a,spinner:#9ece6a,header:#9ece6a
# "

# #############
# # History search (CTRL-R) + atuin
# # Paste the selected command from history onto the command-line
# #
# # If you want to see the commands in chronological order, press CTRL-R again which toggles sorting by relevance
# # Press CTRL-/ to toggle line wrapping and see the whole command
# #
# # Set FZF_CTRL_R_OPTS to pass additional options to fzf
# # CTRL-Y to copy the command into clipboard using pbcopy
# #############

# # History search (CTRL-R) - Integrated with Atuin
# export FZF_CTRL_R_OPTS="
#   --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'
#   --color header:italic
#   --header 'CTRL-Y: Copy | CTRL-R: Toggle sort'
#   --border-label='Command History'"

# #############
# # Dir+File search (CTRL-T)
# # Preview file content using bat (https://github.com/sharkdp/bat)
# #
# # Paste the selected files and directories onto the command-line
# #
# # The list is generated using --walker file,dir,follow,hidden option
# # You can override the behavior by setting FZF_CTRL_T_COMMAND to a custom command that generates the desired list
# # Or you can set --walker* options in FZF_CTRL_T_OPTS
# # Set FZF_CTRL_T_OPTS to pass additional options to fzf
# #############
# export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
# export FZF_CTRL_T_OPTS="
#   --walker-skip .git,node_modules,target,.cache
#   --preview 'bat -n --color=always {}'
#   --bind 'ctrl-/:change-preview-window(down|hidden|)'
#   --border-label='Files'"

# #############
# # Directory navigation (ALT-C) (cd into the selected directory)
# #
# # The list is generated using --walker dir,follow,hidden option
# # Set FZF_ALT_C_COMMAND to override the default command
# # Or you can set --walker-* options in FZF_ALT_C_OPTS
# # Set FZF_ALT_C_OPTS to pass additional options to fzf
# #
# # Print tree structure in the preview window
# #############
# export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git --exclude node_modules --exclude target'
# export FZF_ALT_C_OPTS="
#   --walker-skip .git,node_modules,target,.cache
#   --preview 'tree -C {} | head -200'
#   --border-label='Directories'"



# # Zoxide configuration
# export _ZO_DATA_DIR="${XDG_DATA_HOME}/zoxide"


# # Enable TF metal acceleration
# export METAL_DEVICE_WRAPPER_TYPE=1
# export TF_ENABLE_METAL=1

# # History configuration
# export HISTFILE="$XDG_STATE_HOME/zsh/history"
# export HISTSIZE=10000
# export SAVEHIST=10000

# # Runs in all sessions
# export CARGO_HOME="$HOME/.cargo"
# export CLICOLOR=1
# export GOPATH="$HOME/go"
# if [[ -d "$CARGO_HOME" ]]; then
#     source "$HOME/.cargo/env"
# fi

# ============================================================================ #
# .zprofile
# ============================================================================ #

# ====== Path Configuration ======
# # Initialize Homebrew (this also sets up PATH)
# if [[ -x /opt/homebrew/bin/brew ]]; then
#     eval "$(/opt/homebrew/bin/brew shellenv)"
#     # Use /opt/homebrew if on Apple Silicon
#     # export HOMEBREW_PREFIX="/opt/homebrew"
#     # export PATH="$HOMEBREW_PREFIX/bin:$PATH"
# fi


# # Brew bundle - https://docs.brew.sh/Manpage#bundle-subcommand
# # global bundle file location
# export HOMEBREW_BUNDLE_FILE="~/.Brewfile"
# export HOMEBREW_BUNDLE_INSTALL_CLEANUP=1
# export HOMEBREW_BUNDLE_DUMP_DESCRIBE=0


# # Additional PATH entries (only add if they exist and aren't already in PATH)
# typeset -U path  # Ensure unique entries
# local additional_paths=(
#     "$HOME/.local/bin"
#     # "/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
#     "$CARGO_HOME/bin"
#     "$GOPATH/bin"
#     "$PYENV_ROOT/bin"
#     "$HOMEBREW_PREFIX/rustup/bin"
# )

# # export PATH="/opt/homebrew/opt/rustup/bin:$PATH"

# for p in $additional_paths; do
#     if [[ -d "$p" ]] && [[ ":$PATH:" != *":$p:"* ]]; then
#         path+=("$p")
#     fi
# done


# ============================================================================ #
# .zshrc
# ============================================================================ #

source "${DOTFILES_DIR:-$HOME/dotfiles}/scripts/symlinks.sh"


# Performance profiling (uncomment to debug slow startup)
# zmodload zsh/zprof

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

# https://docs.brew.sh/Shell-Completion#configuring-completions-in-zsh
# Initialize completions for Homebrew and installed packages
# if type brew &>/dev/null; then
#     FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
#
#     # Load brew-installed completions
#     local completion_file
#     for completion_file in "$(brew --prefix)/share/zsh/site-functions"/_*; do
#         if [[ -f "$completion_file" ]]; then
#             source "$completion_file"
#         fi
#     done
# fi

# Load Homebrew completions
if type brew &>/dev/null; then
    FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
fi

# Initialize completion system
autoload -Uz compinit
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
    compinit
else
    compinit -C
fi

# Load all configuration files
for conf in "$ZDOTDIR"/conf.d/*.zsh; do
    source "$conf"
done

# Load plugins and tools
_load_brew_plugin() {
    local plugin_name="$1"
    local plugin_path="$(brew --prefix)/share/zsh-${plugin_name}/${plugin_name}.zsh"
    if [[ -f "$plugin_path" ]]; then
        source "$plugin_path"
    else
        echo "Warning: Plugin $plugin_name not found at $plugin_path"
    fi
}

# Load essential plugins
_load_brew_plugin "syntax-highlighting"
_load_brew_plugin "autosuggestions"

# Initialize tools if installed
# (( $+commands[fzf] )) && eval "$( init zsh)" + fzf -> https://junegunn.github.io/fzf/shell-integration/
source <(fzf --zsh)

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
(( $+commands[uv] ))  && eval "$(uv generate-shell-completion zsh)"


# # Python (pyenv)
# if command -v pyenv >/dev/null; then
#     eval "$(pyenv init -)"
# fi




# Source aliases and functions
source "$XDG_CONFIG_HOME/zsh/aliases.zsh"
source "$XDG_CONFIG_HOME/zsh/functions.zsh"



zprof  # End profiling
