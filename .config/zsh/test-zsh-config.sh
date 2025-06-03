#!/usr/bin/env zsh
# Test script for zsh configuration

set -e

echo "Testing ZSH Configuration..."
echo "============================"

# Test 1: Check if zsh can source configuration files
echo -n "Test 1: Sourcing configuration files... "
zsh -c 'source $HOME/.config/zsh/.zshenv && source $HOME/.config/zsh/.zprofile && source $HOME/.config/zsh/.zshrc' 2>/dev/null && echo "✓ PASS" || echo "✗ FAIL"

# Test 2: Check essential environment variables
echo -n "Test 2: Essential environment variables... "
zsh -c '
source $HOME/.config/zsh/.zshenv
[[ -n "$DOTFILES" ]] && [[ -n "$XDG_CONFIG_HOME" ]] && [[ -n "$ZDOTDIR" ]] && [[ -n "$PATH" ]]
' && echo "✓ PASS" || echo "✗ FAIL"

# Test 3: Check if PATH contains essential directories
echo -n "Test 3: PATH configuration... "
zsh -c '
source $HOME/.config/zsh/.zshenv
source $HOME/.config/zsh/.zprofile
echo $PATH | grep -q "/opt/homebrew/opt/coreutils/libexec/gnubin" && echo $PATH | grep -q "$HOME/.volta/bin"
' && echo "✓ PASS" || echo "✗ FAIL"

# Test 4: Check if key aliases are defined
echo -n "Test 4: Alias definitions... "
zsh -ic '
alias | grep -q "^ls=" && alias | grep -q "^ll=" && alias | grep -q "^v="
' 2>/dev/null && echo "✓ PASS" || echo "✗ FAIL"

# Test 5: Check if functions are defined
echo -n "Test 5: Function definitions... "
zsh -ic '
type has_command >/dev/null 2>&1 && type cdf >/dev/null 2>&1 && type vf >/dev/null 2>&1
' && echo "✓ PASS" || echo "✗ FAIL"

# Test 6: Check completion system
echo -n "Test 6: Completion system... "
zsh -ic 'compinit -C; echo ${#_comps}' 2>/dev/null | grep -q '^[0-9]\+$' && echo "✓ PASS" || echo "✗ FAIL"

# Test 7: Check if Homebrew is properly configured
echo -n "Test 7: Homebrew configuration... "
zsh -ic '[[ -n "$HOMEBREW_PREFIX" ]]' 2>/dev/null && echo "✓ PASS" || echo "✗ FAIL"

# Test 8: Interactive shell test
echo -n "Test 8: Interactive shell startup... "
timeout 2 zsh -ic 'echo "interactive shell works"' >/dev/null 2>&1 && echo "✓ PASS" || echo "✗ FAIL"

echo "============================"
echo "Configuration test complete!"