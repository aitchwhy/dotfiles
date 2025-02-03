# M-Series Optimizations
export HOMEBREW_PREFIX="/opt/homebrew"
export PATH="${HOMEBREW_PREFIX}/bin:${PATH}"

# Metal/Neural Engine
export METAL_DEVICE_WRAPPER_TYPE=1
export TF_ENABLE_METAL=1

# Load Homebrew
eval "$(${HOMEBREW_PREFIX}/bin/brew shellenv)"

# macOS-Specific Aliases
alias flushdns="sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder"
alias showhidden="defaults write com.apple.finder AppleShowAllFiles YES; killall Finder"