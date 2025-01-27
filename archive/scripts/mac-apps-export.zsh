#!/bin/zsh

# Basic setup

setopt ERR_EXIT
TIMESTAMP=$(date +'%Y%m%d_%H%M%S')
OUTPUT_FILE="${HOME}/Desktop/mac-apps_${TIMESTAMP}.txt"
TEMP_FILE="/tmp/mac-apps_${TIMESTAMP}_temp.txt"

# Colors

BLUE=$'\033[0;34m'
GREEN=$'\033[0;32m'
RESET=$'\033[0m'

# Basic functions

log() {
local timestamp=$(date +'%Y-%m-%d %H:%M:%S')
echo "${timestamp} [$1] $2"
}

progress() {
echo "${BLUE}→${RESET} $1..."
}

cleanup() {
[[ -f $TEMP_FILE ]] && rm -f "$TEMP_FILE"
log "INFO" "Cleanup completed"
}

# Set up cleanup trap

trap cleanup EXIT INT TERM

# Main script

log "INFO" "Starting Mac applications export"

# Create output file

echo "Mac Applications Export - $(date)" > "$OUTPUT_FILE"
echo "================================" >> "$OUTPUT_FILE"

# Collect Homebrew packages

progress "Collecting Homebrew packages"
{
echo "\nHomebrew Packages:"
brew bundle dump --all --file=- 2>/dev/null
} | sort -u >> "$TEMP_FILE"

# Collect Global Brewfile contents

progress "Collecting Global Brewfile contents"
{
echo "\nGlobal Brewfile Contents:"
brew bundle list --global --all 2>/dev/null
} | sort -u >> "$TEMP_FILE"

# Collect System Applications

progress "Collecting System Applications"
{
echo "\nSystem Applications:"
ls -a -1 /Applications | grep ".app$" | sed 's/^//Applications//'
} | sort -u >> "$TEMP_FILE"

# Process results

progress "Processing results"

# Process different categories

echo "\nGUI Applications (Casks):" >> "$OUTPUT_FILE"
grep "^cask" "$TEMP_FILE" | sort -u >> "$OUTPUT_FILE"

echo "\nCLI Applications (Formulae):" >> "$OUTPUT_FILE"
grep "^brew" "$TEMP_FILE" | sort -u >> "$OUTPUT_FILE"

echo "\nMac App Store Applications:" >> "$OUTPUT_FILE"
grep "^mas" "$TEMP_FILE" | sort -u >> "$OUTPUT_FILE"

echo "\nSystem Applications:" >> "$OUTPUT_FILE"

# grep ".app" "$TEMP_FILE" |  sed 's/^//Applications/' | sort -u >> "$OUTPUT_FILE"

grep "/Applications" "$TEMP_FILE" | sort -u >> "$OUTPUT_FILE"

# Add summary

{
echo "\nSummary:"
echo "----------------------------------------"
echo "Total GUI Applications: $(grep -c "^cask" "$TEMP_FILE")"
echo "Total CLI Applications: $(grep -c "^brew" "$TEMP_FILE")"
echo "Total App Store Apps: $(grep -c "^mas" "$TEMP_FILE")"
echo "Total System Applications: $(grep -c "/Applications/" "$TEMP_FILE")"
} >> "$OUTPUT_FILE"

# Final timestamp

echo "\nExport completed at: $(date)" >> "$OUTPUT_FILE"

log "INFO" "Export completed successfully: ${OUTPUT_FILE}"
echo "${GREEN}✓${RESET} Results saved to: ${OUTPUT_FILE}"

# Display preview

echo "----------------------------------------\n"
echo "Apps Summary: $(wc -l $OUTPUT_FILE) \n"
echo "----------------------------------------\n"
echo "Content:\n"
echo "----------------------------------------\n"
cat "$OUTPUT_FILE"
echo "----------------------------------------\n”

