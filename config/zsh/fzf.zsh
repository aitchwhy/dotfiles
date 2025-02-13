
# default command for fzf
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git --exclude node_modules --exclude target'
# export FZF_DEFAULT_COMMAND='rg --files --no-ignore-vcs --hidden'

# Default options
export FZF_DEFAULT_OPTS="
  --height 80% 
  --layout=reverse 
  --border sharp
  --preview 'bat --style=numbers,changes --color=always --line-range :500 {}' 
  --preview-window='right:60%:border-left'
  --bind='ctrl-/:toggle-preview'
  --bind='ctrl-y:execute-silent(echo {} | pbcopy)'
  --bind='ctrl-e:execute(nvim {} < /dev/tty > /dev/tty)'
  --bind='ctrl-f:preview-page-down'
  --bind='ctrl-b:preview-page-up'
  --color=fg:#c0caf5,bg:#1a1b26,hl:#bb9af7
  --color=fg+:#c0caf5,bg+:#292e42,hl+:#7dcfff
  --color=info:#7aa2f7,prompt:#7dcfff,pointer:#7dcfff
  --color=marker:#9ece6a,spinner:#9ece6a,header:#9ece6a
"

#############
# History search (CTRL-R) + atuin
# Paste the selected command from history onto the command-line
#
# If you want to see the commands in chronological order, press CTRL-R again which toggles sorting by relevance
# Press CTRL-/ to toggle line wrapping and see the whole command
#
# Set FZF_CTRL_R_OPTS to pass additional options to fzf
# CTRL-Y to copy the command into clipboard using pbcopy
#############

# History search (CTRL-R) - Integrated with Atuin
export FZF_CTRL_R_OPTS="
  --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'
  --color header:italic
  --header 'CTRL-Y: Copy | CTRL-R: Toggle sort'
  --border-label='Command History'"

#############
# Dir+File search (CTRL-T)
# Preview file content using bat (https://github.com/sharkdp/bat)
#
# Paste the selected files and directories onto the command-line
#
# The list is generated using --walker file,dir,follow,hidden option
# You can override the behavior by setting FZF_CTRL_T_COMMAND to a custom command that generates the desired list
# Or you can set --walker* options in FZF_CTRL_T_OPTS
# Set FZF_CTRL_T_OPTS to pass additional options to fzf
#############
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="
  --walker-skip .git,node_modules,target,.cache
  --preview 'bat -n --color=always {}'
  --bind 'ctrl-/:change-preview-window(down|hidden|)'
  --border-label='Files'"

#############
# Directory navigation (ALT-C) (cd into the selected directory)
#
# The list is generated using --walker dir,follow,hidden option
# Set FZF_ALT_C_COMMAND to override the default command
# Or you can set --walker-* options in FZF_ALT_C_OPTS
# Set FZF_ALT_C_OPTS to pass additional options to fzf
#
# Print tree structure in the preview window
#############
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git --exclude node_modules --exclude target'
export FZF_ALT_C_OPTS="
  --walker-skip .git,node_modules,target,.cache
  --preview 'tree -C {} | head -200'
  --border-label='Directories'"

# Load fzf keybindings
# source "$(brew --prefix)/opt/fzf/shell/key-bindings.zsh"