# Nix Configuration

My personal Nix configuration for macOS systems using nix-darwin and home-manager.

## Overview

This repository contains my personal system configuration using:
- [Nix](https://nixos.org/) - The purely functional package manager
- [nix-darwin](https://github.com/LnL7/nix-darwin) - MacOS system configuration
- [home-manager](https://github.com/nix-community/home-manager) - User environment management

## Structure

```
.
├── configs/               # Program-specific configurations
│   ├── atuin/            # Shell history
│   ├── cheat/            # Command cheatsheets
│   ├── ghostty/          # Terminal emulator
│   ├── git/              # Git configuration
│   ├── hammerspoon/      # Window management
│   ├── lazygit/          # Git TUI
│   ├── nvim/             # Neovim configuration
│   ├── zed/              # Zed editor
│   └── zellij/           # Terminal multiplexer
├── home/                 # Home-manager configurations
│   ├── core.nix         # Core home configuration
│   ├── default.nix      # Home-manager entry point
│   ├── git.nix          # Git configuration
│   ├── shell.nix        # Shell configuration
│   └── starship.nix     # Prompt configuration
├── modules/             # System modules
│   ├── apps.nix        # Application configuration
│   ├── host-users.nix  # Host-specific user settings
│   ├── nix-core.nix    # Core Nix settings
│   └── system.nix      # System configuration
├── flake.nix           # Nix flake configuration
├── flake.lock          # Flake lockfile
├── Justfile            # Command runner
└── README.md           # This file
```

## Setup

1. Install Nix:
```bash
sh <(curl -L https://nixos.org/nix/install)
```

2. Enable Flakes:
```bash
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

3. Install nix-darwin:
```bash
nix-build https://github.com/LnL7/nix-darwin/archive/master.tar.gz -A installer
./result/bin/darwin-installer
```

4. Clone this repository:
```bash
git clone https://github.com/yourusername/nix-config.git ~/.config/nix-config
cd ~/.config/nix-config
```

5. Build and switch to the configuration:
```bash
just switch
```

## Usage

The `Justfile` provides several helpful commands:

- `just switch` - Build and switch to the new configuration
- `just update` - Update all flake inputs
- `just clean` - Clean up old generations
- `just check` - Check flake
- `just fmt` - Format nix files
- `just build` - Build configuration without switching
- `just diff` - Show system closure difference

## Hosts

This configuration supports multiple macOS hosts:
- `hank-mbp` - MacBook Pro
- `hank-mstio` - Mac Studio

Each host inherits from the base configuration with its own specific overrides.

## Customization

1. Edit host-specific settings in `flake.nix`
2. Modify system configuration in `modules/`
3. Update user configuration in `home/`
4. Add program-specific configs in `configs/`

## Maintenance

- Update packages: `just update`
- Clean old generations: `just clean`
- Format code: `just fmt`
- Check configuration: `just check`

## License

MIT
