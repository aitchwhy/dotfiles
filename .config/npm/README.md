# NPM Configuration

This directory contains npm configuration for the dotfiles setup.

## Structure

- `.npmrc` - User-level npm configuration (symlinked to ~/.npmrc)
- `global-packages.txt` - List of global npm packages to install
- `setup.sh` - Setup script to configure npm
- `.npm-global` - Legacy config file (can be removed after migration)

## Setup

Run the setup script to configure npm:

```bash
./setup.sh
```

To also install global packages:

```bash
./setup.sh --install-globals
```

## Configuration Details

### Directories
- **Global packages**: `~/dotfiles/.config/npm-global/`
- **Cache**: `~/.cache/npm/`
- **Config**: `~/dotfiles/.config/npm/.npmrc`

### Environment Variables
The following environment variable should be set in your shell:

```bash
export PATH="$PATH:$HOME/dotfiles/.config/npm-global/bin"
```

Note: The `NPM_CONFIG_USERCONFIG` environment variable is no longer needed with this setup,
as npm will automatically use `~/.npmrc` which is symlinked to our config.

## Managing Global Packages

To add a new global package to the list:
1. Edit `global-packages.txt`
2. Run `npm install -g <package-name>`

To reinstall all global packages on a new machine:
```bash
cat global-packages.txt | grep -v '^#' | xargs npm install -g
```

## Migration from Old Setup

The old setup used:
- Config file: `.npm-global` (should be `.npmrc`)
- Environment variable: `NPM_CONFIG_USERCONFIG`

After running the setup script, you can:
1. Remove the old `.npm-global` file
2. Remove the `NPM_CONFIG_USERCONFIG` export from your shell config
3. Ensure PATH includes the npm global bin directory