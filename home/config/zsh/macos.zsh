# ~/dotfiles/home/zsh/macos.zsh - macOS specific settings
# M-Series optimizations
export HOMEBREW_PREFIX="/opt/homebrew"
export PATH="${HOMEBREW_PREFIX}/bin:${PATH}"

# Metal/Neural Engine
export METAL_DEVICE_WRAPPER_TYPE=1
export TF_ENABLE_METAL=1

# macOS aliases
alias flushdns="sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder"
alias showhidden="defaults write com.apple.finder AppleShowAllFiles YES; killall Finder"
Last edited 28 minutes ago


