# Package Management Troubleshooting

Common issues and solutions for package management systems (Nix, Homebrew, uv).

## Homebrew Issues

### Brew Update Failures

**Symptoms:**
- `brew update` fails with repository errors
- Outdated formulae cannot be updated

**Solutions:**

1. Reset Homebrew's repository:
```bash
cd "$(brew --repo)"
git fetch
git reset --hard origin/master
```

2. Clear Homebrew's cache:
```bash
rm -rf "$(brew --cache)"
brew update
```

3. Full reset (if nothing else works):
```bash
cd "$(brew --repo)/Library/Taps/homebrew/homebrew-core"
git fetch
git reset --hard origin/master
brew update
```

### Brew Install Failures

**Symptoms:**
- Package installation fails with dependency errors
- Build errors during compilation

**Solutions:**

1. Update Homebrew and retry:
```bash
brew update && brew upgrade
brew install <package>
```

2. Clear and rebuild:
```bash
brew cleanup
brew doctor --verbose
# Fix any issues mentioned, then:
brew install <package>
```

3. Install with verbose logging:
```bash
HOMEBREW_NO_AUTO_UPDATE=1 brew install -v <package>
```

4. Force linking:
```bash
brew link --overwrite <package>
```

### Permission Issues

**Symptoms:**
- Permission denied errors
- Unable to write to Homebrew directories

**Solutions:**

1. Check ownership:
```bash
ls -la "$(brew --prefix)"
```

2. Fix permissions:
```bash
sudo chown -R $(whoami):admin $(brew --prefix)/*
```

## Nix Issues

### Nix Store Corruption

**Symptoms:**
- Hash mismatch errors
- Failed builds with integrity verification errors

**Solutions:**

1. Verify and repair the Nix store:
```bash
nix-store --verify --check-contents --repair
```

2. Garbage collect and optimize:
```bash
nix-collect-garbage -d
nix-store --optimize
```

### Nix Channel Update Issues

**Symptoms:**
- Channel update failures
- Package builds referring to missing dependencies

**Solutions:**

1. Update with verbose logging:
```bash
nix-channel --update -v
```

2. Refresh channels and rebuild:
```bash
nix-channel --update
nixos-rebuild build
```

3. Rollback to a previous generation:
```bash
nix-env --rollback
# Or for a specific generation:
nix-env --list-generations
nix-env --switch-generation <num>
```

### Nix Flake Issues

**Symptoms:**
- Unable to update flake inputs
- Errors about lockfile or registry

**Solutions:**

1. Force update flakes:
```bash
nix flake update --recreate-lock-file
```

2. Clear the nix path:
```bash
rm ~/.cache/nix/flake-registry.json
nix registry list
```

3. Update specific input:
```bash
nix flake update --update-input nixpkgs
```

## Python/uv Issues

### Package Installation Failures

**Symptoms:**
- Unable to install packages with dependency conflicts
- Compilation errors for packages with C extensions

**Solutions:**

1. Clear cache and try again:
```bash
uv cache clean
uv pip install <package>
```

2. Install with specific compiler flags:
```bash
CFLAGS="-I$(brew --prefix openssl)/include" LDFLAGS="-L$(brew --prefix openssl)/lib" uv pip install <package>
```

3. Install from source:
```bash
uv pip install --no-binary=:all: <package>
```

### Virtual Environment Issues

**Symptoms:**
- Environment activation problems
- Path conflicts between environments

**Solutions:**

1. Create fresh environment:
```bash
uv venv env
source env/bin/activate
```

2. Recreate with specific Python version:
```bash
uv venv --python=python3.11 env
```

### Python Version Conflicts

**Symptoms:**
- "Wrong Python version" errors
- Package incompatibilities due to Python version

**Solutions:**

1. Check current Python versions:
```bash
uv python --list
```

2. Create environment with specific version:
```bash
uv venv --python=python3.11 env
```

## Cross-Package Manager Issues

### Path Conflicts

**Symptoms:**
- Commands found in unexpected locations
- Version mismatches between expected and actual

**Solutions:**

1. Check command locations:
```bash
which -a <command>
```

2. Inspect PATH variable:
```bash
echo $PATH | tr ':' '\n'
```

3. Prioritize paths in .zshrc/.zprofile:
```bash
# Example priority order
export PATH="$HOME/.nix-profile/bin:$PATH"
export PATH="/opt/homebrew/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
```

### Library Conflicts

**Symptoms:**
- Library not found errors
- Wrong version of shared libraries loaded

**Solutions:**

1. Check dynamic library paths:
```bash
otool -L $(which <command>)
```

2. Set specific library paths:
```bash
export DYLD_LIBRARY_PATH="/opt/homebrew/lib:$DYLD_LIBRARY_PATH"
```

## Performance Optimization

### Slow Package Operations

**Symptoms:**
- Package installations taking unusually long
- High CPU/memory usage during operations

**Solutions:**

1. For Homebrew:
```bash
# Analyze dependencies
brew deps --tree <formula>

# Check if a package is installed
brew list | grep <formula>
```

2. For Nix:
```bash
# Use binary caches
nix-store --verify --check-contents
nix-store --optimise

# Add cachix
nix-env -iA cachix -f https://cachix.org/api/v1/install
cachix use <cache-name>
```

3. For Python/uv:
```bash
# Use wheels instead of source
uv pip install --prefer-binary <package>
