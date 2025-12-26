# Neovim Plugin Management Module
# Usage: just nvim <command>
set shell := ["bash", "-ec"]

# Show available nvim commands
[private]
default:
    @just --list --justfile {{ source_file() }}

# Edit Neovim config
edit:
    nvim ~/.config/nvim/init.lua

# Update Neovim plugins
update:
    nvim --headless "+Lazy update" +qa

# Check Neovim health
health:
    nvim --headless "+checkhealth" "+write /tmp/nvim-health.txt" +qa && nvim /tmp/nvim-health.txt

# Clean unused Neovim plugins
clean:
    nvim --headless "+Lazy clean" +qa

# Sync Neovim plugins (install missing + clean unused)
sync:
    nvim --headless "+Lazy sync" +qa

# Format Neovim Lua files
format:
    stylua ~/.config/nvim/lua

# List all installed plugins
plugins:
    nvim --headless "+Lazy list" "+write /tmp/nvim-plugins.txt" +qa && cat /tmp/nvim-plugins.txt

# Start Neovim with minimal config
minimal:
    NVIM_APPNAME=nvim-minimal nvim

# Start Neovim with no config
scratch:
    nvim -u NONE
