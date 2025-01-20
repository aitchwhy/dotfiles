#!/bin/zsh

#------------------------------------------------------------------------------
# Early Performance Settings
#------------------------------------------------------------------------------
skip_global_compinit=1

# Performance settings for Homebrew
export HOMEBREW_NO_ENV_HINTS=1
export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_BAT=1
export HOMEBREW_CURL_RETRIES=2
export HOMEBREW_NO_INSTALL_FROM_API=1
export HOMEBREW_NO_INSTALLED_DEPENDENTS_CHECK=1

# Set Zsh options early
setopt extended_glob
setopt HIST_REDUCE_BLANKS
setopt SHARE_HISTORY
setopt HIST_SAVE_NO_DUPS
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_VERIFY
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt EXTENDED_GLOB

#------------------------------------------------------------------------------
# Local Configuration
#------------------------------------------------------------------------------
[[ -f ~/.zshenv.local ]] && source ~/.zshenv.local

#------------------------------------------------------------------------------
# Environment Variables and XDG Base Directory
#------------------------------------------------------------------------------
export LANG='en_US.UTF-8'
export LC_ALL='en_US.UTF-8'

export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
export XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}
export XDG_CACHE_HOME=${XDG_CACHE_HOME:-$HOME/.cache}
export ZDOTDIR=${ZDOTDIR:-$XDG_CONFIG_HOME/zsh}

#------------------------------------------------------------------------------
# Editor and Pager Configuration
#------------------------------------------------------------------------------
export EDITOR='nvim'
export VISUAL='nvim'
export SUDO_EDITOR='nvim'

# Configure less and bat
export LESS='-R -i'
export LESSCHARSET=utf-8
export PAGER='bat --pager=always'
export MANPAGER="sh -c 'col -bx | bat --paging=always --language=man'"

#------------------------------------------------------------------------------
# History Configuration
#------------------------------------------------------------------------------
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000

#------------------------------------------------------------------------------
# Homebrew and Path Configuration
#------------------------------------------------------------------------------
# Set HOMEBREW_PREFIX based on architecture
if [[ "$(uname -m)" == "arm64" ]]; then
    export HOMEBREW_PREFIX="/opt/homebrew"
else
    export HOMEBREW_PREFIX="/usr/local"
fi

# Tool-specific paths
export BUN_INSTALL="$HOME/.bun"
export GLOBAL_PYTHON_VENV="$HOME/src/.python-global"

# Initialize path arrays without duplicates
typeset -gU path fpath

# Set path with priorities
path=(
    # Homebrew paths (highest priority)
    $HOMEBREW_PREFIX/{bin,sbin}(N)
    
    # System paths
    /usr/local/{bin,sbin}(N)
    $HOME/.local/{bin,sbin}(N)
    $HOME/{bin,sbin}(N)
    
    # Language/tool-specific paths
    $BUN_INSTALL/bin(N)
    $GLOBAL_PYTHON_VENV/bin(N)
    $HOME/.cargo/bin(N)
    $HOME/.deno/bin(N)
    $HOME/go/bin(N)
    
    # App-specific paths
    $HOME/.cache/lm-studio/bin(N)
    
    # System paths (lower priority)
    /usr/{bin,sbin}(N)
    /{bin,sbin}(N)
    
    # Existing paths
    $path
)

#------------------------------------------------------------------------------
# Homebrew Initialization
#------------------------------------------------------------------------------
if ! command -v brew >/dev/null; then
    echo "Homebrew not found. Please install from https://brew.sh"
    return 1
fi

eval "$($HOMEBREW_PREFIX/bin/brew shellenv)"

#------------------------------------------------------------------------------
# Plugin Configuration
#------------------------------------------------------------------------------
local brew_prefix=${HOMEBREW_PREFIX:-$(brew --prefix 2>/dev/null)}
local plugins=(
    zsh-syntax-highlighting
    zsh-autosuggestions
    zsh-autopair
    zsh-history-substring-search
)

for plugin in $plugins; do
    plugin_path="$brew_prefix/share/$plugin/$plugin.zsh"
    [[ -f $plugin_path ]] && source $plugin_path
done
unset plugins plugin plugin_path

#------------------------------------------------------------------------------
# Tool Configuration
#------------------------------------------------------------------------------
# FZF configuration
export FZF_DEFAULT_COMMAND="rg --files --hidden --follow --glob '!.git/*'"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers --color=always --line-range=:500 {}'"

#------------------------------------------------------------------------------
# Completion System
#------------------------------------------------------------------------------
fpath=(
    $HOMEBREW_PREFIX/share/zsh/site-functions
    $HOMEBREW_PREFIX/share/zsh-completions
    $fpath
)

autoload -Uz compinit
compinit

#------------------------------------------------------------------------------
# Development Tools Initialization
#------------------------------------------------------------------------------
# Node.js version manager (fnm)
eval "$(fnm env --use-on-cd --version-file-strategy recursive --shell zsh)"

# Bun JavaScript runtime
[ -s "$BUN_INSTALL/_bun" ] && source "$BUN_INSTALL/_bun"

# Python uv tool
eval "$(uv generate-shell-completion zsh)"

#------------------------------------------------------------------------------
# Shell Enhancements
#------------------------------------------------------------------------------
# Initialize enhanced tools
eval "$(zoxide init zsh)"
eval "$(atuin init zsh)"
eval "$(temporal completion zsh)"
eval "$(starship init zsh)"

#------------------------------------------------------------------------------
# Functions
#------------------------------------------------------------------------------
# Reload zsh configuration
function reload() {
    zs
    echo "Reloaded"
}

# FZF with bat preview
function fbat() {
    bat --paging=always "$1" | fzf
}

# Rebuild zsh completions
function rebuild_zsh_completions() {
    rm -f ~/.zcompdump; compinit
}

# Yazi file manager wrapper
function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}

#------------------------------------------------------------------------------
# Aliases
#------------------------------------------------------------------------------
# Modern alternatives
alias cat='bat --paging=always'
alias grep='rg'
alias find='fd'
alias md='glow'
alias ls='eza --icons'
alias ll='eza -l --icons'
alias la='eza -al --icons'

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias lg='lazygit'

# FZF enhanced commands
alias flog='fzf --preview "bat --style=numbers --color=always --line-range=:500 {}"'
alias falias='alias | fzf'
alias fman='man -k . | fzf --preview "man {}"'

# Homebrew aliases
alias b="brew"
alias bdr="brew doctor"
alias blk="brew leaves"
alias boc="brew outdated --cask"
alias bof="brew outdated --formula"
alias bupd="brew update"
alias bupg="brew upgrade"
alias bclean="brew cleanup --prune=all"
alias bcleanall='brew cleanup --prune=all && rm -rf $(brew --cache)'
alias bpull="bupd && bupg && bclean"
alias bin="brew install"
alias brein="brew reinstall"
alias bi="brew info"
alias bs="brew search"

# Homebrew Cask aliases
alias bcl="brew list --cask"
alias bcin="brew install --cask"
alias bcup="brew upgrade --cask"

# Homebrew Bundle aliases
alias bb="brew bundle"
alias bbls="brew bundle dump --all --file=- --verbose"
alias bbsave="brew bundle dump --all --verbose --global -f && chezmoi re-add ~/.Brewfile"
alias bbcheck="brew bundle check --all --global --verbose"

# Chezmoi (dotfile management)
alias cm="chezmoi"
alias cma="chezmoi add"
alias cmra="chezmoi re-add"
alias cmf="chezmoi forget"
alias cmap="chezmoi apply"
alias cmsrc="chezmoi source-path"
alias cmdst="chezmoi source-path"
alias cmls="chezmoi managed"

# Directory shortcuts
alias gdl='cd ~/Downloads'
alias gcf='cd ~/.config/'

# Python virtual environment
alias uvgn="uv venv $GLOBAL_PYTHON_VENV"
alias uvg="source $GLOBAL_PYTHON_VENV/bin/activate"

# Zsh configuration shortcuts
alias ze="chezmoi edit ~/.zshrc --apply && source ~/.zshrc"
alias zs="chezmoi apply -v ~/.zshrc && source ~/.zshrc"
alias zcompreset="rm -f ~/.zcompdump; compinit"

# Export GitHub credentials
export GITHUB_USER="aitchwhy"
export GITHUB_EMAIL="hank.lee.qed@gmail.com"

#------------------------------------------------------------------------------
# Homebrew and Path Configuration
#------------------------------------------------------------------------------
# Set HOMEBREW_PREFIX based on architecture
if [[ "$(uname -m)" == "arm64" ]]; then
    export HOMEBREW_PREFIX="/opt/homebrew"
else
    export HOMEBREW_PREFIX="/usr/local"
fi

# Tool-specific paths
export BUN_INSTALL="$HOME/.bun"
export GLOBAL_PYTHON_VENV="$HOME/src/.python-global"

# Initialize path arrays without duplicates
typeset -gU path fpath

# Set path with priorities
path=(
    # Homebrew paths (highest priority)
    $HOMEBREW_PREFIX/{bin,sbin}(N)
    
    # System paths
    /usr/local/{bin,sbin}(N)
    $HOME/.local/{bin,sbin}(N)
    $HOME/{bin,sbin}(N)
    
    # Language/tool-specific paths
    $BUN_INSTALL/bin(N)
    $GLOBAL_PYTHON_VENV/bin(N)
    $HOME/.cargo/bin(N)
    $HOME/.deno/bin(N)
    $HOME/go/bin(N)
    
    # App-specific paths
    $HOME/.cache/lm-studio/bin(N)
    
    # System paths (lower priority)
    /usr/{bin,sbin}(N)
    /{bin,sbin}(N)
    
    # Existing paths
    $path
)

#------------------------------------------------------------------------------
# Homebrew Initialization
#------------------------------------------------------------------------------
if ! command -v brew >/dev/null; then
    echo "Homebrew not found. Please install from https://brew.sh"
    return 1
fi

eval "$($HOMEBREW_PREFIX/bin/brew shellenv)"

#------------------------------------------------------------------------------
# Plugin Configuration
#------------------------------------------------------------------------------
local brew_prefix=${HOMEBREW_PREFIX:-$(brew --prefix 2>/dev/null)}
local plugins=(
    zsh-syntax-highlighting
    zsh-autosuggestions
    zsh-autopair
    zsh-history-substring-search
)

for plugin in $plugins; do
    plugin_path="$brew_prefix/share/$plugin/$plugin.zsh"
    [[ -f $plugin_path ]] && source $plugin_path
done
unset plugins plugin plugin_path

#------------------------------------------------------------------------------
# Tool Configuration
#------------------------------------------------------------------------------
# FZF configuration
export FZF_DEFAULT_COMMAND="rg --files --hidden --follow --glob '!.git/*'"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers --color=always --line-range=:500 {}'"

#------------------------------------------------------------------------------
# Completion System
#------------------------------------------------------------------------------
fpath=(
    $HOMEBREW_PREFIX/share/zsh/site-functions
    $HOMEBREW_PREFIX/share/zsh-completions
    $fpath
)

autoload -Uz compinit
compinit

#------------------------------------------------------------------------------
# Development Tools Initialization
#------------------------------------------------------------------------------
# Node.js version manager (fnm)
eval "$(fnm env --use-on-cd --version-file-strategy recursive --shell zsh)"

# Bun JavaScript runtime
[ -s "$BUN_INSTALL/_bun" ] && source "$BUN_INSTALL/_bun"

# Python uv tool
eval "$(uv generate-shell-completion zsh)"

#------------------------------------------------------------------------------
# Shell Enhancements
#------------------------------------------------------------------------------
# Initialize enhanced tools
eval "$(zoxide init zsh)"
eval "$(atuin init zsh)"
eval "$(temporal completion zsh)"
eval "$(starship init zsh)"

#------------------------------------------------------------------------------
# Functions
#------------------------------------------------------------------------------
# Reload zsh configuration
function reload() {
    zs
    echo "Reloaded"
}

# FZF with bat preview
function fbat() {
    bat --paging=always "$1" | fzf
}

# Rebuild zsh completions
function rebuild_zsh_completions() {
    rm -f ~/.zcompdump; compinit
}

# Yazi file manager wrapper
function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}

#------------------------------------------------------------------------------
# Aliases
#------------------------------------------------------------------------------
# Modern alternatives
alias cat='bat --paging=always'
alias grep='rg'
alias find='fd'
alias md='glow'
alias ls='eza --icons'
alias ll='eza -l --icons'
alias la='eza -al --icons'

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias lg='lazygit'

# FZF enhanced commands
alias flog='fzf --preview "bat --style=numbers --color=always --line-range=:500 {}"'
alias falias='alias | fzf'
alias fman='man -k . | fzf --preview "man {}"'

# Homebrew aliases
alias b="brew"
alias bdr="brew doctor"
alias blk="brew leaves"
alias boc="brew outdated --cask"
alias bof="brew outdated --formula"
alias bupd="brew update"
alias bupg="brew upgrade"
alias bclean="brew cleanup --prune=all"
alias bcleanall='brew cleanup --prune=all && rm -rf $(brew --cache)'
alias bpull="bupd && bupg && bclean"
alias bin="brew install"
alias brein="brew reinstall"
alias bi="brew info"
alias bs="brew search"

# Homebrew Cask aliases
alias bcl="brew list --cask"
alias bcin="brew install --cask"
alias bcup="brew upgrade --cask"

# Homebrew Bundle aliases
alias bb="brew bundle"
alias bbls="brew bundle dump --all --file=- --verbose"
alias bbsave="brew bundle dump --all --verbose --global -f && chezmoi re-add ~/.Brewfile"
alias bbcheck="brew bundle check --all --global --verbose"

# Chezmoi (dotfile management)
alias cm="chezmoi"
alias cma="chezmoi add"
alias cmra="chezmoi re-add"
alias cmf="chezmoi forget"
alias cmap="chezmoi apply"
alias cmsrc="chezmoi source-path"
alias cmdst="chezmoi source-path"
alias cmls="chezmoi managed"

# Directory shortcuts
alias gdl='cd ~/Downloads'
alias gcf='cd ~/.config/'

# Python virtual environment
alias uvgn="uv venv $GLOBAL_PYTHON_VENV"
alias uvg="source $GLOBAL_PYTHON_VENV/bin/activate"

# Zsh configuration shortcuts
alias ze="chezmoi edit ~/.zshrc --apply && source ~/.zshrc"
alias zs="chezmoi apply -v ~/.zshrc && source ~/.zshrc"
alias zcompreset="rm -f ~/.zcompdump; compinit"

# Export GitHub credentials
export GITHUB_USER="aitchwhy"
export GITHUB_EMAIL="hank.lee.qed@gmail.com"

######################
#
#
#!/bin/zsh

#--------------------------------------------------------
# Logical flow for code (zshenv + zprofile + zshrc altogether here)
#--------------------------------------------------------
# - Early Performance/Optimizations (like skip_global_compinit, zprof)
# - Locale Settings (LANG, LC_ALL)
# - Path Configurations (typeset -U path)
# - Editors and Paginated Tools Config (nvim, bat, fzf configurations)
# - Completion Configuration (compinit)
# - Tool Initializations like Homebrew, fnm, bun, uv
# - Load Homebrew environment first.
# - Shell Options/Enhancements (history, shell behaviors, zoxide, atuin, etc.)
# - Functions and Aliases
# - Final Commands or Misc Tools

# Explanation of Key Updates
# Path Configuration Cleanup:
#
# Centralized all paths into one path array declaration for cleaner handling. Removed duplicate or redundant export PATH statements.
# Editor and Pager Setup:
#
# Consolidated MANPAGER settings so you can choose between bat-enhanced showing of man pages or nvim (uncomment one).
# Completion Initialization:
#
# Deferred compinit to run later after all paths and editor settings are defined. This avoids unnecessary re-initialization.
# Tool Initializations and Conditional Loading:
#
# Included conditional checks for optional tools like bun and uv to only load them if present.
# Modularity:
#
# Suggested keeping large alias and function definitions in separate files like aliases.zsh and functions.zsh, allowing cleaner .zshrc and easier debugging/updating.
# Aliases:
#
# Reorganized aliases into logical sections, making it easier to locate and modify shell, filesystem, git, dev tool, and Docker-related commands.
# History and Options:
#
# Placed history and zsh option configurations toward the middle to ensure that all prior settings are saved correctly in history.
# Closing Remarks:
# This structure optimizes shell performance, ensures modularity through separate sourcing of aliases and functions, and guarantees the necessary tools follow the correct path resolution and locale setup. Future customization will be easier by logically maintaining functions/aliases externally.


#------------------------------------------------------------------------------
# Early Performance Settings
#------------------------------------------------------------------------------

# PERFORMANCE: Skip automatic global compinit (completion system initialization) from /etc/zshrc
# Why? 1. Prevents duplicate initialization (macOS runs it twice by default)
#      2. Lets us control when completions load (we'll do it ourselves in .zshrc)
#      3. Can significantly speed up shell startup (20-100ms+)
# Details: Completion system (compinit) loads available command completions, but it's 
#          expensive. Better to run it once, deliberately, after other configs are loaded.
# Docs: https://zsh.sourceforge.io/Doc/Release/Completion-System.html
skip_global_compinit=1

# Set Zsh opts.
setopt extended_glob

# TODO
# zmodload zsh/zprof  # Uncomment for profiling

setopt HIST_REDUCE_BLANKS
setopt SHARE_HISTORY
setopt HIST_SAVE_NO_DUPS

# History and option settings
setopt HIST_IGNORE_DUPS      # Ignore duplicate entries in history
setopt HIST_IGNORE_SPACE     # Ignore commands prefixed by space
setopt HIST_VERIFY           # Edit actions before execution (after Up arrow)

# Zsh navigation tweaks
setopt AUTO_CD               # Automatically `cd` when typing a directory name
setopt AUTO_PUSHD            # Automatically push directories onto the stack
setopt PUSHD_IGNORE_DUPS     # Ignore duplicate directories in the stack
setopt EXTENDED_GLOB         # Enable advanced globbing in Zsh



#################################################
# TODO: from https://github.com/holman/dotfiles/blob/master/zsh/zshrc.symlink
# link : https://www.reddit.com/r/zsh/comments/11v07m1/how_to_set_up_zshrc_to_be_used_on_macos_homebrew/
#------------------------------------------------------------------------------
# TODO: local .zshenv env vars if any
#------------------------------------------------------------------------------

# Local config - from https://github.com/thoughtbot/dotfiles/blob/main/zshenv
[[ -f ~/.zshenv.local ]] && source ~/.zshenv.local

#------------------------------------------------------------------------------
# Locale (Language/Encoding) Configuration + Editors + pagers (could be .zshenv)
# - **Locale settings** and global encoding like `LANG` and `LC_ALL` should stay **towards the top** as they define environment behavior early.
# Set UTF-8 as the globally recognized encoding for system-wide compatibility
#------------------------------------------------------------------------------

export LANG='en_US.UTF-8'
export LC_ALL='en_US.UTF-8'

export SUDO_EDITOR='nvim'
export EDITOR='nvim'
export VISUAL='nvim'

# For using less with color and proper UTF-8 formatting as the default pager:
# Ensure less behaves well with color and UTF-8 content
export LESS='-R -i'
export LESSCHARSET=utf-8
export PAGER='bat --pager=always'  # Bat as the pager for general output
# bat as a pager for man pages, with syntax highlighting
export MANPAGER="sh -c 'col -bx | bat --paging=always --language=man'"
# Alternatively, if you want to use NeoVim for man pages, uncomment this:
# export MANPAGER="nvim +Man!"

#--------------
# Shell History and Essential Options
# 
# TODO: https://www.reddit.com/r/zsh/comments/11v07m1/how_to_set_up_zshrc_to_be_used_on_macos_homebrew/
#-------------

# Set history file and size limits
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
#------------------------------------------------------------------------------
# Locale (Language/Encoding) Configuration + Editors + pagers (could be .zshenv)
# NOTE: **Locale settings** and global encoding like `LANG` and `LC_ALL` should stay **towards the top** as they define environment behavior early.
# NOTE: Set UTF-8 as the globally recognized encoding for system-wide compatibility
#------------------------------------------------------------------------------

# Below uses the ${parameter:-word} syntax -> use "parameter" if set, else use "word"

# Set ZDOTDIR if you want to re-home Zsh.
export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
export XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}
export XDG_CACHE_HOME=${XDG_CACHE_HOME:-$HOME/.cache}

# Set the root name of the plugins files (.txt and .zsh) antidote will use.
export ZDOTDIR=${ZDOTDIR:-$XDG_CONFIG_HOME/zsh}
zsh_plugins=${ZDOTDIR:-~}/.zsh_plugins

# Set HOMEBREW_PREFIX if not already set
export HOMEBREW_PREFIX="${HOMEBREW_PREFIX:-/opt/homebrew}"

# Ensure Homebrew prefix is set correctly for the architecture
if [[ -z "$HOMEBREW_PREFIX" ]]; then
    if [[ "$(uname -m)" == "arm64" ]]; then
        export HOMEBREW_PREFIX="/opt/homebrew"
    else
        export HOMEBREW_PREFIX="/usr/local"
    fi
fi

# Non-standard CORE environment-specific paths (e.g. tool/lang specific)
export BUN_INSTALL="$HOME/.bun"
export GLOBAL_PYTHON_VENV="$HOME/src/.python-global"
# export RIPGREP_CONFIG_PATH="$HOME/.ripgreprc"


#------------------------------------------------------------------------------
# .zprofile type code
#
# PATH Configuration (Unique Paths)
#
# PATHS: Declare path array with unique entries (-U = unique, removes duplicates)
# Why? 1. Maintains clean $PATH without duplicate entries
#      2. More efficient than manual PATH string manipulation
#      3. ZSH-native way to handle paths (better than export PATH=...)
# Usage: path+=(/new/path)  # Add new paths safely, duplicates auto-removed
# (typeset -U path) : a good **Zsh-native way** to handle paths. Make sure the `path` array settings are done once.
# Define **`typeset -U path`** early, include all complex paths, and **avoid repetitive export PATH statements** mid-way through the file (e.g. "export PATH=$BUN_INSTALL/bin:$PATH").
#------------------------------------------------------------------------------
# Ensure path (binaries) + fpath (completions) arrays do not contain duplicates.
typeset -gU path fpath

# Init the list of directories that zsh searches for commands
# If dirs are missing, they won't be added due to null globbing.
path=(
    # Homebrew paths (using the pre-defined HOMEBREW_PREFIX)
    $HOMEBREW_PREFIX/{,s}bin(N)

    # /usr/local (Apple Silicon Mac : different from HOMEBREW_PREFIX so need explicit addition)
    /usr/local/{,s}bin(N)

    # User-specific binaries
    $HOME/.local/{,s}bin(N)
    $HOME/{,s}bin(N)
        
    # Language/tool-specific paths
    $BUN_INSTALL/bin(N)
    $GLOBAL_PYTHON_VENV/bin(N)
    $HOME/.cargo/bin(N)           # Rust
    $HOME/.deno/bin(N)           # Deno
    $HOME/go/bin(N)              # Go
    
    # App-specific paths
    $HOME/.cache/lm-studio/bin(N)

    # System paths (lower priority)
    /usr/{,s}bin(N)
    /{,s}bin(N)

    # Inherit existing PATH
    $path
)

# TODO: above paths
# # /usr/local only if different from HOMEBREW_PREFIX
# # This conditional addition prevents duplicate paths on Intel Macs (vs Apple Silicon Macs)
# ${${:-/usr/local/bin}:#$HOMEBREW_PREFIX/bin}(N)
# ${${:-/usr/local/sbin}:#$HOMEBREW_PREFIX/sbin}(N)

#------------------------------------------------------------------------------
# insert Homebrew-managed zsh completions (in zsh/site-functions) into zsh
#
# This is done by inserting the homebrew zsh/site-functions 'path' into $FPATH before zsh's completions are initialized done by eval "$(brew shellenv)"
# make sure inserting zsh/site-functions (eval "$(brew shellenv)") is done BEFORE initialising zsh’s completion init (autoload -Ux compinit && compinit).
# https://docs.brew.sh/Shell-Completion#configuring-completions-in-zsh
#------------------------------------------------------------------------------
eval "$($HOMEBREW_PREFIX/bin/brew shellenv)"
# eval "$(brew shellenv)"

#------------------------------------------------------------------------------
# .zshrc - Zsh file loaded on interactive shell sessions.
#------------------------------------------------------------------------------

export GITHUB_USER="aitchwhy"
export GITHUB_EMAIL="hank.lee.qed@gmail.com"

# inspo
# - https://www.reddit.com/r/zsh/comments/11v07m1/how_to_set_up_zshrc_to_be_used_on_macos_homebrew/
# TODO: Source any plugins installed via homebrew if found.
: ${HOMEBREW_PREFIX:=$(brew --prefix 2>/dev/null)}
zsh_plugins=(
   $HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh(N)

   # https://github.com/zsh-users/zsh-autosuggestions
   $HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh(N)

   # https://github.com/hlissner/zsh-autopair
   $HOMEBREW_PREFIX/share/zsh-autopair/autopair.zsh(N)

   # https://github.com/zsh-users/zsh-history-substring-search
   $HOMEBREW_PREFIX/share/zsh-history-substring-search/zsh-history-substring-search.zsh

   # https://zsh-abbr.olets.dev/installation.html
   # $HOMEBREW_PREFIX/share/zsh-abbr/zsh-abbr.zsh

   # TODO: zsh-autosuggestions + zsh-abbr integration (https://github.com/olets/zsh-autosuggestions-abbreviations-strategy)
   # $HOMEBREW_PREFIX/share/zsh-autosuggestions-abbreviations-strategy/zsh-autosuggestions-abbreviations-strategy.zsh

   # $HOMEBREW_PREFIX/etc/bash-completion/completions/git-extras(N)
   # $HOMEBREW_PREFIX/opt/zsh-fast-syntax-highlighting/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh(N)
)
for zfile in $zsh_plugins; source $zfile

# Cleanup.
unset zsh_plugins zfile

#------------------------------------------------------------------------------
# Tool Configuration and Exports (bat, fzf, ripgrep)
#------------------------------------------------------------------------------

# Fuzzy Find: Set default command for fzf with ripgrep (hidden files included). Use fzf with bat for searching file contents
export FZF_DEFAULT_COMMAND="rg --files --hidden --follow --glob '!.git/*'"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers --color=always --line-range=:500 {}'"
# export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'


# TODO: DevToys dev utils (https://devtoys.app/doc/articles/extension-development/getting-started/setup.html?tabs=macos)
# export DevToysGuiDebugEntryPoint="/Applications/DevToys.app/Contents/MacOS/DevToys"
# export DevToysCliDebugEntryPoint="/Applications/DevToys.app/Contents/MacOS/DevToys"

#------------------------------------------------------------------------------
# Completion System Initialization (Load Late to Avoid Reinitialization)
# brew shellenv -> fpath[1,0]="/opt/homebrew/share/zsh/site-functions";
#------------------------------------------------------------------------------

# TODO: brew zsh-completions
# if type brew &>/dev/null; then
#   FPATH=$(brew --prefix)/share/zsh-completions:$FPATH
#
#   autoload -Uz compinit
#   compinit
# fi

# zsh completions initialization (TODO: antidote)
autoload -Uz compinit
compinit
# if [[ -n ${ZDOTDIR}/.zcompdump(#qN.mh+24) ]]; then
#     compinit;
# else
#     compinit -C;
# fi


#------------------------------------------------------------------------------
# Core Dev Tool Initialization (Order Matters)
#------------------------------------------------------------------------------

# Node version manager (fnm) initialization
eval "$(fnm env --use-on-cd --version-file-strategy recursive --shell zsh)"

# Bun (JavaScript runtime) initialization (conditional load)
[ -s "$BUN_INSTALL/_bun" ] && source "$BUN_INSTALL/_bun"

# Universal Python Global Virtual Environment (uv) CLI initialization
eval "$(uv generate-shell-completion zsh)"

# TODO: safer storage + handling secrets auth + credential




#------------------------------------------------------------------------------
# Shell Enhancements (zoxide, history extensions)
#------------------------------------------------------------------------------

# zoxide (enhanced directory navigation)
eval "$(zoxide init zsh)"

# atuin (advanced shell history management)
eval "$(atuin init zsh)"

# temporal (measure and log command duration times)
eval "$(temporal completion zsh)"

# Starship prompt setup (load prompt last)
eval "$(starship init zsh)"


# TODO: uv python cli (global virtualenv venv as workaround)
# Create global venv (if not exist)
# uv venv ~/.python-global


#------------------------------------------------------------------------------
# Custom Functions (Separate File Sourcing for Modularity)
#------------------------------------------------------------------------------

# TODO: Source external modular functions
# source "$ZDOTDIR/functions.zsh"  # Source functions defined elsewhere

# zsh reload with chezmoi changes
function reload() {
    zs
    echo "Reloaded"
}

# Use fzf + bat for filtering large output files (e.g., logs, big text files)
function fbat() {
  bat --paging=always "$1" | fzf
}

function rebuild_zsh_completions() {
    rm -f ~/.zcompdump; compinit
}

# yazi helper function
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

#------------------------------------------------------------------------------
# Custom Aliases for Productivity (Organized by Sections)
#------------------------------------------------------------------------------

# Stream large data using bat + fzf
alias flog='fzf --preview "bat --style=numbers --color=always --line-range=:500 {}"'
alias falias='alias | fzf'

# Fuzzy man page search
alias fman='man -k . | fzf --preview "man {}"'

############
# use modern alternatives
############
# Use bat by default for viewing files
alias cat='bat --paging=always'
alias grep='rg'
alias find='fd'
alias md='glow'

# Git shortcuts
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias lg='lazygit'  # Run lazygit

# TODO: Github Copilot (ghc + ghce function)

# Filesystem navigation shortcuts using exa
# TODO: --group-directories-first
# TODO: --color=auto
alias ls='eza --icons'
alias ll='eza -l --icons'
alias la='eza -al --icons'

# Docker shortcuts
alias dc='docker-compose'
alias dps='docker ps'

# Zsh+Chezmoi shortcuts for managing dotfiles
alias ze="chezmoi edit ~/.zshrc --apply && source ~/.zshrc"
alias zs="chezmoi apply -v ~/.zshrc && source ~/.zshrc"

# rebuild_zsh_completions
alias zcompreset="rm -f ~/.zcompdump; compinit"

# Chezmoi shortcuts for managing dotfiles
alias cm="chezmoi"
alias cma="chezmoi add"
alias cmra="chezmoi re-add"
alias cmf="chezmoi forget"
alias cmap="chezmoi apply"
# managed code
alias cmsrc="chezmoi source-path"
# actual code
alias cmdst="chezmoi source-path"
alias cm="chezmoi"
alias cmls="chezmoi managed"
# should not use below if chezmoi works
# alias _ze="$EDITOR ~/.zshrc"
# alias _zs="source ~/.zshrc"

# Homebrew operations
alias b="brew"

alias bh="brew home"
alias bx="brew commands"
alias bupd="brew update"
alias bupg="brew upgrade"
alias bdoc="brew doctor"
alias bclean="brew cleanup --prune=all"

alias bpull="bupd && bupg && bclean"
alias bui="brew uninstall"
alias bls="brew list -1"
alias bu="brew update"
alias bin="brew install"
alias brein="brew reinstall"
alias bi="brew info"
alias bo="brew outdated"
alias bs="brew search"
alias bsd="brew search --eval-all --desc"

# Homebrew Cask operations
alias bcl="brew list --cask"
alias bcin="brew install --cask"
alias bcup="brew upgrade --cask"

# Homebrew Bundle operations
alias bb="brew bundle"
alias bbhelp="brew bundle -h"
alias bbcat="brew bundle list --all --global --verbose"
alias bbin="brew bundle install --all --global --verbose"
alias bbls="brew bundle dump --all --file=- --verbose"
alias bbsave="brew bundle dump --all --verbose --global -f && chezmoi re-add ~/.Brewfile"
alias bbcheck="brew bundle check --all --global  --verbose"


# Tailscale VPN
alias ts="tailscale"

#------------------------------------------------------------------------------
# TODO: Sourcing Additional Files/External Scripts (For Modularity)
#------------------------------------------------------------------------------

alias gdl='cd ~/Downloads'
alias gcf='cd ~/.config/'


alias uvgn="uv venv $GLOBAL_PYTHON_VENV"
alias uvg="source $GLOBAL_PYTHON_VENV/bin/activate"

#------------------------------------------------------------------------------
# TODO: command cheatsheet (use cheat CLI command)
# TODO: zsh-abbr shortcuts
#------------------------------------------------------------------------------
# $ ln -s ~/.config/zsh/.zshrc ~/.zshrc
# $ nvim <file>	Opens NeoVim in the terminal to edit the given file.
# $ cat <file>	bat-enhanced cat, uses pagination and syntax highlighting.
# $ fbat <file>	Use bat + fzf to filter and preview large files interactively.
# $ flog <file>	Stream logs using fzf while previewing sections of large log files.
# $ fman	fzf-based man page search: Quickly search and preview man pages, select using fuzzy find and preview.
# $ man <command>	Opens bat-enhanced man pages with syntax highlighting and nice paging.

