#!/usr/bin/env bats
# System settings verification tests for macOS Nix Darwin configuration
# Run with: bats tests/system-settings.bats
#
# These tests verify that darwin-rebuild switch applied settings correctly.
# NOTE: Some settings require LOG OUT/LOG IN to take full effect.

# ============================================================================
# Helper Functions
# ============================================================================

# Read a defaults value, returning empty string if not found
read_default() {
  /usr/bin/defaults read "$1" "$2" 2>/dev/null || echo ""
}

# Normalize boolean values (macOS uses 0/1, true/false inconsistently)
normalize_bool() {
  case "$1" in
    0|false|no|NO|False) echo "0" ;;
    1|true|yes|YES|True) echo "1" ;;
    *) echo "$1" ;;
  esac
}

# ============================================================================
# Keyboard Tests
# ============================================================================

@test "keyboard: fnState = 0 (F12 = Volume Up by default)" {
  result=$(normalize_bool "$(read_default NSGlobalDomain com.apple.keyboard.fnState)")
  [ "$result" = "0" ]
}

@test "keyboard: InitialKeyRepeat = 15 (225ms delay)" {
  result=$(read_default NSGlobalDomain InitialKeyRepeat)
  [ "$result" = "15" ]
}

@test "keyboard: KeyRepeat = 2 (30ms repeat rate)" {
  result=$(read_default NSGlobalDomain KeyRepeat)
  [ "$result" = "2" ]
}

@test "keyboard: ApplePressAndHoldEnabled = false (key repeat enabled)" {
  result=$(normalize_bool "$(read_default NSGlobalDomain ApplePressAndHoldEnabled)")
  [ "$result" = "0" ]
}

@test "keyboard: NSAutomaticSpellingCorrectionEnabled = false" {
  result=$(normalize_bool "$(read_default NSGlobalDomain NSAutomaticSpellingCorrectionEnabled)")
  [ "$result" = "0" ]
}

@test "keyboard: NSAutomaticCapitalizationEnabled = false" {
  result=$(normalize_bool "$(read_default NSGlobalDomain NSAutomaticCapitalizationEnabled)")
  [ "$result" = "0" ]
}

@test "keyboard: NSAutomaticDashSubstitutionEnabled = false" {
  result=$(normalize_bool "$(read_default NSGlobalDomain NSAutomaticDashSubstitutionEnabled)")
  [ "$result" = "0" ]
}

@test "keyboard: NSAutomaticQuoteSubstitutionEnabled = false" {
  result=$(normalize_bool "$(read_default NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled)")
  [ "$result" = "0" ]
}

@test "keyboard: NSAutomaticPeriodSubstitutionEnabled = false" {
  result=$(normalize_bool "$(read_default NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled)")
  [ "$result" = "0" ]
}

# ============================================================================
# Trackpad Tests (Built-in)
# ============================================================================

@test "trackpad: Clicking = 1 (tap-to-click enabled)" {
  result=$(normalize_bool "$(read_default com.apple.AppleMultitouchTrackpad Clicking)")
  [ "$result" = "1" ]
}

@test "trackpad: TrackpadRightClick = 1 (two-finger right-click)" {
  result=$(normalize_bool "$(read_default com.apple.AppleMultitouchTrackpad TrackpadRightClick)")
  [ "$result" = "1" ]
}

@test "trackpad: TrackpadThreeFingerDrag = 0 (disabled)" {
  result=$(normalize_bool "$(read_default com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag)")
  [ "$result" = "0" ]
}

@test "trackpad: TrackpadFourFingerPinchGesture = 2 (Launchpad enabled)" {
  result=$(read_default com.apple.AppleMultitouchTrackpad TrackpadFourFingerPinchGesture)
  [ "$result" = "2" ]
}

@test "trackpad: TrackpadFourFingerVertSwipeGesture = 2 (Mission Control enabled)" {
  result=$(read_default com.apple.AppleMultitouchTrackpad TrackpadFourFingerVertSwipeGesture)
  [ "$result" = "2" ]
}

@test "trackpad: TrackpadFourFingerHorizSwipeGesture = 2 (App Switch enabled)" {
  result=$(read_default com.apple.AppleMultitouchTrackpad TrackpadFourFingerHorizSwipeGesture)
  [ "$result" = "2" ]
}

@test "trackpad: TrackpadFiveFingerPinchGesture = 2" {
  result=$(read_default com.apple.AppleMultitouchTrackpad TrackpadFiveFingerPinchGesture)
  [ "$result" = "2" ]
}

@test "trackpad: TrackpadThreeFingerHorizSwipeGesture = 2" {
  result=$(read_default com.apple.AppleMultitouchTrackpad TrackpadThreeFingerHorizSwipeGesture)
  [ "$result" = "2" ]
}

@test "trackpad: TrackpadThreeFingerVertSwipeGesture = 2" {
  result=$(read_default com.apple.AppleMultitouchTrackpad TrackpadThreeFingerVertSwipeGesture)
  [ "$result" = "2" ]
}

# ============================================================================
# Screenshot Tests
# ============================================================================

@test "screenshot: type = png" {
  result=$(read_default com.apple.screencapture type)
  [ "$result" = "png" ]
}

@test "screenshot: disable-shadow = 1 (no window shadow)" {
  result=$(normalize_bool "$(read_default com.apple.screencapture disable-shadow)")
  [ "$result" = "1" ]
}

@test "screenshot: location contains Screenshots" {
  result=$(read_default com.apple.screencapture location)
  [[ "$result" == *"Screenshots"* ]]
}

# ============================================================================
# Spaces / Mission Control Tests
# ============================================================================

@test "spaces: mru-spaces = 0 (no auto-rearrange)" {
  result=$(normalize_bool "$(read_default com.apple.dock mru-spaces)")
  [ "$result" = "0" ]
}

@test "spaces: spans-displays = 0 (separate per display)" {
  result=$(read_default com.apple.spaces spans-displays)
  [ "$result" = "0" ]
}

# ============================================================================
# Window Manager Tests
# ============================================================================

@test "window-manager: Stage Manager disabled" {
  result=$(normalize_bool "$(read_default com.apple.WindowManager GloballyEnabled 2>/dev/null || echo 0)")
  [ "$result" = "0" ]
}

@test "window-manager: click-to-show-desktop disabled" {
  result=$(read_default com.apple.WindowManager EnableStandardClickToShowDesktop 2>/dev/null || echo 0)
  [ "$result" = "0" ]
}

# ============================================================================
# Dock Tests
# ============================================================================

@test "dock: autohide = 1 (auto-hide enabled)" {
  result=$(normalize_bool "$(read_default com.apple.dock autohide)")
  [ "$result" = "1" ]
}

@test "dock: orientation = left" {
  result=$(read_default com.apple.dock orientation)
  [ "$result" = "left" ]
}

@test "dock: show-recents = 0" {
  result=$(normalize_bool "$(read_default com.apple.dock show-recents)")
  [ "$result" = "0" ]
}

# ============================================================================
# Finder Tests
# ============================================================================

@test "finder: AppleShowAllFiles = 1 (show hidden files)" {
  result=$(normalize_bool "$(read_default com.apple.finder AppleShowAllFiles)")
  [ "$result" = "1" ]
}

@test "finder: AppleShowAllExtensions = 1" {
  result=$(normalize_bool "$(read_default NSGlobalDomain AppleShowAllExtensions)")
  [ "$result" = "1" ]
}

@test "finder: FXPreferredViewStyle = clmv (column view)" {
  result=$(read_default com.apple.finder FXPreferredViewStyle)
  [ "$result" = "clmv" ]
}

# ============================================================================
# Application Installation Tests
# ============================================================================

@test "app: Raycast is installed" {
  [ -d "/Applications/Raycast.app" ]
}

# ============================================================================
# Config File Tests
# ============================================================================

@test "config: ghostty config exists" {
  [ -f "$HOME/.config/ghostty/config" ]
}

# ============================================================================
# Quick Verification Summary
# ============================================================================

@test "SUMMARY: Multi-finger gestures enabled (native macOS)" {
  # With Swish removed, native gestures should be enabled
  pinch=$(read_default com.apple.AppleMultitouchTrackpad TrackpadFourFingerPinchGesture)
  swipe=$(read_default com.apple.AppleMultitouchTrackpad TrackpadFourFingerVertSwipeGesture)
  [ "$pinch" = "2" ] && [ "$swipe" = "2" ]
}

@test "SUMMARY: F12 key test - fnState should be false (media keys by default)" {
  # Another key acceptance criteria
  result=$(normalize_bool "$(read_default NSGlobalDomain com.apple.keyboard.fnState)")
  [ "$result" = "0" ]
}
