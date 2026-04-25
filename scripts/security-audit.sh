#!/usr/bin/env bash
# Security audit run as part of `just switch`, `just check`, and `just audit`.
#
# Scans:
#   1. Nix system closure  → vulnix (NVD)
#   2. ~/src/told lockfiles → osv-scanner (OSV.dev)
#   3. dotfiles lockfiles   → osv-scanner (OSV.dev)
#   4. Homebrew installs    → `brew outdated --greedy`
#
# Severity gating:
#   CRITICAL or HIGH  → exit 1 (fails the calling lifecycle event)
#   MEDIUM / LOW      → printed but does not fail
#
# Flags:
#   --fast        skip osv-scanner (used by `just check` for tighter inner loop)
#   --report PATH override report path (default ~/dotfiles/audit-reports/<date>.md)
#   --no-gate     never fail; warn only (used for advisory contexts)

set -uo pipefail

REPORT_DIR="$HOME/dotfiles/audit-reports"
REPORT="$REPORT_DIR/$(date -u +%Y-%m-%d).md"
FAST=0
GATE=1

while [ $# -gt 0 ]; do
  case "$1" in
    --fast) FAST=1; shift ;;
    --no-gate) GATE=0; shift ;;
    --report) REPORT="$2"; shift 2 ;;
    *) echo "Unknown flag: $1" >&2; exit 2 ;;
  esac
done

mkdir -p "$REPORT_DIR"

# Tally counters in a tmp file so subshells share state
TALLY="$(mktemp -t audit-tally.XXXXXX)"
echo "0 0 0 0" > "$TALLY"  # critical high medium low
trap 'rm -f "$TALLY"' EXIT

bump() {
  read -r c h m l < "$TALLY"
  case "$1" in
    CRITICAL) c=$((c+1)) ;;
    HIGH) h=$((h+1)) ;;
    MEDIUM) m=$((m+1)) ;;
    LOW) l=$((l+1)) ;;
  esac
  echo "$c $h $m $l" > "$TALLY"
}

emit() { printf '%s\n' "$@" >> "$REPORT"; }
section() { emit "" "## $1" ""; }

cat > "$REPORT" <<EOF
# Security audit — $(date -u +%Y-%m-%dT%H:%M:%SZ)

Trigger: \`$(basename "${0}")\` ($([ "$FAST" = 1 ] && echo "fast" || echo "full"))
Host: $(hostname -s)

EOF

# ─────────────────────────────────────────────────────────────────────────────
# 1. vulnix — system closure
# ─────────────────────────────────────────────────────────────────────────────
section "1. Nix system closure (vulnix)"

VULNIX_OUT="$(mktemp -t vulnix.XXXXXX)"
trap 'rm -f "$TALLY" "$VULNIX_OUT"' EXIT

if command -v vulnix >/dev/null 2>&1; then
  # Vulnix exits 0 when no CVEs, 2 when CVEs are found, 1 on error.
  # JSON output is on stdout regardless.
  WHITELIST_FLAG=()
  if [ -f "$HOME/dotfiles/config/security/vulnix-whitelist.toml" ]; then
    WHITELIST_FLAG=(-w "$HOME/dotfiles/config/security/vulnix-whitelist.toml")
  fi

  vulnix --system --json "${WHITELIST_FLAG[@]}" > "$VULNIX_OUT" 2>/dev/null
  VULNIX_EXIT=$?

  # vulnix JSON shape: array of {name, pname, version, affected_by: [CVE...],
  # whitelisted: [CVE...], cvssv3_basescore: {CVE: score}, description: {CVE: str}}
  if [ -s "$VULNIX_OUT" ] && jq -e 'length > 0' "$VULNIX_OUT" >/dev/null 2>&1; then
    SUMMARY="$(jq -r '
      def sev(c):
        if c >= 9.0 then "CRITICAL"
        elif c >= 7.0 then "HIGH"
        elif c >= 4.0 then "MEDIUM"
        else "LOW" end;
      .[]
      | . as $pkg
      | (.affected_by // [])[] as $cve
      | select(($pkg.whitelisted // []) | index($cve) | not)
      | ($pkg.cvssv3_basescore[$cve] // 5.0) as $score
      | "\(sev($score))\t\($score)\t\($pkg.pname // $pkg.name)@\($pkg.version)\t\($cve)"
    ' "$VULNIX_OUT" 2>/dev/null | sort -u)"

    if [ -z "$SUMMARY" ]; then
      emit "✅ No CVEs (after whitelist) reported by vulnix."
    else
      emit "| Severity | CVSS | Package | CVE |"
      emit "|---|---|---|---|"
      while IFS=$'\t' read -r sev score pkgver cve; do
        emit "| $sev | $score | $pkgver | $cve |"
        bump "$sev"
      done <<< "$SUMMARY"
    fi
  elif [ "$VULNIX_EXIT" -eq 0 ]; then
    emit "✅ vulnix: no CVEs."
  else
    emit "ℹ️  vulnix exited $VULNIX_EXIT with no parseable JSON (possibly NVD fetch failure on first run)."
  fi
else
  emit "⚠️  \`vulnix\` not on PATH — install via Nix (\`pkgs.vulnix\`)."
fi

# ─────────────────────────────────────────────────────────────────────────────
# 2. osv-scanner — Told + dotfiles (skipped in --fast)
# ─────────────────────────────────────────────────────────────────────────────
if [ "$FAST" = 0 ]; then
  section "2. Application dependencies (osv-scanner)"

  if ! command -v osv-scanner >/dev/null 2>&1; then
    emit "⚠️  \`osv-scanner\` not on PATH — install via Nix (\`pkgs.osv-scanner\`)."
  else
    OSV_OUT="$(mktemp -t osv.XXXXXX)"

    SCAN_TARGETS=()
    [ -d "$HOME/src/told" ] && SCAN_TARGETS+=("$HOME/src/told")
    SCAN_TARGETS+=("$HOME/dotfiles")

    OSV_CONFIG_FLAG=()
    if [ -f "$HOME/dotfiles/config/security/osv-scanner.toml" ]; then
      OSV_CONFIG_FLAG=(--config "$HOME/dotfiles/config/security/osv-scanner.toml")
    fi

    for target in "${SCAN_TARGETS[@]}"; do
      emit "### ${target/$HOME/~}"
      # osv-scanner v2: `scan source [path]`. Exits 1 when vulns found, 0 clean.
      osv-scanner scan source --format json "${OSV_CONFIG_FLAG[@]}" "$target" > "$OSV_OUT" 2>/dev/null
      OSV_EXIT=$?

      if [ -s "$OSV_OUT" ] && jq -e '.results | length > 0' "$OSV_OUT" >/dev/null 2>&1; then
        # Use groups[].max_severity (CVSS score) for accurate bucketing.
        FINDINGS="$(jq -r '
          def sev(c):
            if c >= 9.0 then "CRITICAL"
            elif c >= 7.0 then "HIGH"
            elif c >= 4.0 then "MEDIUM"
            else "LOW" end;
          .results[]?.packages[]?
          | . as $p
          | (.groups // [])[]
          | (.max_severity // "0" | tonumber? // 0) as $score
          | "\(sev($score))\t\($score)\t\($p.package.name)@\($p.package.version)\t\(.aliases | join(","))"
        ' "$OSV_OUT" 2>/dev/null | sort -u)"

        if [ -z "$FINDINGS" ]; then
          emit "✅ No vulnerabilities."
        else
          emit "| Severity | CVSS | Package | Aliases |"
          emit "|---|---|---|---|"
          while IFS=$'\t' read -r sev score pkgver aliases; do
            emit "| $sev | $score | $pkgver | $aliases |"
            bump "$sev"
          done <<< "$FINDINGS"
        fi
      elif [ "$OSV_EXIT" -eq 0 ]; then
        emit "✅ No vulnerabilities."
      else
        emit "ℹ️  osv-scanner exited $OSV_EXIT with no parseable findings."
      fi
    done

    rm -f "$OSV_OUT"
  fi
fi

# ─────────────────────────────────────────────────────────────────────────────
# 3. Homebrew outdated (advisory only — not severity-gated)
# ─────────────────────────────────────────────────────────────────────────────
section "3. Homebrew freshness"

if command -v brew >/dev/null 2>&1; then
  STALE="$(brew outdated --greedy --quiet 2>/dev/null)"
  if [ -z "$STALE" ]; then
    emit "✅ All Homebrew formulae and casks current."
  else
    emit "Stale Homebrew packages (no severity assigned — review and \`just switch\` to upgrade):"
    emit '```'
    echo "$STALE" >> "$REPORT"
    emit '```'
  fi
else
  emit "ℹ️  Homebrew not on PATH — skipping freshness check."
fi

# ─────────────────────────────────────────────────────────────────────────────
# Summary + gating
# ─────────────────────────────────────────────────────────────────────────────
read -r CRIT HIGH MED LOW < "$TALLY"

section "Summary"
emit "| Severity | Count |"
emit "|---|---|"
emit "| CRITICAL | $CRIT |"
emit "| HIGH | $HIGH |"
emit "| MEDIUM | $MED |"
emit "| LOW | $LOW |"
emit ""

printf '\n'
printf 'Security audit: %d CRITICAL · %d HIGH · %d MEDIUM · %d LOW\n' "$CRIT" "$HIGH" "$MED" "$LOW"
printf 'Report: %s\n' "$REPORT"

if [ "$GATE" = 1 ] && { [ "$CRIT" -gt 0 ] || [ "$HIGH" -gt 0 ]; }; then
  printf '\n❌ FAIL: %d CRITICAL + %d HIGH advisory(ies). See report.\n' "$CRIT" "$HIGH" >&2
  printf '   Override with: just audit-no-gate (advisory) or fix the advisories.\n' >&2
  exit 1
fi

printf '✓ Audit passed (or warn-only mode).\n'
