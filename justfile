# Root justfile for dotfiles
# Usage: just [command]
# Version: 1.40.0
mod ant '~/dotfiles/.config/just/ant.just'

# Set shell to zsh for all recipes
# set shell := ["zsh", "-cu"]

set dotenv-load
set positional-arguments
# set fallback
# export recipe args as env vars in recipe


# Default recipe - show available commands
default:
    @just --list

choose:
    @just --choose



# -----------------------------------------------------------
# System management
# -----------------------------------------------------------

# Check for missing dependencies
check-deps:
    @echo "=== Checking Dependencies ==="
    @which git >/dev/null || echo "Missing: git"
    @which zsh >/dev/null || echo "Missing: zsh"
    @which brew >/dev/null || echo "Missing: brew"
    @which nvim >/dev/null || echo "Missing: nvim"
    @which starship >/dev/null || echo "Missing: starship"
    @which yazi >/dev/null || echo "Missing: yazi"
    @which just >/dev/null || echo "Missing: just"

# List all changed files since last commit
changed:
    @git status -s

# Reload shell configuration
reload:
    @exec zsh

# Show system information
sysinfo:
    @echo "=== System Information ==="
    @echo "OS: $(uname -s) $(uname -r)"
    @echo "Architecture: $(uname -m)"
    @echo "Hostname: $(hostname)"
    @echo "User: $(whoami)"
    @echo "Shell: $SHELL"
    @echo "Terminal: $TERM"
    @echo "Directory: $(pwd)"
    @echo "Date: $(date)"

# -----------------------------------------------------------
# Documentation
# -----------------------------------------------------------

# View main README
readme:
    @glow README.md

# View PRD (Product Requirements Document)
prd:
    @glow PRD.md

# -----------------------------------------------------------
# ant
# -----------------------------------------------------------
[no-cd]
[group('ant node')]
npm-clean:
    trash ~/.npm **/node_modules

[group('ant sdk')]
[no-cd]
ant-sdk-clean:
    dotnet clean

[group('ant sdk')]
[no-cd]
ant-sdk-restore:
    dotnet restore

[group('ant sdk')]
[no-cd]
ant-sdk-build:
    dotnet build

[group('ant sdk')]
[no-cd]
ant-sdk-test:
    dotnet test --logger "console;verbosity=detailed"

[group('ant sdk')]
[no-cd]
ant-sdk-sample-app appDir="SampleApp":
    dotnet run --project {{appDir}} -- --sample-cases=should-error-corrupted-clinical
    dotnet test --logger "console;verbosity=detailed"

[group('ant sdk')]
[no-cd]
ant-sdk-all: ant-sdk-clean ant-sdk-restore ant-sdk-build ant-sdk-test
    @echo "ant-sdk-all"




# -----------------------------------------------------------
# Homebrew management
# -----------------------------------------------------------
#
# # Install recommended packages from core Brewfile
# install-core:
#     @echo "=== Installing Core Packages ==="
#     @brew bundle install --file=Brewfile.core
#
# # Install all packages including optional ones
# install-full:
#     @echo "=== Installing All Packages ==="
#     @brew bundle install --file=Brewfile.full
#
# # Update all Homebrew packages
# update:
#     @echo "=== Updating Homebrew Packages ==="
#     @brew update
#     @brew upgrade
#     @brew cleanup

# # Create/update Brewfile from currently installed packages
# dump:
#     @echo "=== Creating Brewfile from Installed Packages ==="
#     @brew bundle dump --force --describe
#
# # Check for outdated packages
# outdated:
#     @echo "=== Checking for Outdated Packages ==="
#     @brew outdated

# -----------------------------------------------------------
# utils
# -----------------------------------------------------------

# Follow @README.md instructions

# # View specific tool documentation
# docs tool:
#     @if [ -f "config/{{tool}}/README.md" ]; then \
#         glow "config/{{tool}}/README.md"; \
#     else \
#         echo "No documentation found for {{tool}}"; \
#     fi
#

# # -----------------------------------------------------------
# # Testing
# # -----------------------------------------------------------

# # Run tests for all components
# test *args="":
#     #!/usr/bin/env zsh
#     echo "\033[1;36m=== Running Tests ===\033[0m"

#     # Check if we have vitest
#     if ! command -v vitest &> /dev/null; then
#         echo "\033[1;33mWarning: vitest not found. Installing...\033[0m"
#         npm install -g vitest
#     fi

#     # Set up test directories
#     TEST_DIRS=()

#     # Find all test directories
#     for dir in $(find . -name "tests" -type d | grep -v "node_modules"); do
#         if [[ -n "$(find "$dir" -name "*.test.*" -o -name "*.spec.*" 2>/dev/null)" ]]; then
#             TEST_DIRS+=("$dir")
#         fi
#     done

#     # Run tests for each directory
#     if [[ ${#TEST_DIRS[@]} -eq 0 ]]; then
#         echo "\033[1;33mNo test directories found\033[0m"
#     else
#         for dir in "${TEST_DIRS[@]}"; do
#             COMPONENT=$(echo "$dir" | sed 's|./||' | sed 's|/tests.*||')
#             echo "\033[1;36mTesting: $COMPONENT\033[0m"

#             # Check for specific test runner commands
#             if [[ -f "$dir/../package.json" ]]; then
#                 # Use npm test if available
#                 CURR_DIR=$(pwd)
#                 cd "$dir/.." || continue
#                 npm test {{args}} || echo "\033[1;31mTests failed for $COMPONENT\033[0m"
#                 cd "$CURR_DIR" || continue
#             elif [[ -n "$(find "$dir" -name "*.test.*" -o -name "*.spec.*" 2>/dev/null)" ]]; then
#                 # Use vitest directly
#                 vitest run "$dir/**/*.{test,spec}.{js,ts,jsx,tsx}" {{args}} || echo "\033[1;31mTests failed for $COMPONENT\033[0m"
#             else
#                 echo "\033[1;33mNo tests found for $COMPONENT\033[0m"
#             fi
#         done
#     fi

#     # Run semgrep validation if available
#     if command -v semgrep &> /dev/null; then
#         echo "\033[1;36mRunning Semgrep Validation\033[0m"
#         semgrep --config=p/r2c-security-audit .
#     else
#         echo "\033[1;33mSemgrep not found, skipping validation\033[0m"
#     fi

# # Run tests for a specific component
# test-component component *args="":
#     #!/usr/bin/env zsh
#     echo "\033[1;36m=== Testing: {{component}} ===\033[0m"

#     # Find test directory
#     TEST_DIR=""
#     if [[ -d "./{{component}}/tests" ]]; then
#         TEST_DIR="./{{component}}/tests"
#     elif [[ -d "./config/{{component}}/tests" ]]; then
#         TEST_DIR="./config/{{component}}/tests"
#     else
#         for dir in $(find . -path "*{{component}}*/tests" -type d); do
#             TEST_DIR="$dir"
#             break
#         done
#     fi

#     if [[ -z "$TEST_DIR" ]]; then
#         echo "\033[1;31mNo test directory found for {{component}}\033[0m"
#         exit 1
#     fi

#     # Check for specific test runner commands
#     if [[ -f "$TEST_DIR/../package.json" ]]; then
#         # Use npm test if available
#         CURR_DIR=$(pwd)
#         cd "$TEST_DIR/.." || exit 1
#         npm test {{args}} || echo "\033[1;31mTests failed for {{component}}\033[0m"
#         cd "$CURR_DIR" || exit 1
#     elif [[ -n "$(find "$TEST_DIR" -name "*.test.*" -o -name "*.spec.*" 2>/dev/null)" ]]; then
#         # Use vitest directly
#         vitest run "$TEST_DIR/**/*.{test,spec}.{js,ts,jsx,tsx}" {{args}} || echo "\033[1;31mTests failed for {{component}}\033[0m"
#     else
#         echo "\033[1;33mNo tests found for {{component}}\033[0m"
#     fi

# # Set up git pre-commit hooks for validation
# setup-hooks:
#     #!/usr/bin/env zsh
#     echo "\033[1;36m=== Setting Up Git Hooks ===\033[0m"

#     # Create hooks directory if it doesn't exist
#     mkdir -p .git/hooks

#     # Create pre-commit hook
#     cat > .git/hooks/pre-commit << 'EOL'
# #!/usr/bin/env zsh
# set -e

# echo "Running pre-commit hooks..."

# # Get changed files
# CHANGED_FILES=$(git diff --cached --name-only --diff-filter=ACM)

# # Skip if no files changed
# if [[ -z "$CHANGED_FILES" ]]; then
#     echo "No files to validate"
#     exit 0
# fi

# # Run tests for components with changed files
# COMPONENTS=()
# for file in $CHANGED_FILES; do
#     if [[ "$file" == config/* ]]; then
#         COMP=$(echo "$file" | cut -d'/' -f2)
#         COMPONENTS+=("$COMP")
#     fi
# done

# # Deduplicate components
# COMPONENTS=($(echo "${COMPONENTS[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))

# # Run tests for changed components
# for comp in "${COMPONENTS[@]}"; do
#     echo "Running tests for component: $comp"
#     just test-component "$comp" || exit 1
# done

# # Run semgrep if available
# if command -v semgrep &> /dev/null; then
#     echo "Running semgrep validation..."
#     semgrep --config=p/r2c-security-audit $CHANGED_FILES || exit 1
# fi

# # Check if PRD matches implementation for each component
# for comp in "${COMPONENTS[@]}"; do
#     # Only check if PRD exists
#     if [[ -f "config/$comp/PRD.md" ]]; then
#         echo "Validating PRD for component: $comp"

#         # Use claude-cli if available to validate PRD
#         if command -v claude &> /dev/null; then
#             echo "Using Claude to validate PRD implementation..."
#             PRD_CONTENT=$(cat "config/$comp/PRD.md")
#             IMPL_FILES=$(find "config/$comp" -type f -not -path "*/\.*" -not -name "PRD.md" -not -name "README.md" | xargs cat)

#             claude --max-tokens 200 --message "Validate if the implementation matches the PRD requirements. Reply ONLY with 'PASS' or 'FAIL: reason'. PRD: $PRD_CONTENT Implementation: $IMPL_FILES" | grep -q "^PASS" || {
#                 echo "PRD validation failed for $comp";
#                 exit 1;
#             }
#         fi
#     fi
# done

# echo "Pre-commit hooks passed!"
# exit 0
# EOL

#     # Make hook executable
#     chmod +x .git/hooks/pre-commit

#     echo "\033[1;32mGit hooks installed successfully\033[0m"
