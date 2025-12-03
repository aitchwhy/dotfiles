#!/bin/bash
# # GIT HOOKS SETUP
#
# setup_git_hooks() {
#   local DOTFILES_ROOT="${DOTFILES:-$HOME/dotfiles}"
#   local COMMITIZEN_DIR="$DOTFILES_ROOT/config/git/commitizen"
#   local HOOKS_DIR="$DOTFILES_ROOT/.husky"
#
#   log_info "Setting up Git hooks and conventional commits..."
#
#   # Create .husky directory if it doesn't exist
#   if [ ! -d "$HOOKS_DIR" ]; then
#     mkdir -p "$HOOKS_DIR"
#     log_success "Created hooks directory: $HOOKS_DIR"
#   fi
#
#   # Install commitizen and dependencies
#   if [ -f "$COMMITIZEN_DIR/package.json" ]; then
#     log_info "Installing commitizen dependencies..."
#     (cd "$COMMITIZEN_DIR" && npm install --no-audit --no-fund)
#   else
#     log_error "package.json not found in $COMMITIZEN_DIR"
#     return 1
#   fi
#
#   # Copy commitlint config to dotfiles root
#   if [ -f "$COMMITIZEN_DIR/commitlint.config.js" ]; then
#     log_info "Copying commitlint.config.js to dotfiles root..."
#     cp "$COMMITIZEN_DIR/commitlint.config.js" "$DOTFILES_ROOT/"
#     log_success "Copied commitlint configuration"
#   fi
#
#   # Create commit-msg hook
#   local COMMIT_MSG_HOOK="$HOOKS_DIR/commit-msg"
#   log_info "Creating commit-msg hook..."
#   cat > "$COMMIT_MSG_HOOK" << 'EOF'
# #!/usr/bin/env sh
# . "$(dirname -- "$0")/_/husky.sh"
#
# npx --no-install commitlint --edit $1
# EOF
#   chmod +x "$COMMIT_MSG_HOOK"
#   log_success "Created commit-msg hook"
#
#   # Create pre-commit hook
#   local PRE_COMMIT_HOOK="$HOOKS_DIR/pre-commit"
#   log_info "Creating pre-commit hook..."
#   cat > "$PRE_COMMIT_HOOK" << 'EOF'
# #!/usr/bin/env sh
# . "$(dirname -- "$0")/_/husky.sh"
#
# npx --no-install lint-staged
# EOF
#   chmod +x "$PRE_COMMIT_HOOK"
#   log_success "Created pre-commit hook"
#
#   # Create husky.sh helper script
#   local HUSKY_HELPER="$HOOKS_DIR/_/husky.sh"
#   log_info "Creating husky helper script..."
#   mkdir -p "$HOOKS_DIR/_"
#   cat > "$HUSKY_HELPER" << 'EOF'
# #!/usr/bin/env sh
# if [ -z "$husky_skip_init" ]; then
#   debug () {
#     if [ "$HUSKY_DEBUG" = "1" ]; then
#       echo "husky (debug) - $1"
#     fi
#   }
#
#   readonly hook_name="$(basename -- "$0")"
#   debug "starting $hook_name..."
#
#   if [ "$HUSKY" = "0" ]; then
#     debug "HUSKY env variable is set to 0, skipping hook"
#     exit 0
#   fi
#
#   if [ -f ~/.huskyrc ]; then
#     debug "sourcing ~/.huskyrc"
#     . ~/.huskyrc
#   fi
#
#   readonly husky_skip_init=1
#   export husky_skip_init
#   sh -e "$0" "$@"
#   exitCode="$?"
#
#   if [ $exitCode != 0 ]; then
#     echo "husky - $hook_name hook exited with code $exitCode (error)"
#   fi
#
#   exit $exitCode
# fi
# EOF
#   chmod +x "$HUSKY_HELPER"
#   log_success "Created husky helper script"
#
#   # Create lint-staged.config.js in dotfiles root
#   local LINT_STAGED_CONFIG="$DOTFILES_ROOT/lint-staged.config.js"
#   log_info "Creating lint-staged.config.js..."
#   cat > "$LINT_STAGED_CONFIG" << 'EOF'
# module.exports = {
#   '*.{js,ts,jsx,tsx}': [
#     'eslint --fix',
#   ],
#   '*.{json,md,yml,yaml}': [
#     'prettier --write',
#   ],
#   '*.{sh,bash,zsh}': [
#     'shfmt -i 2 -ci -w',
#   ],
# };
# EOF
#   log_success "Created lint-staged configuration"
#
#   # Update git config to use hooks
#   git config --global core.hooksPath .husky
#
#   log_success "Git hooks and conventional commits setup complete!"
#   log_info "You can now use 'gcz' or 'git-cz' to create conventional commits with fuzzy filtering"
# }
