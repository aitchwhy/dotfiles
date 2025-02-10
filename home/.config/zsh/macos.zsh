# macos.zsh
# macOS / Apple Silicon specific config

# Use /opt/homebrew if on Apple Silicon
# export HOMEBREW_PREFIX="/opt/homebrew"
export PATH="$HOMEBREW_PREFIX/bin:$PATH"

# Example: flush DNS
alias flushdns="sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder"
alias showhidden="defaults write com.apple.finder AppleShowAllFiles YES; killall Finder"

# Enable TF metal acceleration
export METAL_DEVICE_WRAPPER_TYPE=1
export TF_ENABLE_METAL=1
