# Hazel Configuration

**Source of Truth:** This directory (`~/dotfiles/config/hazel/`)

All Hazel rules are maintained here and symlinked to Hazel's configuration directory for use by the application.

---

## Directory Structure

```
~/dotfiles/config/hazel/
├── README.md                           # This file
├── rules/                              # Rule definitions
│   ├── desktop-critical.hazelrules    # Desktop automation (1 rule)
│   ├── downloads-critical.hazelrules  # Downloads automation (1 rule)
│   ├── gdrive-critical.hazelrules     # Google Drive automation (1 rule)
│   └── backups-critical.hazelrules    # Backup automation (1 rule)
└── archive/                            # Full rule sets (for future use)
    ├── desktop-lifecycle.hazelrules   # Complete Desktop rules (5 rules)
    ├── downloads-lifecycle.hazelrules # Complete Downloads rules (5 rules)
    ├── gdrive-lifecycle.hazelrules    # Complete Google Drive rules (6 rules)
    └── backups-lifecycle.hazelrules   # Complete Backup rules (4 rules)
```

---

## Philosophy: Incremental Introduction

**Why start minimal?**
- Automation can be overwhelming if introduced all at once
- Starting with 1 critical rule per folder allows time to observe and adjust
- Build trust in the system before adding more automation
- Easier to debug if something goes wrong

**Current Phase:** Critical Rules Only (1 per folder)

**Future:** Gradually introduce more rules from `archive/` as you become comfortable

---

## Critical Rules (Active)

### Desktop: Screenshot Auto-Import
**File:** `rules/desktop-critical.hazelrules`
**Purpose:** Prevent screenshot clutter on Desktop
**Action:** Import screenshots to Photos.app after 1-hour buffer, then delete
**Impact:** Low risk, high value - keeps Desktop clean

### Downloads: DMG Installer Cleanup
**File:** `rules/downloads-critical.hazelrules`
**Purpose:** Remove old installer files automatically
**Action:** Delete .dmg files older than 7 days
**Impact:** Low risk - installers are re-downloadable

### Google Drive: .DS_Store Cleanup
**File:** `rules/gdrive-critical.hazelrules`
**Purpose:** Remove macOS clutter files
**Action:** Delete .DS_Store files immediately
**Impact:** Zero risk - these files serve no purpose

### Backups: Orphaned File Cleanup
**File:** `rules/backups-critical.hazelrules`
**Purpose:** Remove failed backup artifacts
**Action:** Delete .tmp, .partial, .download files older than 7 days
**Impact:** Low risk - only cleans up failed operations

---

## Symlink Setup

Hazel reads rules from its internal configuration directory. To maintain source of truth in dotfiles:

```bash
# After Hazel is installed, create symlinks:
# (This will be automated in darwin configuration)

# Hazel stores rules at:
# ~/Library/Application Support/Hazel/Rules/

# Create symlinks from Hazel to dotfiles:
ln -sf ~/dotfiles/config/hazel/rules/desktop-critical.hazelrules \
  ~/Library/Application\ Support/Hazel/Rules/Desktop.hazelrules

ln -sf ~/dotfiles/config/hazel/rules/downloads-critical.hazelrules \
  ~/Library/Application\ Support/Hazel/Rules/Downloads.hazelrules

# ... etc for each folder
```

**Note:** Actual symlink setup will be handled by nix-darwin activation script.

---

## Adding More Rules (Future)

When ready to add more automation:

1. Review archived rules in `archive/` directory
2. Select next rule to add based on comfort level
3. Copy rule from archive to active rules file
4. Test for 1 week before adding more
5. Repeat until all desired rules are active

**Suggested order for adding rules:**
1. ✅ Critical rules (active now)
2. Desktop: Day-old files → Review (after 1 week of comfort)
3. Downloads: PDF categorization (after 2 weeks)
4. Google Drive: Inbox flagging (after 3 weeks)
5. Full lifecycle rules (after 1 month)

---

## Troubleshooting

### Rules not applying
1. Check Hazel is running: `ps aux | grep -i hazel`
2. Verify symlinks exist: `ls -la ~/Library/Application\ Support/Hazel/Rules/`
3. Check Hazel logs: `tail -f ~/Library/Logs/Hazel/*.log`
4. Open Hazel.app and verify rules are imported and enabled

### Want to disable a rule temporarily
1. Open Hazel.app
2. Find the folder with the rule
3. Uncheck the box next to the rule
4. Re-enable when ready

### Want to modify a rule
1. Edit the source file in `~/dotfiles/config/hazel/rules/`
2. Commit changes to git
3. Reload rules in Hazel.app (or restart Hazel)

---

## Full Rule Sets (Available in Archive)

When you're ready for full automation, the complete rule sets are available:

- **Desktop** (5 rules): Screenshots, day-old transition, week-old transition, large files, installer cleanup
- **Downloads** (5 rules): PDF categorization, image handling, old file archival, DMG cleanup, ZIP cleanup
- **Google Drive** (6 rules): Inbox flagging, Active→Recent, Recent→Archive, Archive→Cold, .DS_Store, root cleanup
- **Backups** (4 rules): Rotation trigger, archive old, delete ancient, orphaned cleanup

See `archive/` directory for full rule definitions.

---

## Related Documentation

- **System Overview:** `~/.claude/plans/folder-organization-system.md`
- **Implementation Summary:** `~/.claude/plans/implementation-summary-2026-02-01.md`
- **Import Instructions:** `~/Desktop/01-Today/HAZEL-IMPORT-INSTRUCTIONS.md`

---

**Status:** Critical rules ready for use
**Last Updated:** 2026-02-01
**Maintained by:** nix-darwin + home-manager
