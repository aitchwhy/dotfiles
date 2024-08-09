#-------------------------------------------------------------------------------
# Path to your dotfiles installation.
#-------------------------------------------------------------------------------
export DOTFILES=$HOME/src/dotfiles
export DOTFILES_ZSH=$DOTFILES/darwin
export DOTFILES_ALIASES=$DOTFILES_ZSH/aliases.zsh
export DOTFILES_EXPORTS=$DOTFILES_ZSH/exports.zsh
export DOTFILES_FUNCTIONS=$DOTFILES_ZSH/functions.zsh

#-------------------------------------------------------------------------------
# OMZ common shortcuts
#-------------------------------------------------------------------------------
export OMZ_HOME=$HOME/.oh-my-zsh
export OMZ_CUSTOM=${ZSH_CUSTOM:-$OMZ/custom}
export OMZ_PLUGIN=${ZSH_PLUGIN:-$OMZ/plugins}

#-------------------------------------------------------------------------------
# homebrew
#-------------------------------------------------------------------------------
export BREW_PREFIX="/opt/homebrew"
export BREWFILE_GLOBAL=${HOMEBREW_BUNDLE_FILE_GLOBAL:-$HOME/.Brewfile}

#-------------------------------------------------------------------------------
# Preferred editor for local and remote sessions
#-------------------------------------------------------------------------------
export EDITOR='nvim'

# #-------------------------------------------------------------------------------
# # Zlib flag export (Pyenv install 'zlib not found' error)
# #-------------------------------------------------------------------------------

# # For compilers to find zlib you may need to set:
# export LDFLAGS="${LDFLAGS} -L/usr/local/opt/zlib/lib"
# export CPPFLAGS="${CPPFLAGS} -I/usr/local/opt/zlib/include"

# # For pkg-config to find zlib you may need to set:
# export PKG_CONFIG_PATH="${PKG_CONFIG_PATH} /usr/local/opt/zlib/lib/pkgconfig"

# #-------------------------------------------------------------------------------
# # Javascript (Node, Deno, etc)
# #-------------------------------------------------------------------------------
# export DENO_INSTALL="$HOME/.deno"

# #-------------------------------------------------------------------------------
# # Tmux fzf gnu-sed (gsed) path
# #-------------------------------------------------------------------------------
# export TMUX_FZF_SED="/usr/local/bin/gsed"

#-------------------------------------------------------------------------------
# Python + Pyenv setup
#-------------------------------------------------------------------------------
# No __pycache__
# export PYTHONDONTWRITEBYTECODE=1
# export PYENV_ROOT=$HOME/.pyenv

# #-------------------------------------------------------------------------------
# # Sqlite DB setup (Homebrew version)
# #
# # See Brewfile 'sqlite' comments for more info
# #-------------------------------------------------------------------------------
# # For compilers to find sqlite you may need to set:
# export LDFLAGS="-L$BREW_PREFIX/opt/sqlite/lib"
# export CPPFLAGS="-I$BREW_PREFIX/opt/sqlite/include"
# # For pkg-config to find sqlite you may need to set:
# export PKG_CONFIG_PATH="$BREW_PREFIX/opt/sqlite/lib/pkgconfig"

############################################################
# TODO
############################################################

#-------------------------------------------------------------------------------
# FZF settings
#-------------------------------------------------------------------------------
# Default settings for CLI fuzzy finder
# https://github.com/junegunn/fzf?tab=readme-ov-file#key-bindings-for-command-line
#
# - m : multi-select with TAB
# - layout=reverse : filter prompt on TOP not bottom
# - inline-info : filtered result count shown INLINE with filter prompt
# - border : draw border around fuzzy finder
# - bind : bind keys WHILE in FZF to execute without leaving FZF
#
# NOTE: {} is replaced with the single-quoted string of the focused line
# NOTE: "alt" == "option" key in Mac
#
# - Press F1 to open the file with less without leaving fzf
# - Press CTRL-Y to copy the line to clipboard and aborts fzf (requires pbcopy)
#   --bind 'f1:execute(less -f {}),ctrl-y:execute-silent(echo {} | pbcopy)+abort'
#-------------------------------------------------------------------------------

# source $DOTFILES/scripts/.functions.sh
# # TODO: ripgrep_fzf_search_file() from .functions.sh

# # export FZF_DEFAULT_COMMAND="rg --no-ignore-vcs --hidden --files $WORKDIR_PATHS"
# export FZF_DEFAULT_COMMAND="fd . $HOME"
# # export FZF_DEFAULT_COMMAND="fd --hidden --no-ignore --type file --files $WORKDIR_PATHS"
# export FZF_DEFAULT_OPTS="
#   --multi
#   --layout=reverse
#   --inline-info
#   --border"

# #########################
# #########################
# # Ctrl+t -> FILES-only search and paste into CLI
# #########################
# #########################
# # Preview file content using bat (https://github.com/sharkdp/bat)
# export FZF_CTRL_T_COMMAND="rg --no-ignore-vcs --hidden --files $WORKDIR_PATHS"
# # FZF_CTRL_T_OPTS to ADD ADDITIONAL options if desired
# export FZF_CTRL_T_OPTS="
#   --preview 'bat -n --color=always {}'
#   --bind 'ctrl-/:change-preview-window(down|hidden|)'
#   --header 'Paste selected into shell CLI. All files (rg)'"
# #########################
# #########################
# # Ctrl+r -> shell command history (zsh) search and paste into CLI
# # NOTE: press Ctrl+r again to SORT toggle (relevance + time)
# # NOTE: "alt" == "option" key in Mac
# #########################
# #########################
# # FZF_CTRL_R_OPTS if we want more options (ADDITIONAL) for Ctrl+r
# # CTRL-/ to toggle small preview window to see the full command
# # CTRL-Y to copy the command into clipboard using pbcopy
# export FZF_CTRL_R_OPTS="
# --preview 'echo {}' --preview-window up:3:hidden:wrap
# --bind 'ctrl-/:toggle-preview'
# --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'
# --color header:italic
# --header 'Paste selected Shell command. Press CTRL-Y to copy command into clipboard'"
# #########################
# # Esc+c -> search and CD into directory
# # NOTE: updated at iTerm2 level to use "Esc" as "Option" -> https://github.com/junegunn/fzf/issues/164
# # NOTE: press Ctrl+r again to SORT toggle (relevance + time)
# #########################
# # FZF_ALT_C_COMMAND -> to override Alt+c command
# # FZF_ALT_C_OPTS -> to pass ADDITIONAL Alt+c options
# export FZF_ALT_C_COMMAND="fd -t d . $HOME"
# # Print tree structure (-C means "colored") in the preview window
# export FZF_ALT_C_OPTS="--preview 'tree -C {}'"
# #########################
