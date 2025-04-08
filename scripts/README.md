# Scripts Directory

This directory contains various scripts and utilities used within the dotfiles repository.

## Using Justfile Commands

The dotfiles repository includes several [just](https://github.com/casey/just) command runner files:

### Root-level Justfile

The main `Justfile` at the repository root contains various commands organized by groups:

- **nix**: Commands for managing Nix packages and configurations
- **desktop**: Commands for Darwin/macOS system configuration
- **flonotes**: Frontend development commands (migrated from `scripts/anterior/justfile`)

The commands are designed to work from any directory, with paths that automatically adjust to ensure scripts run with the correct working directory.

To list all available commands:
```bash
just --list
```

To list commands by group:
```bash
just --list --list-groups
```

To run a command:
```bash
just <command-name>
```

For example:
```bash
just run-noggin    # Build and run noggin
just run-platform  # Build and run the platform components
```

#### Path Handling in Justfile

The Flonotes commands are configured with path variables:
```
flonotes_platform := "~/src/platform"
flonotes_fe := "~/src/flonotes-fe"
```

Commands automatically navigate to the appropriate directory before execution. For scripts, the Justfile uses the `{{justfile_directory()}}` function to ensure scripts are found regardless of where you run the `just` command from.

For example, the `deploy-local` command:
```
cd {{flonotes_fe}} && \
$(pwd)/{{justfile_directory()}}/scripts/anterior/deploy-local.sh http://localhost:59000
```

This means you can run these commands from any directory and they will still correctly:
1. Change to the appropriate project directory
2. Run the scripts located in the dotfiles repository

### User-specific Justfile

The `scripts/user.justfile` contains user-specific commands that may not be appropriate for the main repository.

To use commands from this file:

```bash
just --justfile scripts/user.justfile <command-name>
```

Alternatively, you can create an alias in your shell:

```bash
alias ujust='just --justfile ~/dotfiles/scripts/user.justfile'
```

Then you can run:

```bash
ujust <command-name>
```

## Available Scripts

- `run-platform.zsh`: Zellij-based script for running platform components
- `csv-merge-cleaner-script.py`: Utility for cleaning and merging CSV data
- Other Python utilities and data processing scripts

## Anterior Directory

The `scripts/anterior` directory contains legacy scripts and configuration files. 
Scripts from this directory have been integrated into the main dotfiles structure where appropriate.
For example, commands from `scripts/anterior/justfile` have been migrated to the root-level `Justfile` 
under the 'flonotes' group.
