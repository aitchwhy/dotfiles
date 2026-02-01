# Hazel Rules Import Instructions
**Date:** 2026-02-01
**Time Required:** ~10 minutes

---

## Quick Start Checklist

- [ ] Open Hazel.app
- [ ] Import Desktop rules
- [ ] Import Downloads rules
- [ ] Import Google Drive rules
- [ ] Import Backups rules
- [ ] Verify all rules are enabled
- [ ] Test with sample file

---

## Detailed Step-by-Step Instructions

### Step 1: Open Hazel

**Option A - Spotlight:**
1. Press `Cmd + Space`
2. Type "Hazel"
3. Press Enter

**Option B - Applications:**
1. Open Finder
2. Go to Applications folder
3. Double-click Hazel.app

**Option C - System Settings:**
1. Open System Settings
2. Look for Hazel in the sidebar (if installed as preference pane)

---

### Step 2: Import Desktop Rules

1. In Hazel, click **"Folders"** in the left sidebar
2. Find or add **~/Desktop** to the folder list
   - If not present: Click **"+"** → Navigate to Desktop → Select
3. Click on **Desktop** in the folder list
4. In the right panel, click the **gear icon** (⚙️) or **"Import Rules"** button
5. Navigate to: `~/dotfiles/config/hazel/`
6. Select: **`desktop-lifecycle.hazelrules`**
7. Click **"Import"**

**Verify:** You should see 5 new rules:
- ✓ Auto-organize screenshots
- ✓ Move day-old files to review
- ✓ Move week-old files to Google Drive
- ✓ Large files to cold storage
- ✓ Remove old installers

8. Check the box next to each rule to **enable** it

---

### Step 3: Import Downloads Rules

1. In Hazel, find or add **~/Downloads** to the folder list
2. Click on **Downloads**
3. Click **"Import Rules"**
4. Select: **`downloads-lifecycle.hazelrules`**
5. Click **"Import"**

**Verify:** You should see 5 new rules:
- ✓ Categorize PDFs
- ✓ Organize images
- ✓ Archive old downloads
- ✓ Clean installers (DMG)
- ✓ Clean installers (ZIP)

6. Enable all rules

---

### Step 4: Import Google Drive Rules

1. In Hazel, find or add:
   `/Users/hank/Library/CloudStorage/GoogleDrive-hank.lee.qed@gmail.com/My Drive/My Drive`

   **Note:** You may need to:
   - Click **"+"** to add a new folder
   - Press `Cmd + Shift + G` in the file picker
   - Paste the full path above
   - Click **"Go"** and **"Select"**

2. Click on **My Drive** in the folder list

3. **IMPORTANT:** Check the box **"Include subfolders"**
   - This is critical for lifecycle rules to work across all folders

4. Click **"Import Rules"**

5. Select: **`gdrive-lifecycle.hazelrules`**

6. Click **"Import"**

**Verify:** You should see 6 new rules:
- ✓ Flag inbox items older than 3 days
- ✓ Move month-old active files to recent
- ✓ Move quarter-old files to archive
- ✓ Move year-old files to cold storage
- ✓ Remove .DS_Store files
- ✓ Organize root files

7. Enable all rules

---

### Step 5: Import Backups Rules

1. In Hazel, find or add:
   `/Users/hank/Library/CloudStorage/GoogleDrive-hank.lee.qed@gmail.com/My Drive/My Drive/Backups`

2. Click on **Backups**

3. Check **"Include subfolders"**

4. Click **"Import Rules"**

5. Select: **`backups-lifecycle.hazelrules`**

6. Click **"Import"**

**Verify:** You should see 4 new rules:
- ✓ Rotate Anthropic backups
- ✓ Archive old backups
- ✓ Delete ancient backups
- ✓ Orphaned backup cleanup

7. Enable all rules

---

## Step 6: Verify Rules Are Active

1. In Hazel, click each folder in the left sidebar
2. Verify you see rules in the right panel
3. Ensure each rule has a **checkmark** (enabled)
4. Look for the rule count in the folder list:
   - Desktop (5)
   - Downloads (5)
   - My Drive (6)
   - Backups (4)

**Total rules:** 20 lifecycle automation rules

---

## Step 7: Test the System

### Test Desktop Rule:
1. Create a test file: `touch ~/Desktop/test-old-file.txt`
2. Change its creation date: `touch -t 202601010000 ~/Desktop/test-old-file.txt`
3. Wait 1-2 minutes for Hazel to process
4. Check: File should move to `~/Desktop/03-Review/`

### Test Google Drive Rule:
1. Create a test file in root: `touch "/Users/hank/Library/CloudStorage/GoogleDrive-hank.lee.qed@gmail.com/My Drive/My Drive/test-root-file.txt"`
2. Change its date: `touch -t 202501010000 "/path/to/test-root-file.txt"`
3. Wait 1-2 minutes
4. Check: File should move to `01-Inbox/` with tag "from-root"

---

## Troubleshooting

### "Hazel.app" not found
**Solution:** Install Hazel from https://www.noodlesoft.com/

### Rules not working
**Possible causes:**
1. Rules not enabled (no checkmark)
2. "Include subfolders" not checked for Google Drive
3. Hazel not running in background
4. File doesn't meet rule conditions (check age/size/name)

**Check Hazel logs:**
```bash
tail -f ~/Library/Logs/Hazel/*.log
```

### Google Drive folder not accessible
**Solution:**
1. Ensure Google Drive is syncing
2. Check: System Settings → Google Drive
3. Make lifecycle folders "Available Offline"

### Rules conflicting with old rules
**Solution:**
1. Review existing rules in each folder
2. Disable or delete old rules that might conflict
3. The new lifecycle rules are comprehensive and replace older rules

---

## After Import: Monitor for 1 Week

### Daily (First 3 Days):
- Check `~/Desktop/03-Review/` - files should appear after 24h
- Check Hazel notifications for any actions taken
- Verify no unexpected file movements

### After 7 Days:
- Check `Google Drive/02-Active/` - files should move from Desktop
- Verify lifecycle transitions are working
- Check `01-Inbox/` for any flagged items

### After 30 Days:
- Check `03-Recent/` - files from Active should appear
- Verify automation is working smoothly
- Adjust timing if needed

---

## Rule File Locations

All rules stored in version control:
```
~/dotfiles/config/hazel/desktop-lifecycle.hazelrules
~/dotfiles/config/hazel/downloads-lifecycle.hazelrules
~/dotfiles/config/hazel/gdrive-lifecycle.hazelrules
~/dotfiles/config/hazel/backups-lifecycle.hazelrules
```

**Note:** If you modify rules in Hazel, export them back to these locations to keep them in sync with your dotfiles.

---

## Quick Reference: Lifecycle Timelines

```
Desktop/01-Today → Desktop/03-Review                    (24 hours)
Desktop/03-Review → Google Drive/02-Active              (7 days)
Google Drive/02-Active → 03-Recent                      (30 days inactive)
Google Drive/03-Recent → 04-Archive                     (90 days inactive)
Google Drive/04-Archive → 05-ColdStorage                (1 year inactive)
```

---

## Need Help?

- Full documentation: `~/.claude/plans/folder-organization-system.md`
- Implementation summary: `~/.claude/plans/implementation-summary-2026-02-01.md`
- Hazel logs: `~/Library/Logs/Hazel/`
- Hazel support: https://www.noodlesoft.com/support/

---

**Import Status:** ⏳ Pending (complete this checklist above)

Once complete, update this file or delete it from Desktop.
