# Hazel Setup Guide - February 2026 SOTA Configuration

## Overview
This guide will help you set up ultra-aggressive auto-organization using Hazel with 2026 best practices.

**Rule Sets Created:**
1. `desktop-2026-aggressive.hazelrules` - 12 rules for Desktop
2. `downloads-2026-aggressive.hazelrules` - 10 rules for Downloads
3. `google-drive-2026-maintenance.hazelrules` - 8 rules for Google Drive
4. `backups-2026-rotation.hazelrules` - 6 rules for Backups

**Total: 36 aggressive automation rules**

## Prerequisites
1. Hazel app installed (https://www.noodlesoft.com/hazel/)
2. Google Drive desktop app installed and syncing
3. Automation scripts in place:
   - `~/dotfiles/scripts/rotate-backups.sh`
   - `~/dotfiles/scripts/check-duplicate-backups.sh`

## Installation Steps

### Step 1: Open Hazel Preferences
```bash
open -a Hazel
```
Or: System Settings → Hazel

### Step 2: Add Monitored Folders

Add these folders to Hazel monitoring:

**Desktop** (Critical - highest priority)
- Path: `~/Desktop`
- Match subfolders: NO (only monitor root)
- Run rules: Continuously

**Downloads** (High priority)
- Path: `~/Downloads`
- Match subfolders: NO
- Run rules: Continuously

**Google Drive Root** (Medium priority)
- Path: `~/Library/CloudStorage/GoogleDrive-hank.lee.qed@gmail.com/My Drive/My Drive/`
- Match subfolders: YES (depth: 2 levels)
- Run rules: Every 6 hours

**Backups Folder** (Low priority)
- Path: `~/Library/CloudStorage/GoogleDrive-hank.lee.qed@gmail.com/My Drive/My Drive/Backups/`
- Match subfolders: YES
- Run rules: Daily at 3:00 AM

### Step 3: Import Rules (Manual Process)

Hazel doesn't support direct .hazelrules import, so you'll need to recreate each rule manually:

#### For Desktop Rules:
1. Click Desktop folder in Hazel
2. Click "+" to add new rule
3. Copy rule details from `desktop-2026-aggressive.hazelrules`
4. Set up conditions and actions for each rule
5. Enable the rule
6. Repeat for all 12 rules

#### Quick Setup - Priority Rules (Start with these 5):

**Rule 1: Screenshots**
```
If: Name contains "Screenshot" AND Kind is Image
Then: Import to Photos → Move to Trash
```

**Rule 2: Large Files >500MB**
```
If: Size > 500 MB AND Age < 7 days
Then: Move to Google Drive/Archive/Large-Archives/
```

**Rule 3: Old Files (30+ days)**
```
If: Date Last Modified > 30 days ago AND not in workspace folders
Then: Move to Google Drive/Archive/2025/Personal/Desktop-Archive/
```

**Rule 4: PDFs - Smart Routing**
```
If: Extension is PDF AND Age > 2 days
Then: If name contains "invoice|receipt" → Receipts folder
      Else if contains "immigration|visa" → Immigration folder
      Else → Documents folder
```

**Rule 5: DMG Cleanup**
```
If: Extension is DMG AND Age > 7 days
Then: Move to Trash
```

### Step 4: Configure Rule Settings

For each rule, configure:
- **Notification**: Display notification for major moves
- **Tags**: Add consistent tags for searchability
- **Logging**: Enable logging for troubleshooting
- **Run timing**: Continuous for Desktop/Downloads, Scheduled for others

### Step 5: Test Rules

Test each rule before enabling:
1. Create a test file matching rule conditions
2. Wait for Hazel to process (or manually run)
3. Verify file moved to correct location
4. Check tags were applied
5. Confirm notification displayed

### Step 6: Enable Advanced Features

**Color-coded folders:**
- Desktop workspace folders: Blue
- Active work folders: Orange
- Archive folders: Gray
- Temp folders: Yellow

**Hazel Preferences:**
- Enable "Move files to Trash automatically"
- Enable "Empty Trash after X days": 30 days
- Enable "Monitor network volumes": YES (for Google Drive)
- Log level: Info (for troubleshooting)

## Monitoring & Maintenance

### Weekly Health Check
```bash
# Check Hazel logs
tail -100 ~/.hazel/logs/*.log

# Verify automation stats
open -a Hazel
# → Info → Show Activity
```

### Monthly Review
- Review Hazel activity statistics
- Check Archive folders for misclassified items
- Adjust rules based on usage patterns
- Clean up any false positives

### Performance Optimization
- If Hazel uses >10% CPU: Reduce monitoring frequency
- If files not processing: Check rule conflicts
- If wrong moves: Refine rule conditions

## 2026 Best Practices Implemented

✅ **Zero Desktop Philosophy**: Nothing stays longer than needed
✅ **Lifecycle-based Management**: Different retention by file type
✅ **Context-aware Routing**: Smart categorization by filename patterns
✅ **AI-ready Metadata**: Consistent tagging for future AI tools
✅ **Cloud-first Architecture**: Everything backed up to Google Drive
✅ **Aggressive Timelines**: 7-30 day cleanup cycles
✅ **Smart Deduplication**: Automatic duplicate detection
✅ **Size-based Actions**: Large files handled differently
✅ **Media Intelligence**: Photos, videos, documents routed appropriately
✅ **Backup Rotation**: Automated with 5-90-180 day retention

## Troubleshooting

### Rules not triggering
1. Check Hazel is running: `ps aux | grep Hazel`
2. Verify folder monitoring: Hazel Preferences → Folders
3. Check rule conditions match exactly
4. Review Hazel logs for errors

### Files going to wrong location
1. Check rule order (Hazel runs top-to-bottom)
2. Verify conditions are specific enough
3. Use "Show matching files" to test
4. Add more specific conditions

### Performance issues
1. Reduce monitoring frequency for large folders
2. Disable "Match subfolders" where not needed
3. Use scheduled runs instead of continuous
4. Exclude large media libraries

## Advanced: Automation Scripts

The rules use these scripts:

```bash
# Backup rotation (runs daily)
~/dotfiles/scripts/rotate-backups.sh

# Duplicate backup cleanup (runs on-demand)
~/dotfiles/scripts/check-duplicate-backups.sh

# Health monitoring (run weekly)
~/dotfiles/scripts/gdrive-health-check.sh
```

## Success Metrics

After setup, you should see:
- **Desktop**: <10 items at all times
- **Downloads**: <500 MB, <20 files
- **Google Drive Root**: <50 items
- **Backups**: Auto-rotated, <50 GB total
- **Manual intervention**: <5 minutes/week

## Next Steps

1. Import rules into Hazel (30-60 minutes)
2. Test each rule with sample files (30 minutes)
3. Monitor for 1 week, adjust as needed
4. Review monthly statistics
5. Refine rules based on usage patterns

---

**Created**: January 31, 2026
**Last Updated**: February 1, 2026
**Version**: 1.0 - February 2026 SOTA Edition
