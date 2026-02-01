# Hazel Automated Setup Guide
**Status:** File-Based Configuration with Sync Rules
**Date:** 2026-02-01

---

## ✅ **Best Approach: Hazel's Built-in Sync Rules**

Hazel supports **file-based configuration** through its [Sync Rules](https://www.noodlesoft.com/manual/hazel/work-with-folders-rules/manage-rules/sync-rules/) feature.

**How it works:**
1. You configure Hazel to sync rules from external `.hazelrules` files (stored in dotfiles)
2. When those files change (via git pull, edits, etc.), Hazel **automatically updates**
3. No manual import needed after initial setup

---

## Initial Setup (One-Time, ~5 Minutes)

### Step 1: Open Hazel Preferences

```bash
# Hazel runs as a System Settings pane
open -a "System Settings"

# Navigate to: Hazel (in sidebar)
```

**Or:**
```bash
# If Hazel is installed as standalone app
open -a "Hazel"
```

### Step 2: Add Folders to Monitor

Click **"+"** to add each folder:

1. **Desktop**
   - Path: `/Users/hank/Desktop`
   - ☐ Include subfolders: No

2. **Downloads**
   - Path: `/Users/hank/Downloads`
   - ☐ Include subfolders: No

3. **Google Drive - My Drive**
   - Path: `/Users/hank/Library/CloudStorage/GoogleDrive-hank.lee.qed@gmail.com/My Drive/My Drive`
   - ☑ Include subfolders: **Yes** (critical!)

4. **Backups**
   - Path: `/Users/hank/Library/CloudStorage/GoogleDrive-hank.lee.qed@gmail.com/My Drive/My Drive/Backups`
   - ☑ Include subfolders: **Yes** (critical!)

### Step 3: Enable Sync Rules (Per Folder)

For **each folder** added above:

1. Select the folder in Hazel's sidebar
2. Click the **gear icon** (⚙️) in the rules section
3. Select **"Sync Rules..."**
4. Click **"Choose..."** and select the corresponding file:

| Folder | Sync Rules File |
|--------|----------------|
| Desktop | `~/dotfiles/config/hazel/rules/desktop-critical.hazelrules` |
| Downloads | `~/dotfiles/config/hazel/rules/downloads-critical.hazelrules` |
| My Drive | `~/dotfiles/config/hazel/rules/gdrive-critical.hazelrules` |
| Backups | `~/dotfiles/config/hazel/rules/backups-critical.hazelrules` |

5. Click **"OK"**

**Result:** Hazel will now automatically sync rules from these files!

---

## ✨ **After Setup: Fully Automated**

Once configured, any changes to rule files in `~/dotfiles/config/hazel/rules/` will **automatically sync to Hazel**.

**Example workflow:**
```bash
# 1. Edit rules
vim ~/dotfiles/config/hazel/rules/downloads-critical.hazelrules

# 2. Commit changes
cd ~/dotfiles
git add config/hazel/rules/downloads-critical.hazelrules
git commit -m "feat(hazel): add new download rule"

# 3. Hazel automatically detects the change and updates!
# No manual import needed ✨
```

---

## Alternative: Direct Import (If Sync Not Working)

If Sync Rules isn't working for any reason, you can import rules manually:

```bash
# 1. In Hazel, select the folder
# 2. Click gear icon (⚙️) → "Import Rules..."
# 3. Select the .hazelrules file
# 4. Click "Import"
```

---

## Verification

### Check if Hazel is Running
```bash
ps aux | grep -i "Hazel" | grep -v grep
```

### Check Synced Rules
1. Open Hazel preferences
2. Select each folder
3. Verify rules appear in the list
4. Each rule should show as "enabled" (checkbox checked)

### Test a Rule
```bash
# Test Downloads video import rule
cp ~/dotfiles/config/hazel/rules/test-video.mp4 ~/Downloads/test-video.mp4

# Wait 1-2 minutes, then check:
# - Video should import to Photos.app
# - Original file should be in Trash
```

---

## Rule Files Location

All rules maintained in version control:

```
~/dotfiles/config/hazel/
├── rules/                              # Active rules (synced to Hazel)
│   ├── desktop-critical.hazelrules    # 1 rule: Screenshot import
│   ├── downloads-critical.hazelrules  # 3 rules: Video/image import, DMG cleanup
│   ├── gdrive-critical.hazelrules     # 1 rule: .DS_Store cleanup
│   └── backups-critical.hazelrules    # 1 rule: Orphaned file cleanup
│
├── archive/                            # Future rules (not active)
│   ├── desktop-lifecycle.hazelrules   # Full 5-rule set
│   ├── downloads-lifecycle.hazelrules # Full 5-rule set
│   ├── gdrive-lifecycle.hazelrules    # Full 6-rule set
│   └── backups-lifecycle.hazelrules   # Full 4-rule set
│
└── docs/                               # Documentation
    ├── AUTOMATED-SETUP-GUIDE.md       # This file
    ├── README.md                       # System overview
    └── IMPLEMENTATION-AUDIT-2026-02-01.md  # Complete audit log
```

---

## Troubleshooting

### "Sync Rules" option is grayed out
- Make sure you've selected a folder in the sidebar first
- Ensure the rules pane is showing (not the "Info" tab)

### Rules aren't updating automatically
1. Check sync is enabled: Gear icon (⚙️) → "Sync Rules..."
2. Verify file path is correct
3. Try re-enabling sync:
   - Disable sync
   - Re-enable and re-select the file

### Hazel not appearing in System Settings
- Hazel 6.0+ installs as a System Settings pane
- Look in: System Settings → Hazel (in sidebar under "Productivity")
- If not there, try: `open -a "Hazel"`

### Rules not triggering
1. Check Hazel is running: `ps aux | grep Hazel`
2. Verify rule conditions match your files
3. Check Hazel logs: Hazel preferences → "Info" tab → "Show Log"

---

## Benefits of This Approach

✅ **Version Controlled**
- All rules in git
- Track changes over time
- Easy rollback if needed

✅ **Automated Updates**
- Edit rules in dotfiles
- Hazel automatically syncs
- No manual import required

✅ **Portable**
- Clone dotfiles on new Mac
- Set up sync once
- All rules automatically loaded

✅ **Documented**
- Rules are readable text files
- Comments explain each rule
- Easy to review and modify

---

## Next Steps

1. ✅ Folders created and rules written
2. ⏳ **DO THIS NOW:** Open Hazel and set up Sync Rules (5 minutes)
3. ✅ Test rules with sample files
4. ✅ Monitor for first few days
5. ✅ Add more rules from `archive/` as needed

---

## References

- [Hazel Sync Rules Documentation](https://www.noodlesoft.com/manual/hazel/work-with-folders-rules/manage-rules/sync-rules/)
- [Hazel Import Rules](https://www.noodlesoft.com/manual/hazel/work-with-folders-rules/manage-rules/import-rules/)
- [Hazel Export Rules](https://www.noodlesoft.com/manual/hazel/work-with-folders-rules/manage-rules/export-rules/)

---

**Status:** ✅ Ready for setup
**Time Required:** ~5 minutes one-time configuration
**After Setup:** Fully automated, file-based configuration
