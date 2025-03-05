# Performance monitoring (uncomment to debug startup time)
# zmodload zsh/zprof

# Main ZSH configuration file for interactive shells

# TODO: https://github.com/mattmc3/zdotdir/blob/main/plugins/xdg/xdg.plugin.zsh
# TODO: https://github.com/getantidote/zdotdir/blob/main/.zshenv

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

# Vi Mode Configuration
bindkey -v
export KEYTIMEOUT=1

# Basic key bindings
bindkey '^P' up-line-or-history
bindkey '^N' down-line-or-history
bindkey '^E' end-of-line
bindkey '^A' beginning-of-line
# bindkey '^K' up-line-or-history
# bindkey '^J' down-line-or-history
# bindkey '^L' end-of-line
# bindkey '^H' beginning-of-line
# bindkey '^R' history-incremental-search-backward
# bindkey '^?' backward-delete-char # Backspace working after vi mode

# Editor
# export EDITOR="nvim"
# export VISUAL="$EDITOR"

has_command nvim && export EDITOR="nvim" && export VISUAL="nvim"

# History
# export HISTFILE="$HOME/.zsh_history"
export HISTSIZE=100000
export SAVEHIST=100000

# Source utilities in specific order
local files=(
  # "./utils.zsh"     # Load core utilities first
  "$ZDOTDIR/system.zsh" # system
  "$ZDOTDIR/brew.zsh"   # Package manager setup
  "$ZDOTDIR/git.zsh"    # Git configuration
  # "./rust.zsh"      # Rust development setup
  # "./nvim.zsh"      # Neovim configuration
  "$ZDOTDIR/fzf.zsh"     # Fuzzy finder setup
  "$ZDOTDIR/aliases.zsh" # Command aliases
  # "./functions.zsh" # Custom functions
  # "./local.zsh" # Local machine specific config (load last)
  "$ZDOTDIR/symlinks.zsh" # symlinks
)

for file in $files; do
  echo "source $file..."
  [[ -f "$file" ]] && source "$file"
done

# [[ -f "$DOTFILES/utils.zsh" ]] && source "$DOTFILES/utils.zsh"

# git env vars

# install rustup if command "rustup" not found
if ! has_command rustup; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
fi

# # install nvim if not exist
# if ! has_command nvim; then
#   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
# fi

# If you need to have rustup first in your PATH, run:
#   echo 'export PATH="/opt/homebrew/opt/rustup/bin:$PATH"' >> /Users/hank/dotfiles/config/zsh/.zshrc
#
# zsh completions have been installed to:
#   /opt/homebrew/opt/rustup/share/zsh/site-functions

# docs
# - https://wiki.archlinux.org/title/Zsh#Configuration_files
# - https://gist.github.com/Linerre/f11ad4a6a934dcf01ee8415c9457e7b2

# Completions
autoload -Uz compinit
compinit

########
#if type brew &>/dev/null; then
#	FPATH=$(brew --prefix)/share/zsh-abbr:$FPATH
#
#	autoload -Uz compinit
#	compinit
#fi

# Load plugins if available
if [[ -d "$HOMEBREW_PREFIX/share" ]]; then
  plugins=(
    "zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
    "zsh-autosuggestions/zsh-autosuggestions.zsh"
    "zsh-abbr/zsh-abbr.zsh"
  )
  for plugin in $plugins; do
    plugin_path="$HOMEBREW_PREFIX/share/$plugin"
    if [[ -f "$plugin_path" ]]; then
      source "$plugin_path"
    fi
  done
fi

# # Initialize tools if installed
# has_command() {
#   command -v "$1" >/dev/null 2>&1
# }

has_command starship && eval "$(starship init zsh)"
has_command atuin && eval "$(atuin init zsh)"
has_command zoxide && eval "$(zoxide init zsh)"
has_command direnv && eval "$(direnv hook zsh)"
has_command fnm && eval "$(fnm env --use-on-cd)"
has_command uv && eval "$(uv generate-shell-completion zsh)"
# has_command pyenv && eval "$(pyenv init -)"
# has_command abbr && eval "$(abbr init zsh)"

# homebrew fzf
has_command fzf && source <(fzf --zsh)
# curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

#########################################
# # TODO:
# rustup completions zsh > ~/.zfunc/_rustup
# rustup completions zsh > $ZDOTDIR/.zfunc/_rustup

#
# Last login: Mon Mar  3 15:23:37 on ttys003
# info: downloading installer
# warn: It looks like you have an existing rustup settings file at:
# warn: /Users/hank/.rustup/settings.toml
# warn: Rustup will install the default toolchain as specified in the settings file,
# warn: instead of the one inferred from the default host triple.
#
# Welcome to Rust!
#
# This will download and install the official compiler for the Rust
# programming language, and its package manager, Cargo.
#
# Rustup metadata and toolchains will be installed into the Rustup
# home directory, located at:
#
#   /Users/hank/.rustup
#
# This can be modified with the RUSTUP_HOME environment variable.
#
# The Cargo home directory is located at:
#
#   /Users/hank/.cargo
#
# This can be modified with the CARGO_HOME environment variable.
#
# The cargo, rustc, rustup and other commands will be added to
# Cargo's bin directory, located at:
#
#   /Users/hank/.cargo/bin
#
# This path will then be added to your PATH environment variable by
# modifying the profile files located at:
#
#   /Users/hank/.profile
#   /Users/hank/.zshenv
#
# You can uninstall at any time with rustup self uninstall and
# these changes will be reverted.
#
# Current installation options:
#
#
#    default host triple: aarch64-apple-darwin
#      default toolchain: stable (default)
#                profile: default
#   modify PATH variable: yes
#
# 1) Proceed with standard installation (default - just press enter)
# 2) Customize installation
# 3) Cancel installation
# >
#########################################

# # Load additional config files
# if [[ -f "$ZDOTDIR/aliases.zsh" ]]; then
#   # echo "source $ZDOTDIR/aliases.zsh"
#   source "$ZDOTDIR/aliases.zsh"
# fi

# if [[ -f "$ZDOTDIR/functions.zsh" ]]; then
#   # echo "source $ZDOTDIR/functions.zsh"
#   source "$ZDOTDIR/functions.zsh"
# fi

# if [[ -f "$ZDOTDIR/fzf.zsh" ]]; then
#   # echo "source $ZDOTDIR/fzf.zsh"
#   source "$ZDOTDIR/fzf.zsh"
# fi

# # Local customizations, not tracked by git
# if [[ -f "$ZDOTDIR/local.zsh" ]]; then
#   # echo "source $ZDOTDIR/local.zsh"
#   source "$ZDOTDIR/local.zsh"
# fi

# FZF Configuration if available
# if [[ -f ~/.fzf.zsh ]]; then
#   source ~/.fzf.zsh
# elif [[ -f "$HOMEBREW_PREFIX/opt/fzf/shell/completion.zsh" ]]; then
#   source "$HOMEBREW_PREFIX/opt/fzf/shell/completion.zsh"
#   source "$HOMEBREW_PREFIX/opt/fzf/shell/key-bindings.zsh"
# fi

# Local customizations (not tracked by git)
# [[ -f "$ZDOTDIR/local.zsh" ]] && source "$ZDOTDIR/local.zsh"

# source $(brew --prefix)/share/zsh/site-functions/_todoist_fzf
