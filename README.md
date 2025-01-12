# Hank's Nix Darwin Configuration

A modern nix-darwin configuration for managing macOS systems using Nix Flakes, Home Manager, and Homebrew.

## System Overview

This configuration manages two macOS devices:
- `hank-mbp`: MacBook Pro
- `hank-mstio`: Mac Studio

## Directory Structure

```
.
├── flake.nix               # Main flake configuration
├── flake.lock             # Flake dependencies lock file
├── Justfile              # Command runner for common operations
├── home/                 # Home-manager configurations
│   ├── core.nix         # Base home-manager config
│   ├── default.nix      # Home-manager entry point
│   ├── git.nix          # Git configuration
│   ├── shell.nix        # Shell configuration (zsh, etc.)
│   └── starship.nix     # Starship prompt configuration
├── modules/             # System modules
│   ├── apps.nix        # Application configurations
│   ├── homebrew-mirror.nix  # Homebrew package management
│   ├── host-users.nix  # User-specific configurations
│   ├── nix-core.nix    # Core Nix settings
│   └── system.nix      # System-level configurations
└── scripts/            # Utility scripts
    └── darwin_set_proxy.py  # Proxy configuration helper
```

## Setup

### Prerequisites

1. Install Nix:
```bash
curl -L https://nixos.org/nix/install | sh
```

2. Install Homebrew:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Installation

1. Clone this repository:
```bash
git clone https://github.com/hank/dotfiles.git
cd dotfiles
```

2. Bootstrap the system (this will install nix-darwin and set up the initial configuration):
```bash
# For MacBook Pro
just bootstrap hank-mbp

# For Mac Studio
just bootstrap hank-mstio
```

## Usage

The configuration uses [just](https://github.com/casey/just) as a command runner. Available commands:

- `just build [hostname]`: Build the system configuration
- `just switch [hostname]`: Switch to the new configuration
- `just update [hostname]`: Build and switch in one command
- `just check [hostname]`: Check configuration without switching
- `just clean`: Clean up old generations
- `just update-flake`: Update flake inputs
- `just fmt`: Format nix files
- `just info`: Show system information
- `just generations`: List current system generations
- `just full-update [hostname]`: Update everything and clean up

Default hostname is "hank-mstio" if not specified.

## Key Features

- Multi-device management with shared configurations
- Comprehensive application management through both Nix and Homebrew
- Modern shell setup with zsh, starship, and various tools
- Git configuration with extensive aliases and integrations
- System preferences management for macOS
- Development environment setup with various programming languages and tools

## Customization

### Adding a New Host

1. Add the host configuration in `flake.nix`:
```nix
hosts = {
  "new-host" = {
    system = "aarch64-darwin";
    username = "username";
    useremail = "email";
  };
  # ...
};
```

2. Add any host-specific configurations in `modules/host-users.nix`

### Modifying Packages

- Nix packages: Edit `home/core.nix`
- Homebrew packages: Edit `modules/homebrew-mirror.nix`
- System applications: Edit `modules/apps.nix`

## Maintenance

### Updating

To update all packages and configurations:
```bash
just full-update
```

### Troubleshooting

If you encounter issues:
1. Check the build output: `just check`
2. Try building without switching: `just test`
3. View the diff of changes: `just diff`
4. Check system information: `just info`

## License

MIT
