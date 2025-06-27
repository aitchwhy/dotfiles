# Shell Path Configuration

This directory contains a centralized path management system for all shells.

## Files

- `paths.conf` - One path per line configuration file (order matters)
- `path_utils.sh` - Shell utilities for managing PATH

## Features

1. **Centralized** - One config file for all shells
2. **Readable** - Clear path list, easy to reorder
3. **No duplicates** - Automatically handled
4. **Preserves system paths** - Doesn't clobber existing PATH
5. **Nix-friendly** - Loads Nix paths first (via .profile)
6. **Modern syntax** - Uses arrays where supported

## Setup

The following files have been configured to use this system:

1. `~/.config/zsh/.zshrc` - Loads path utilities
2. `~/.config/aerospace/bash/.bashrc` - Loads path utilities
3. `~/.bashrc` - Loads path utilities (appended)
4. `~/.profile` - Loads Nix first, then path utilities

## Usage

### Editing Paths

Edit `~/.config/shell/paths.conf` to manage your PATH. The file uses a simple format:
- One path per line
- Lines starting with # are comments
- Order matters (first = highest priority)

### Available Commands

After sourcing path_utils.sh, you have access to:

- `path_print` - Display current PATH entries with numbers

Example:
```bash
$ path_print
 1. /opt/homebrew/bin
 2. /Users/hank/.volta/tools/image/npm/11.4.1/bin
 3. /Users/hank/.volta/tools/image/node/22.16.0/bin
 ...
```

## How It Works

1. Paths are loaded from `paths.conf`
2. Environment variables like `$HOME` are expanded
3. Only existing directories are added to PATH
4. Duplicates are automatically removed
5. Existing PATH entries are preserved at the end