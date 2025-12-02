# Hank's Nix Configuration

A modular, maintainable nix-darwin configuration for macOS systems with comprehensive tooling and automation.

## Features

- 🎯 **Modular Architecture**: Clean separation of concerns with focused modules
- 🔧 **Comprehensive Tooling**: Bootstrap, health-check, and recovery scripts
- 🧪 **Full Test Suite**: Unit and integration tests with CI/CD
- 📚 **Rich Documentation**: Architecture diagrams and detailed guides
- 🚀 **Modern Development**: Latest tools and best practices
- 🔒 **Security First**: Proper secrets handling and validation

## Quick Start

### Prerequisites

- macOS (Intel or Apple Silicon)
- Internet connection
- Administrator access

### Installation

1. **Run the bootstrap script**:
   ```bash
   curl -L https://raw.githubusercontent.com/yourusername/nixdots/main/scripts/bootstrap.sh | bash
   ```

2. **Or manually**:
   ```bash
   # Install Nix
   curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
   
   # Clone repository
   git clone https://github.com/yourusername/nixdots.git ~/nixdots
   cd ~/nixdots
   
   # Build and switch
   darwin-rebuild switch --flake .#$(hostname -s)
   ```

## Structure

```
.
├── flake.nix              # Entry point defining systems
├── lib/                   # Helper functions and abstractions
│   ├── mkSystem.nix      # System builder functions
│   ├── options.nix       # Option type helpers
│   └── validators.nix    # Configuration validators
├── modules/               # Modular system configuration
│   ├── core/             # Core system modules
│   ├── darwin/           # macOS-specific modules
│   │   ├── ui/          # UI customizations
│   │   ├── system/      # System preferences
│   │   └── apps/        # Application settings
│   ├── home/            # User environment modules
│   │   ├── shell/       # Shell configurations
│   │   ├── tools/       # Development tools
│   │   └── editors/     # Editor settings
│   └── services/        # System services
├── machines/             # Host-specific configurations
├── users/               # User-specific configurations
├── scripts/             # Operational scripts
│   ├── bootstrap.sh     # Initial setup
│   ├── health-check.sh  # System verification
│   └── recovery.sh      # Disaster recovery
├── tests/               # Test infrastructure
└── docs/                # Documentation
```

## Common Commands

### Using Just

```bash
# Most common - rebuild and switch
just switch        # or: just s

# Build without switching
just build         # or: just b

# Update all inputs
just update        # or: just u

# Format code
just fmt

# Run checks
just check

# Clean old generations
just clean         # or: just gc

# Show available commands
just
```

### Direct Commands

```bash
# Rebuild system
darwin-rebuild switch --flake .#$(hostname -s)

# Check configuration
nix flake check

# Update inputs
nix flake update

# Garbage collection
nix-collect-garbage -d
```

## Configuration

### System Architecture

The configuration uses a modular architecture with clear separation:

1. **Core Modules** (`modules/core/`): Nix settings, security
2. **Darwin Modules** (`modules/darwin/`): macOS customizations
3. **Home Modules** (`modules/home/`): User environment
4. **Service Modules** (`modules/services/`): System services

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for detailed architecture documentation.

### Adding a New Machine

1. Create `machines/hostname.nix`:
   ```nix
   { config, pkgs, lib, ... }:
   {
     networking.hostName = "hostname";
     system.stateVersion = 4;
     
     # Machine-specific configuration
   }
   ```

2. Add to `flake.nix`:
   ```nix
   darwinConfigurations.hostname = nix-darwin.lib.darwinSystem {
     system = "aarch64-darwin";  # or "x86_64-darwin"
     modules = [
       ./modules/core/nix.nix
       ./modules/darwin
       ./modules/services/homebrew.nix
       ./machines/hostname.nix
       # ... user config
     ];
   };
   ```

### Customizing Modules

Enable/disable specific features in your user configuration:

```nix
{
  # Disable specific darwin modules
  modules.darwin.safari.enable = false;
  
  # Configure git
  modules.home.tools.git = {
    userName = "Your Name";
    userEmail = "your.email@example.com";
    signing.enable = true;
    signing.key = "YOUR_GPG_KEY";
  };
  
  # Choose shell prompt style
  modules.home.shell.prompts.style = "full";  # minimal, full, custom
}
```

## Key Features

### Development Environment

- **Modern Shell**: Zsh with autosuggestions, syntax highlighting
- **Smart Prompt**: Starship with git integration
- **CLI Tools**: ripgrep, fd, bat, eza, delta, and more
- **Development**: Git, tmux, neovim, direnv, fzf
- **Languages**: Node.js, Python, Go, Rust (via user config)

### macOS Integration

- **System Preferences**: Dock, Finder, keyboard, trackpad
- **Security**: Touch ID for sudo, FileVault
- **Applications**: Safari, Terminal, Activity Monitor settings
- **Homebrew**: GUI applications and Mac App Store apps

### Operational Excellence

- **Bootstrap Script**: Zero to functional system
- **Health Checks**: System verification and diagnostics
- **Recovery Tools**: Rollback and repair capabilities
- **Test Suite**: Automated testing for all modules
- **CI/CD**: GitHub Actions for continuous validation

## Troubleshooting

### Quick Fixes

```bash
# Run health check
./scripts/health-check.sh

# Enter recovery mode
./scripts/recovery.sh

# Rollback to previous generation
darwin-rebuild --rollback

# Fix Nix store permissions
sudo nix-store --verify --check-contents --repair
```

### Common Issues

1. **Module not found**: Check import paths and typos
2. **Build failures**: Run with `--show-trace` for details
3. **Permission denied**: Ensure proper sudo access
4. **Flake issues**: Try `nix flake update`

## Development

### Running Tests

```bash
# Run all tests
just test

# Run specific test suite
./tests/unit/test-modules.sh
./tests/integration/test-full-build.sh

# Validate structure
./tests/lib/validate-structure.sh
```

### Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests
5. Submit a pull request

## Security

- **No secrets in code**: Use environment variables or secret management
- **Validated inputs**: All configuration options are type-checked
- **Minimal permissions**: Only request necessary access
- **Regular updates**: Keep dependencies current

## Performance

- **Fast evaluation**: < 5 second configuration evaluation
- **Optimized builds**: Shared nixpkgs, minimal rebuilds
- **Efficient runtime**: Lazy loading, optimized PATH
- **Smart caching**: Nix store deduplication

## License

MIT - See [LICENSE](LICENSE) file for details.

## Acknowledgments

Inspired by the Nix community and various configurations:
- [Mitchell Hashimoto's nixos-config](https://github.com/mitchellh/nixos-config)
- [nix-darwin](https://github.com/LnL7/nix-darwin)
- [home-manager](https://github.com/nix-community/home-manager)

---

For detailed architecture documentation, see [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).
For improvement plans and roadmap, see [NIX_FIX.md](NIX_FIX.md).