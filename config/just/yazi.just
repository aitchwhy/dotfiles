# Yazi File Manager Module
# Usage: just yazi <command>
set shell := ["bash", "-uc"]

# Show available yazi commands
[private]
default:
    @just --list --justfile {{ source_file() }}

# Edit Yazi config
edit:
    nvim ~/.config/yazi/yazi.toml

# Edit Yazi Lua init file
init:
    nvim ~/.config/yazi/init.lua

# Edit Yazi keymap
keymap:
    nvim ~/.config/yazi/keymap.toml

# Edit Yazi theme
theme:
    nvim ~/.config/yazi/theme.toml

# List installed plugins
plugins:
    @find ~/.config/yazi/plugins -maxdepth 1 -type d -not -path "*/\.*" | sed 's|.*/||' | sort

# Install recommended Yazi plugins
install-plugins:
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p ~/.config/yazi/plugins
    git clone https://github.com/Rolv-Apneseth/yazi-web-devicons.git ~/.config/yazi/plugins/web-devicons 2>/dev/null \
        || (cd ~/.config/yazi/plugins/web-devicons && git pull)
    git clone https://github.com/sxyazi/yazi-vcs.git ~/.config/yazi/plugins/yazi-vcs 2>/dev/null \
        || (cd ~/.config/yazi/plugins/yazi-vcs && git pull)
    echo "Yazi plugins installed or updated"

# Update all Yazi plugins
update-plugins:
    find ~/.config/yazi/plugins -maxdepth 1 -type d -name "*.yazi" -o -type d -name "*.git" | xargs -I{} git -C {} pull

# Open current directory in Yazi
here:
    yazi .

# Open home directory in Yazi
home:
    yazi ~

# Open config directory in Yazi
config:
    yazi ~/.config
