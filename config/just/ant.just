


# Set shell to zsh for all recipes
# set shell := ["", "develop"]
# set shell := ["zsh", "-cu"]
set unstable := true
set working-directory := '~/src/platform'
set dotenv-load

# # arguments can be variables or expressions
# file := '/sys/class/power_supply/BAT0/status'
# bat0stat := shell('cat $1', file)

# # commands can be variables or expressions
# command := 'wc -l'
# output := shell(command + ' "$1"', 'main.c')
#
# # arguments referenced by the shell command must be used
# empty := shell('echo', 'foo')
# full := shell('echo $1', 'foo')
# error := shell('echo $1')


# Interactive selection pipeline: enterprise -> user -> workspace
[group('nix')]
@foo:
  pwd
  set -euxo pipefail
  nix develop
  echo "hallo"
  # Select enterprise
  ENTERPRISE=$(ant-admin enterprises list | fzf --prompt="Enterprise: " | awk "{print \$1}")
  [[ -z "$ENTERPRISE" ]] && { echo "No enterprise selected"; exit 1; }

  # Select user
  USER=$(ant-admin users list | fzf --prompt="User: " | awk "{print \$1}")
  [[ -z "$USER" ]] && { echo "No user selected"; exit 1; }

  # Select workspace
  WORKSPACE=$(ant-admin workspaces list --enterprise=$ENTERPRISE | fzf --prompt="Workspace: " | awk "{print \$1}")
  [[ -z "$WORKSPACE" ]] && { echo "No workspace selected"; exit 1; }

  echo "Selected: $ENTERPRISE | $USER | $WORKSPACE"
  echo "Usage: just create-key $USER $ENTERPRISE $WORKSPACE [name] [role]"
  WORKSPACE=$(ant-admin workspaces list --enterprise=$ENTERPRISE | fzf --prompt="Workspace:
  " | awk "{print \$1}")
  [[ -z "$WORKSPACE" ]] && { echo "No workspace selected"; exit 1; }

  echo "Selected: $ENTERPRISE | $USER | $WORKSPACE"
  echo "Usage: just create-key $USER $ENTERPRISE $WORKSPACE [name] [role]"

