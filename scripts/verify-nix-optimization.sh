#!/usr/bin/env bash
# verify-nix-optimization.sh
# Uses modern CLI tools: rg (ripgrep)
set -euo pipefail

echo "==============================================================="
echo "  Nix Build Optimization Verification"
echo "==============================================================="

ERRORS=0
WARNINGS=0

# Check 1: Derivation splitting (using rg instead of grep)
echo ""
echo "Checking derivation splitting..."

if rg "bun install" flake.nix flake/*.nix 2>/dev/null | rg -v "nodeModules|node-modules" | rg -q .; then
  echo "  FAIL: bun install found outside nodeModules derivation"
  ERRORS=$((ERRORS + 1))
else
  echo "  PASS: bun install properly isolated"
fi

# Check 2: nixpkgs pin (using rg instead of grep)
echo ""
echo "Checking nixpkgs pin..."

if rg -q "nixos-unstable" flake.nix; then
  echo "  WARN: Using nixos-unstable (slower eval)"
  WARNINGS=$((WARNINGS + 1))
else
  echo "  PASS: nixpkgs pinned to stable"
fi

# Check 3: CI configuration (using rg instead of grep)
echo ""
echo "Checking CI configuration..."

if [ -d ".github/workflows" ]; then
  if rg -l "nix-installer-action" .github/workflows/*.yml 2>/dev/null | xargs rg -q "magic-nix-cache" 2>/dev/null; then
    echo "  PASS: magic-nix-cache configured"
  else
    echo "  FAIL: magic-nix-cache missing in CI"
    ERRORS=$((ERRORS + 1))
  fi

  if rg -l "nix-installer-action" .github/workflows/*.yml 2>/dev/null | xargs rg -q "cachix" 2>/dev/null; then
    echo "  PASS: Cachix configured"
  else
    echo "  WARN: Cachix not configured"
    WARNINGS=$((WARNINGS + 1))
  fi
else
  echo "  SKIP: No .github/workflows directory"
fi

# Check 4: nix2container layers (using rg instead of grep)
echo ""
echo "Checking nix2container configuration..."

if rg -q "buildImage" flake.nix flake/*.nix 2>/dev/null; then
  if rg -A20 "buildImage" flake.nix flake/*.nix 2>/dev/null | rg -q "layers"; then
    echo "  PASS: nix2container has layer separation"
  else
    echo "  WARN: nix2container missing layer separation"
    WARNINGS=$((WARNINGS + 1))
  fi
else
  echo "  SKIP: No nix2container images found"
fi

# Summary
echo ""
echo "==============================================================="
if [ $ERRORS -eq 0 ]; then
  if [ $WARNINGS -eq 0 ]; then
    echo "  All checks passed"
  else
    echo "  Passed with $WARNINGS warning(s)"
  fi
  exit 0
else
  echo "  $ERRORS error(s), $WARNINGS warning(s)"
  exit 1
fi
