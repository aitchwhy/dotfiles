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
  # Default profile contains the active system + user packages
  if vulnix --system --json > "$VULNIX_OUT" 2>/dev/null; then
    :
  fi

  # Parse JSON output: each entry has "affected_by" CVE list with severity
  if [ -s "$VULNIX_OUT" ]; then
    # Use jq to bucket by severity. vulnix doesn't always carry severity in
    # its JSON; treat any reported CVE as at-least-medium and rely on the NVD
    # CVSS score field if present.
    SUMMARY="$(jq -r '
      def sev(c):
        if c >= 9.0 then "CRITICAL"
        elif c >= 7.0 then "HIGH"
        elif c >= 4.0 then "MEDIUM"
        else "LOW" end;
      .[] | . as $pkg
        | (.affected_by // [])[]
        | "\(sev(.cvssv3 // .cvssv2 // 5.0))\t\($pkg.name // "?")@\($pkg.version // "?")\t\(.cve // "?")"
    ' "$VULNIX_OUT" 2>/dev/null | sort -u)"

    if [ -z "$SUMMARY" ]; then
      emit "✅ No CVEs reported by vulnix."
    else
      emit '```'
      echo "$SUMMARY" >> "$REPORT"
      emit '```'
      while IFS=$'\t' read -r sev pkgver cve; do
        bump "$sev"
      done <<< "$SUMMARY"
    fi
  else
    emit "ℹ️  vulnix produced no JSON output (possibly no CVEs, possibly NVD fetch failure)."
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

    for target in "${SCAN_TARGETS[@]}"; do
      emit "### ${target/$HOME/~}"
      if osv-scanner --format json --recursive "$target" > "$OSV_OUT" 2>/dev/null; then
        :
      fi

      if [ -s "$OSV_OUT" ]; then
        FINDINGS="$(jq -r '
          .results[]?.packages[]? as $p
          | $p.vulnerabilities[]?
          | (
              ($p.package.name // "?") + "@" + ($p.package.version // "?") + " " +
              (.id // "?") + " " +
              ((.database_specific.severity // "UNKNOWN") | ascii_upcase)
            )
        ' "$OSV_OUT" 2>/dev/null | sort -u)"

        if [ -z "$FINDINGS" ]; then
          emit "✅ No vulnerabilities."
        else
          emit '```'
          echo "$FINDINGS" >> "$REPORT"
          emit '```'
          while read -r line; do
            sev="$(echo "$line" | awk '{print $NF}')"
            case "$sev" in
              CRITICAL|HIGH|MEDIUM|LOW) bump "$sev" ;;
              *) bump "MEDIUM" ;;
            esac
          done <<< "$FINDINGS"
        fi
      else
        emit "ℹ️  osv-scanner returned no JSON for this target."
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
