#!/usr/bin/env bash
# Test runner for macOS system settings verification
# Usage: ./tests/run-tests.sh [--verbose] [--tap]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Options
VERBOSE=false
TAP_OUTPUT=false

while [[ $# -gt 0 ]]; do
  case $1 in
    -v|--verbose) VERBOSE=true; shift ;;
    --tap) TAP_OUTPUT=true; shift ;;
    -h|--help)
      echo "Usage: $0 [--verbose] [--tap]"
      echo ""
      echo "Options:"
      echo "  -v, --verbose  Show detailed output"
      echo "  --tap          Output in TAP format"
      exit 0
      ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║         macOS System Settings Test Suite                       ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "Host: $(hostname)"
echo "macOS: $(sw_vers -productVersion) ($(sw_vers -buildVersion))"
echo "Date: $(date)"
echo ""

# Check for bats
if ! command -v bats &> /dev/null; then
  echo -e "${YELLOW}bats not found. Attempting to install via Homebrew...${NC}"
  if command -v brew &> /dev/null; then
    brew install bats-core
  else
    echo -e "${RED}Error: bats not found and Homebrew not available${NC}"
    echo "Install with: brew install bats-core"
    echo "Or via Nix: nix-shell -p bats"
    exit 1
  fi
fi

# Build bats arguments
BATS_ARGS=""
if $VERBOSE; then
  BATS_ARGS="--verbose-run"
fi
if $TAP_OUTPUT; then
  BATS_ARGS="$BATS_ARGS --tap"
fi

echo -e "${BLUE}Running system settings tests...${NC}"
echo ""

# Run tests
if bats $BATS_ARGS "$SCRIPT_DIR/system-settings.bats"; then
  echo ""
  echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${GREEN}                    ALL TESTS PASSED                                ${NC}"
  echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  exit 0
else
  echo ""
  echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${RED}                    SOME TESTS FAILED                                ${NC}"
  echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo "Troubleshooting steps:"
  echo "1. Run: darwin-rebuild switch --flake .#hank-mbp-m4"
  echo "2. LOG OUT and LOG BACK IN (required for trackpad changes)"
  echo "3. Restart affected apps"
  echo ""
  echo "Quick verification:"
  echo "  defaults read com.apple.AppleMultitouchTrackpad TrackpadFourFingerPinchGesture"
  echo "  defaults read NSGlobalDomain com.apple.keyboard.fnState"
  exit 1
fi
