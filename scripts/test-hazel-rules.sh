#!/bin/bash
# Test Hazel Rules One by One
# Creates sample files and verifies rules trigger correctly

set -e

DOWNLOADS="$HOME/Downloads"
DESKTOP="$HOME/Desktop"
GDRIVE_ROOT="/Users/hank/Library/CloudStorage/GoogleDrive-hank.lee.qed@gmail.com/My Drive/My Drive"
BACKUPS="$GDRIVE_ROOT/Backups"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "🧪 Testing Hazel Rules"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Function to create an old file (bypasses 1-hour buffer)
create_old_file() {
    local filepath="$1"
    local hours_old="$2"

    touch "$filepath"

    # Set file modification time to X hours ago
    # Format: YYYYMMDDhhmm
    local old_date=$(date -v-${hours_old}H "+%Y%m%d%H%M")
    touch -t "$old_date" "$filepath"
}

# Test 1: Google Drive .DS_Store Cleanup (Immediate)
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 1: Google Drive .DS_Store Cleanup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Rule: Delete .DS_Store files immediately"
echo "Expected: File deleted within 1-2 minutes"
echo ""

TEST_DS_STORE="$GDRIVE_ROOT/01-Inbox/.DS_Store"
echo "Creating test file: $TEST_DS_STORE"
touch "$TEST_DS_STORE"

if [ -f "$TEST_DS_STORE" ]; then
    echo -e "${GREEN}✓${NC} Test file created"
    echo ""
    echo "⏳ Waiting 2 minutes for Hazel to process..."
    echo "   (Hazel checks every 1-2 minutes)"
    sleep 120

    if [ ! -f "$TEST_DS_STORE" ]; then
        echo -e "${GREEN}✅ Test 1 PASSED${NC} - .DS_Store file was deleted"
    else
        echo -e "${YELLOW}⚠️  Test 1 PENDING${NC} - File still exists, may need more time"
        echo "   Check Hazel logs: tail -f ~/Library/Logs/Hazel/*.log"
    fi
else
    echo -e "${RED}✗${NC} Failed to create test file"
fi

echo ""
read -p "Press Enter to continue to next test..."
echo ""

# Test 2: Downloads Video Import
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 2: Downloads Video Import to Photos"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Rule: Import MP4 videos to Photos.app after 1 hour"
echo "Expected: Video imported to Photos, original file deleted"
echo ""

# Find an existing video to copy, or create a tiny test video
if find ~/Movies -name "*.mp4" -o -name "*.mov" 2>/dev/null | head -1 | grep -q .; then
    SOURCE_VIDEO=$(find ~/Movies -name "*.mp4" -o -name "*.mov" 2>/dev/null | head -1)
    TEST_VIDEO="$DOWNLOADS/hazel-test-video.mp4"

    echo "Copying existing video: $(basename "$SOURCE_VIDEO")"
    cp "$SOURCE_VIDEO" "$TEST_VIDEO"

    # Make it appear 2 hours old (bypasses 1-hour buffer)
    echo "Setting file timestamp to 2 hours ago..."
    create_old_file "$TEST_VIDEO" 2

    if [ -f "$TEST_VIDEO" ]; then
        echo -e "${GREEN}✓${NC} Test video created and backdated"
        echo "Location: $TEST_VIDEO"
        echo ""
        echo "⏳ Waiting 2 minutes for Hazel to process..."
        sleep 120

        if [ ! -f "$TEST_VIDEO" ]; then
            echo -e "${GREEN}✅ Test 2 PASSED${NC} - Video processed (imported and deleted)"
            echo "   Check Photos.app to verify import"
        else
            echo -e "${YELLOW}⚠️  Test 2 PENDING${NC} - Video still in Downloads"
            echo "   File info:"
            ls -lh "$TEST_VIDEO"
            echo "   Check Hazel logs for details"
        fi
    fi
else
    echo "No sample video found in ~/Movies"
    echo "Creating minimal test MP4..."

    # Create a tiny black video using ffmpeg if available
    if command -v ffmpeg &> /dev/null; then
        TEST_VIDEO="$DOWNLOADS/hazel-test-video.mp4"
        ffmpeg -f lavfi -i color=black:s=320x240:d=1 -c:v libx264 -t 1 -pix_fmt yuv420p "$TEST_VIDEO" -y 2>/dev/null

        create_old_file "$TEST_VIDEO" 2

        echo -e "${GREEN}✓${NC} Test video created"
        echo "⏳ Waiting 2 minutes for Hazel to process..."
        sleep 120

        if [ ! -f "$TEST_VIDEO" ]; then
            echo -e "${GREEN}✅ Test 2 PASSED${NC} - Video processed"
        else
            echo -e "${YELLOW}⚠️  Test 2 PENDING${NC} - Video still exists"
        fi
    else
        echo -e "${YELLOW}⚠️  Test 2 SKIPPED${NC} - No sample video available and ffmpeg not installed"
        echo "   To test manually: Copy any .mp4 file to Downloads and wait 1 hour"
    fi
fi

echo ""
read -p "Press Enter to continue to next test..."
echo ""

# Test 3: Downloads Image Import
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 3: Downloads Image Import to Photos"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Rule: Import images to Photos.app after 1 hour"
echo "Expected: Image imported to Photos, original file deleted"
echo ""

TEST_IMAGE="$DOWNLOADS/hazel-test-image.jpg"
echo "Creating test image..."

# Create a simple colored image using ImageMagick or sips
if command -v sips &> /dev/null; then
    # Create a 100x100 red square
    sips -s format jpeg /System/Library/Desktop\ Pictures/Solid\ Colors/Solid\ Aqua\ Dark\ Blue.png --out "$TEST_IMAGE" --resampleWidth 100 2>/dev/null

    create_old_file "$TEST_IMAGE" 2

    if [ -f "$TEST_IMAGE" ]; then
        echo -e "${GREEN}✓${NC} Test image created and backdated"
        echo "Location: $TEST_IMAGE"
        echo ""
        echo "⏳ Waiting 2 minutes for Hazel to process..."
        sleep 120

        if [ ! -f "$TEST_IMAGE" ]; then
            echo -e "${GREEN}✅ Test 3 PASSED${NC} - Image processed (imported and deleted)"
            echo "   Check Photos.app to verify import"
        else
            echo -e "${YELLOW}⚠️  Test 3 PENDING${NC} - Image still in Downloads"
            echo "   Check Hazel logs for details"
        fi
    fi
else
    echo -e "${YELLOW}⚠️  Test 3 SKIPPED${NC} - sips not available"
    echo "   To test manually: Copy any .jpg file to Downloads and wait 1 hour"
fi

echo ""
read -p "Press Enter to continue to next test..."
echo ""

# Test 4: Desktop Screenshot Import
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 4: Desktop Screenshot Import"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Rule: Import screenshots to Photos.app after 1 hour"
echo "Expected: Screenshot imported to Photos, original deleted"
echo ""

TEST_SCREENSHOT="$DESKTOP/Screenshot 2026-02-01 at 10.00.00 AM.png"
echo "Creating test screenshot..."

if command -v sips &> /dev/null; then
    sips -s format png /System/Library/Desktop\ Pictures/Solid\ Colors/Solid\ Aqua\ Dark\ Blue.png --out "$TEST_SCREENSHOT" --resampleWidth 200 2>/dev/null

    create_old_file "$TEST_SCREENSHOT" 2

    if [ -f "$TEST_SCREENSHOT" ]; then
        echo -e "${GREEN}✓${NC} Test screenshot created and backdated"
        echo "Location: $TEST_SCREENSHOT"
        echo ""
        echo "⏳ Waiting 2 minutes for Hazel to process..."
        sleep 120

        if [ ! -f "$TEST_SCREENSHOT" ]; then
            echo -e "${GREEN}✅ Test 4 PASSED${NC} - Screenshot processed"
            echo "   Check Photos.app to verify import"
        else
            echo -e "${YELLOW}⚠️  Test 4 PENDING${NC} - Screenshot still on Desktop"
            echo "   Check Hazel logs for details"
        fi
    fi
else
    echo -e "${YELLOW}⚠️  Test 4 SKIPPED${NC} - sips not available"
fi

echo ""
read -p "Press Enter to continue to next test..."
echo ""

# Test 5: Downloads DMG Cleanup
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 5: Downloads DMG Installer Cleanup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Rule: Delete .dmg files older than 7 days"
echo "Expected: Old DMG files moved to Trash"
echo ""

TEST_DMG="$DOWNLOADS/hazel-test-installer.dmg"
echo "Creating test DMG file..."

# Create empty file with .dmg extension
touch "$TEST_DMG"

# Make it appear 8 days old (bypasses 7-day buffer)
echo "Setting file timestamp to 8 days ago..."
create_old_file "$TEST_DMG" $((8 * 24))

if [ -f "$TEST_DMG" ]; then
    echo -e "${GREEN}✓${NC} Test DMG created and backdated to 8 days ago"
    echo "Location: $TEST_DMG"
    echo ""
    echo "⏳ Waiting 2 minutes for Hazel to process..."
    sleep 120

    if [ ! -f "$TEST_DMG" ]; then
        echo -e "${GREEN}✅ Test 5 PASSED${NC} - DMG file was deleted"
        echo "   Check Trash to verify"
    else
        echo -e "${YELLOW}⚠️  Test 5 PENDING${NC} - DMG still in Downloads"
        ls -lh "$TEST_DMG"
        echo "   Check Hazel logs for details"
    fi
fi

echo ""
read -p "Press Enter to continue to next test..."
echo ""

# Test 6: Backups Orphaned File Cleanup
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 6: Backups Orphaned File Cleanup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Rule: Delete .tmp, .partial, .download files older than 7 days"
echo "Expected: Old temporary files deleted"
echo ""

TEST_TMP="$BACKUPS/test-backup.tmp"
echo "Creating test orphaned file..."

touch "$TEST_TMP"

# Make it appear 8 days old
echo "Setting file timestamp to 8 days ago..."
create_old_file "$TEST_TMP" $((8 * 24))

if [ -f "$TEST_TMP" ]; then
    echo -e "${GREEN}✓${NC} Test orphaned file created and backdated"
    echo "Location: $TEST_TMP"
    echo ""
    echo "⏳ Waiting 2 minutes for Hazel to process..."
    sleep 120

    if [ ! -f "$TEST_TMP" ]; then
        echo -e "${GREEN}✅ Test 6 PASSED${NC} - Orphaned file was deleted"
    else
        echo -e "${YELLOW}⚠️  Test 6 PENDING${NC} - File still exists"
        ls -lh "$TEST_TMP"
        echo "   Check Hazel logs for details"
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎯 All Tests Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Summary:"
echo "- If tests show PASSED: ✅ Rules are working"
echo "- If tests show PENDING: Check Hazel logs"
echo "- Some rules may need longer to process"
echo ""
echo "Hazel logs location:"
echo "  ~/Library/Logs/Hazel/*.log"
echo ""
echo "To view logs:"
echo "  tail -f ~/Library/Logs/Hazel/*.log"
echo ""
