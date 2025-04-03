#!/bin/zsh
#
#$ zr tail -f /path/to/my/file # open a new pane tailing this file
#$ zrf htop # open a new floating pane with htop
#$ ze ./main.rs # open a new pane with your editor (eg. vim) pointed at ./main.rs
#
######################
# …/dotfiles  main [?1]
# ❯ zellij help run
# zellij-run
# Run a command in a new pane
#
# USAGE:
#     zellij run [OPTIONS] [--] <COMMAND>...
#
# ARGS:
#     <COMMAND>...    Command to run
#
# OPTIONS:
#     -c, --close-on-exit            Close the pane immediately when its command exits
#         --cwd <CWD>                Change the working directory of the new pane
#     -d, --direction <DIRECTION>    Direction to open the new pane in
#     -f, --floating                 Open the new pane in floating mode
#     -h, --help                     Print help information
#         --height <HEIGHT>          The height if the pane is floating as a bare integer (eg. 1) or
#                                    percent (eg. 10%)
#     -i, --in-place                 Open the new pane in place of the current pane, temporarily
#                                    suspending it
#     -n, --name <NAME>              Name of the new pane
#         --pinned <PINNED>          Whether to pin a floating pane so that it is always on top
#     -s, --start-suspended          Start the command suspended, only running after you first presses
#                                    ENTER
#         --width <WIDTH>            The width if the pane is floating as a bare integer (eg. 1) or
#                                    percent (eg. 10%)
#     -x, --x <X>                    The x coordinates if the pane is floating as a bare integer (eg.
#                                    1) or percent (eg. 10%)
#     -y, --y <Y>                    The y coordinates if the pane is floating as a bare integer (eg.
#                                    1) or percent (eg. 10%)
######################

SRC_DIR="~/src/"
PLATFORM_DIR="$SRC_DIR/platform"
FLONOTES_FE_DIR="$SRC_DIR/flonotes-fe"

# Create a new Zellij session
zellij --layout three-pane --session dev_session

# Function to create a new tab, navigate to repo and run command
add_repo_tab() {
    local repo_path=$1
    local command=$2
    local log_file=$3

    # Send commands to the active pane
    zellij action write-chars "cd $repo_path && $command | tee -a $log_file"
    zellij action write 13  # Send Enter key
}

# Wait for Zellij to initialize
sleep 1

# Configure each pane with a different repo
local RUN_CMD_ALL="ant build api user s3 prefect-worker prefect-agent prefect-server data-seeder && ant up api user s3 prefect-worker prefect-agent prefect-server data-seeder"
local RUN_FLONOTES_FE="make deploy-local"
local RUN_CMD_NOGGIN="ant build noggin && ant run noggin"

zellij action focus-pane 0
add_repo_tab $PLATFORM_DIR "$RUN_CMD_ALL" "$RUN_CMD_ALL.log"

zellij action focus-pane 1
add_repo_tab $FLONOTES_FE_DIR "$RUN_FLONOTES_FE" "$RUN_FLONOTES_FE.log"

zellij action focus-pane 2
add_repo_tab $PLATFORM_DIR "$RUN_CMD_NOGGIN" "$RUN_CMD_NOGGIN.log"

# tail
#
