#!/bin/bash
# setup-git-hooks.sh
# Sets up Git hooks and commitizen configuration for conventional commits workflow
# This script is called by the main setup.sh script

set -e

DOTFILES_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMMITIZEN_DIR="$DOTFILES_ROOT/config/git/commitizen"
HOOKS_DIR="$DOTFILES_ROOT/.husky"

echo "📦 Setting up Git hooks and conventional commits..."

# Create .husky directory if it doesn't exist
if [ ! -d "$HOOKS_DIR" ]; then
  mkdir -p "$HOOKS_DIR"
  echo "Created hooks directory: $HOOKS_DIR"
fi

# Install commitizen and dependencies
if [ -f "$COMMITIZEN_DIR/package.json" ]; then
  echo "Installing commitizen dependencies..."
  (cd "$COMMITIZEN_DIR" && npm install --no-audit --no-fund)
else
  echo "Error: package.json not found in $COMMITIZEN_DIR"
  exit 1
fi

# Copy commitlint config to dotfiles root
if [ -f "$COMMITIZEN_DIR/commitlint.config.js" ]; then
  echo "Copying commitlint.config.js to dotfiles root..."
  cp "$COMMITIZEN_DIR/commitlint.config.js" "$DOTFILES_ROOT/"
  echo "Copied commitlint configuration"
fi

# Create commit-msg hook
COMMIT_MSG_HOOK="$HOOKS_DIR/commit-msg"
echo "Creating commit-msg hook..."
cat > "$COMMIT_MSG_HOOK" << 'EOF'
#!/usr/bin/env sh
. "$(dirname -- "$0")/_/husky.sh"

npx --no-install commitlint --edit $1
EOF
chmod +x "$COMMIT_MSG_HOOK"
echo "Created commit-msg hook"

# Create pre-commit hook
PRE_COMMIT_HOOK="$HOOKS_DIR/pre-commit"
echo "Creating pre-commit hook..."
cat > "$PRE_COMMIT_HOOK" << 'EOF'
#!/usr/bin/env sh
. "$(dirname -- "$0")/_/husky.sh"

npx --no-install lint-staged
EOF
chmod +x "$PRE_COMMIT_HOOK"
echo "Created pre-commit hook"

# Create husky.sh helper script
HUSKY_HELPER="$HOOKS_DIR/_/husky.sh"
echo "Creating husky helper script..."
mkdir -p "$HOOKS_DIR/_"
cat > "$HUSKY_HELPER" << 'EOF'
#!/usr/bin/env sh
if [ -z "$husky_skip_init" ]; then
  debug () {
    if [ "$HUSKY_DEBUG" = "1" ]; then
      echo "husky (debug) - $1"
    fi
  }

  readonly hook_name="$(basename -- "$0")"
  debug "starting $hook_name..."

  if [ "$HUSKY" = "0" ]; then
    debug "HUSKY env variable is set to 0, skipping hook"
    exit 0
  fi

  if [ -f ~/.huskyrc ]; then
    debug "sourcing ~/.huskyrc"
    . ~/.huskyrc
  fi

  readonly husky_skip_init=1
  export husky_skip_init
  sh -e "$0" "$@"
  exitCode="$?"

  if [ $exitCode != 0 ]; then
    echo "husky - $hook_name hook exited with code $exitCode (error)"
  fi

  exit $exitCode
fi
EOF
chmod +x "$HUSKY_HELPER"
echo "Created husky helper script"

# Create lint-staged.config.js in dotfiles root
LINT_STAGED_CONFIG="$DOTFILES_ROOT/lint-staged.config.js"
echo "Creating lint-staged.config.js..."
cat > "$LINT_STAGED_CONFIG" << 'EOF'
module.exports = {
  '*.{js,ts,jsx,tsx}': [
    'eslint --fix',
  ],
  '*.{json,md,yml,yaml}': [
    'prettier --write',
  ],
  '*.{sh,bash,zsh}': [
    'shfmt -i 2 -ci -w',
  ],
};
EOF
echo "Created lint-staged configuration"

# Update git config to use hooks
git config --global core.hooksPath .husky

echo "✅ Git hooks and conventional commits setup complete!"
echo "You can now use 'gcz' or 'git-cz' to create conventional commits with fuzzy filtering"