# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a **nix-darwin** configuration for macOS systems using Nix flakes. The repository manages system-level and user-level configurations through a modular architecture.

## Common Commands

### Building and Switching
```bash
# Rebuild and activate configuration (most common)
just switch     # or: just s

# Build without switching
just build      # or: just b

# Preview changes before applying
just diff

# Run checks before switching
just check
```

### Development and Maintenance
```bash
# Enter development shell with Nix tools
just dev

# Format all Nix files
just fmt

# Update all flake inputs
just update     # or: just u

# Run linting and tests
just lint
just test

# Clean old generations (keep 7 days)
just clean      # or: just gc

# Health check
just doctor
```

### Direct Commands (without just)
```bash
# Main rebuild command
darwin-rebuild switch --flake .#hank-mbp-m4

# Build only
darwin-rebuild build --flake .#hank-mbp-m4

# Format check
nix fmt -- --check

# Flake check
nix flake check
```

## Architecture

### Current Structure (Active)
```
├── flake.nix             # Entry point, defines darwinConfigurations
├── modules/              # Core system modules
│   ├── nix.nix          # Nix daemon settings
│   ├── darwin.nix       # macOS system configuration
│   ├── homebrew.nix     # Homebrew packages and casks
│   └── home.nix         # Home-manager module definition
├── machines/            # Host-specific configurations
│   └── hank-mbp-m4.nix  # MacBook Pro M4 settings
├── users/               # User home-manager configurations
│   └── hank.nix         # User packages, dotfiles, shell config
└── justfile             # Task runner commands
```

### Key Design Patterns

1. **Module Composition**: The system is built by composing modules in `flake.nix`:
   - Core modules provide system-wide configuration
   - Machine module adds host-specific settings
   - User configuration managed through home-manager

2. **Platform Handling**: Use `pkgs.stdenv.isDarwin` and `pkgs.stdenv.isLinux` for conditional configuration within modules

3. **Package Management**:
   - System packages: Defined in flake.nix inline configuration
   - User packages: Managed in `users/hank.nix` through home-manager
   - Homebrew: GUI apps and casks in `modules/homebrew.nix`

4. **Home-Manager Integration**: 
   - `useGlobalPkgs = true` ensures single nixpkgs evaluation
   - User config imported from `users/hank.nix`
   - Manages dotfiles, shell configuration, and user packages

## Important Notes

### Ongoing Refactoring
The repository shows signs of an incomplete migration. Documentation (README.md, ARCHITECTURE.md) describes a different structure than what exists. The actual implementation uses:
- `modules/`, `machines/`, `users/` (current)
- Not `features/`, `homes/`, `hosts/` (as documented)

### Code Duplication Investigation
There are potential duplications between:
- `modules/home/packages/default.nix` and `modules/home/default.nix`
- System packages (flake.nix) and user packages (users/hank.nix)

### Adding New Features

1. **New System Module**: Create in `modules/`, add to flake.nix modules list
2. **New User**: Create `users/username.nix`, reference in home-manager.users
3. **New Host**: Create `machines/hostname.nix`, add new darwinConfiguration in flake.nix

### Testing Changes
Always run these before switching:
```bash
just fmt        # Format code
just check      # Run all checks
just diff       # Preview changes
just switch     # Apply changes
```

## Key Technologies

- **nix-darwin**: macOS system configuration
- **home-manager**: User environment management
- **nixvim**: Neovim configuration as Nix module
- **Homebrew**: Integration for GUI apps and casks
- **just**: Task runner for common commands

## Development Environment

The configuration sets up:
- Modern shell (zsh with starship, fzf, etc.)
- CLI tools (ripgrep, fd, bat, eza, delta)
- Development tools (git, neovim, direnv)
- Cloud tools (AWS CLI, terraform)
- Container tools (docker, podman)
- Nix development (nixd LSP, nixpkgs-fmt)