#!/bin/bash

# SSD Backup Verification Script
# Save as: verify_backup.sh
# Usage: ./verify_backup.sh [source] [backup]

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Default paths (modify these)
SOURCE="${1:-/Volumes/Macintosh HD}"
BACKUP="${2:-/Volumes/CCC_Backup}"

# Configuration
SAMPLE_SIZE=100  # Number of random files to checksum
LARGE_FILE_SIZE="100M"  # Files larger than this get special attention
LOG_FILE="$HOME/Desktop/backup_verification_$(date +%Y%m%d_%H%M%S).log"

# Functions
print_status() { echo -e "${GREEN}[✓]${NC} $1" | tee -a "$LOG_FILE"; }
print_error() { echo -e "${RED}[✗]${NC} $1" | tee -a "$LOG_FILE"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1" | tee -a "$LOG_FILE"; }
print_info() { echo -e "${BLUE}[i]${NC} $1" | tee -a "$LOG_FILE"; }
print_header() { 
    echo -e "\n${BLUE}========== $1 ==========${NC}" | tee -a "$LOG_FILE"
}

# Check if running as root for system files
if [ "$EUID" -ne 0 ]; then 
    print_warning "Not running as root. Some system files may not be accessible."
    print_info "For full verification, run: sudo $0"
fi

# Verify drives exist
print_header "Drive Verification"
if [ ! -d "$SOURCE" ]; then
    print_error "Source not found: $SOURCE"
    exit 1
fi

if [ ! -d "$BACKUP" ]; then
    print_error "Backup not found: $BACKUP"
    exit 1
fi

print_status "Source: $SOURCE"
print_status "Backup: $BACKUP"

# Get drive info
print_header "Drive Information"
SOURCE_INFO=$(diskutil info "$SOURCE" 2>/dev/null | grep -E "(Volume Name:|File System:|Capacity:)" || echo "Unable to get info")
BACKUP_INFO=$(diskutil info "$BACKUP" 2>/dev/null | grep -E "(Volume Name:|File System:|Capacity:)" || echo "Unable to get info")

echo "Source Drive:" | tee -a "$LOG_FILE"
echo "$SOURCE_INFO" | tee -a "$LOG_FILE"
echo -e "\nBackup Drive:" | tee -a "$LOG_FILE"
echo "$BACKUP_INFO" | tee -a "$LOG_FILE"

# Compare disk usage
print_header "Size Comparison"
SOURCE_SIZE=$(du -sh "$SOURCE" 2>/dev/null | cut -f1)
BACKUP_SIZE=$(du -sh "$BACKUP" 2>/dev/null | cut -f1)
print_info "Source size: $SOURCE_SIZE"
print_info "Backup size: $BACKUP_SIZE"

# Count files and directories
print_header "File Count Comparison"
print_info "Counting files (this may take a few minutes)..."

SOURCE_FILES=$(find "$SOURCE" -type f 2>/dev/null | wc -l | tr -d ' ')
BACKUP_FILES=$(find "$BACKUP" -type f 2>/dev/null | wc -l | tr -d ' ')
SOURCE_DIRS=$(find "$SOURCE" -type d 2>/dev/null | wc -l | tr -d ' ')
BACKUP_DIRS=$(find "$BACKUP" -type d 2>/dev/null | wc -l | tr -d ' ')

print_info "Source: $SOURCE_FILES files, $SOURCE_DIRS directories"
print_info "Backup: $BACKUP_FILES files, $BACKUP_DIRS directories"

if [ "$SOURCE_FILES" -eq "$BACKUP_FILES" ]; then
    print_status "File count matches"
else
    DIFF=$((SOURCE_FILES - BACKUP_FILES))
    print_warning "File count difference: $DIFF files"
fi

# Quick diff check
print_header "Quick Structure Check"
print_info "Running quick diff (first differences only)..."

DIFF_OUTPUT=$(diff -rq "$SOURCE" "$BACKUP" 2>&1 | head -20 || true)
if [ -z "$DIFF_OUTPUT" ]; then
    print_status "No differences found in quick check"
else
    print_warning "Differences found:"
    echo "$DIFF_OUTPUT" | tee -a "$LOG_FILE"
fi

# Random file checksum verification
print_header "Random Sample Checksum Verification"
print_info "Selecting $SAMPLE_SIZE random files for checksum verification..."

# Create temp files for checksums
TEMP_SOURCE="/tmp/source_checksums_$$"
TEMP_BACKUP="/tmp/backup_checksums_$$"

# Get random files
RANDOM_FILES=$(find "$SOURCE" -type f -not -path "*/.*" 2>/dev/null | \
    grep -v -E "(\.DS_Store|\.Spotlight-V100|\.fseventsd|\.Trashes)" | \
    sort -R | head -n "$SAMPLE_SIZE")

VERIFIED=0
FAILED=0

while IFS= read -r file; do
    REL_PATH="${file#$SOURCE}"
    BACKUP_FILE="$BACKUP$REL_PATH"
    
    if [ -f "$BACKUP_FILE" ]; then
        SOURCE_HASH=$(shasum -a 256 "$file" 2>/dev/null | cut -d' ' -f1)
        BACKUP_HASH=$(shasum -a 256 "$BACKUP_FILE" 2>/dev/null | cut -d' ' -f1)
        
        if [ "$SOURCE_HASH" = "$BACKUP_HASH" ]; then
            ((VERIFIED++))
            echo -n "." # Progress indicator
        else
            ((FAILED++))
            print_error "Checksum mismatch: $REL_PATH"
        fi
    else
        ((FAILED++))
        print_error "Missing in backup: $REL_PATH"
    fi
done <<< "$RANDOM_FILES"

echo # New line after progress dots
print_info "Checksums verified: $VERIFIED/$SAMPLE_SIZE"
if [ $FAILED -gt 0 ]; then
    print_error "Failed verifications: $FAILED"
fi

# Check large files
print_header "Large File Verification"
print_info "Checking files larger than $LARGE_FILE_SIZE..."

LARGE_FILES=$(find "$SOURCE" -type f -size +$LARGE_FILE_SIZE 2>/dev/null | head -10)
while IFS= read -r file; do
    [ -z "$file" ] && continue
    REL_PATH="${file#$SOURCE}"
    BACKUP_FILE="$BACKUP$REL_PATH"
    
    if [ -f "$BACKUP_FILE" ]; then
        SOURCE_SIZE=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null)
        BACKUP_SIZE=$(stat -f%z "$BACKUP_FILE" 2>/dev/null || stat -c%s "$BACKUP_FILE" 2>/dev/null)
        
        if [ "$SOURCE_SIZE" = "$BACKUP_SIZE" ]; then
            print_status "Size match: $(basename "$file") ($SOURCE_SIZE bytes)"
        else
            print_error "Size mismatch: $(basename "$file")"
        fi
    fi
done <<< "$LARGE_FILES"

# Check critical system files (if accessible)
print_header "Critical File Check"
CRITICAL_PATHS=(
    "/System/Library/CoreServices/SystemVersion.plist"
    "/Library/Preferences/SystemConfiguration/com.apple.Boot.plist"
    "/private/var/db/.AppleSetupDone"
)

for path in "${CRITICAL_PATHS[@]}"; do
    if [ -f "$SOURCE$path" ] && [ -f "$BACKUP$path" ]; then
        print_status "Found: $path"
    elif [ -f "$SOURCE$path" ]; then
        print_warning "Missing in backup: $path"
    fi
done

# Test file readability
print_header "File Readability Test"
print_info "Testing random file access..."

TEST_COUNT=0
READ_ERRORS=0

while IFS= read -r file && [ $TEST_COUNT -lt 20 ]; do
    [ -z "$file" ] && continue
    if head -c 1024 "$file" >/dev/null 2>&1; then
        ((TEST_COUNT++))
    else
        ((READ_ERRORS++))
        print_error "Cannot read: $(basename "$file")"
    fi
done <<< "$(find "$BACKUP" -type f 2>/dev/null | sort -R)"

print_info "Successfully read $TEST_COUNT test files"
[ $READ_ERRORS -gt 0 ] && print_error "Read errors: $READ_ERRORS"

# Check for common backup issues
print_header "Common Issues Check"

# Check for .DS_Store files
DS_COUNT=$(find "$BACKUP" -name ".DS_Store" 2>/dev/null | wc -l | tr -d ' ')
print_info ".DS_Store files in backup: $DS_COUNT"

# Check permissions
print_info "Checking permissions preservation..."
PERM_CHECK=$(find "$BACKUP" -type f -perm 000 2>/dev/null | head -5)
if [ -n "$PERM_CHECK" ]; then
    print_warning "Found files with no permissions:"
    echo "$PERM_CHECK" | tee -a "$LOG_FILE"
fi

# Extended attributes check (macOS specific)
print_header "Extended Attributes Check"
XATTR_SOURCE=$(find "$SOURCE" -type f -xattrname "com.apple.FinderInfo" 2>/dev/null | wc -l | tr -d ' ')
XATTR_BACKUP=$(find "$BACKUP" -type f -xattrname "com.apple.FinderInfo" 2>/dev/null | wc -l | tr -d ' ')
print_info "Files with extended attributes - Source: $XATTR_SOURCE, Backup: $XATTR_BACKUP"

# Final summary
print_header "VERIFICATION SUMMARY"
echo "===========================================" | tee -a "$LOG_FILE"
echo "Source: $SOURCE" | tee -a "$LOG_FILE"
echo "Backup: $BACKUP" | tee -a "$LOG_FILE"
echo "Files verified: $VERIFIED/$SAMPLE_SIZE" | tee -a "$LOG_FILE"
echo "Verification failures: $FAILED" | tee -a "$LOG_FILE"
echo "Read errors: $READ_ERRORS" | tee -a "$LOG_FILE"
echo "Log saved to: $LOG_FILE" | tee -a "$LOG_FILE"
echo "===========================================" | tee -a "$LOG_FILE"

if [ $FAILED -eq 0 ] && [ $READ_ERRORS -eq 0 ]; then
    print_status "BACKUP VERIFICATION PASSED"
    exit 0
else
    print_error "BACKUP VERIFICATION FAILED"
    exit 1
fi
