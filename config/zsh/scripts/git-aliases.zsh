# Git & conventional commits aliases for zsh
# Adds support for commitizen, fuzzy git operations, and more
# (c) 2025 Hank

# Commitizen aliases
alias git-cz='npx --no-install -- cz'
alias gcz='git-cz'
alias gczf='npx --no-install -- cz --no-verify'  # Skip commitlint hooks

# Fuzzy git operations
alias gfa='git fzadd'            # Fuzzy add files 
alias gfc='git fzcommit'         # Fuzzy add files and commit
alias gaic='git ai-commit'       # AI-assisted commit

# Enhanced log views
alias gll='git log --graph --pretty=format:"%C(yellow)%h%Cred%d %Creset%s%Cblue [%cn]" --decorate --numstat'
alias glc='git log --graph --pretty=format:"%C(yellow)%h%Cred%d %Creset%s%Cblue [%cn]" --decorate --numstat --all'

# Branch operations with fuzzy finding
alias gco='git checkout $(git branch | fzf | tr -d "[:space:]*")'  # Fuzzy checkout branch
alias gbr='git branch -a | fzf | tr -d "[:space:]*" | xargs git checkout'

# Run commitlint on last commit
alias gclint='npx --no-install commitlint --from HEAD~1 --to HEAD'

# Load custom setup
function git-setup-conv() {
  local INSTALL_DIR="$HOME/dotfiles/config/git/commitizen"
  
  echo "Setting up conventional commits workflow..."
  
  # Install dependencies if not present
  if [ ! -d "$INSTALL_DIR/node_modules" ]; then
    (cd "$INSTALL_DIR" && npm install)
  fi
  
  # Set up hooks
  (cd "$INSTALL_DIR" && node scripts/setup-hooks.js)
  
  echo "✅ Conventional commits setup complete!"
  echo "Commands available:"
  echo "  - git-cz or gcz     : Start commitizen for fuzzy conventional commits"
  echo "  - gfa               : Fuzzy add files"
  echo "  - gfc               : Fuzzy add and commit"
  echo "  - gaic              : Use AI to generate commit message"
  echo ""
  echo "See more aliases in: $HOME/dotfiles/config/zsh/git-aliases.zsh"
}

# Function to show help for conventional commits 
function git-conv-help() {
  echo "🔍 Conventional Commits Quick Guide"
  echo "===================================="
  echo "Types:"
  echo "  feat     : A new feature"
  echo "  fix      : A bug fix"
  echo "  docs     : Documentation only changes"
  echo "  style    : Changes that don't affect code meaning"
  echo "  refactor : Code change that neither fixes bug nor adds feature"
  echo "  perf     : Performance improvement"
  echo "  test     : Adding or fixing tests"
  echo "  build    : Changes to build system or dependencies"
  echo "  ci       : Changes to CI configuration"
  echo "  chore    : Other changes not modifying src or test"
  echo "  revert   : Reverts a previous commit"
  echo ""
  echo "Format:"
  echo "  type(scope): description  # scope is optional"
  echo ""
  echo "Breaking Changes:"
  echo "  type(scope)!: description"
  echo "  OR add BREAKING CHANGE: in commit body"
  echo ""
  echo "Use 'git-cz' or 'gcz' for interactive commit with fuzzy filtering"
}