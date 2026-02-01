# Hazel Configuration

**Philosophy:** File-based, version-controlled automation with incremental adoption.

---

## Architecture

### File-Based Configuration
All rules stored in `~/dotfiles/config/hazel/` as source of truth. Hazel syncs from these files using its built-in [Sync Rules](https://www.noodlesoft.com/manual/hazel/work-with-folders-rules/manage-rules/sync-rules/) feature.

**Benefits:**
- Version controlled (git)
- Portable across machines
- Easy to review and modify
- Auto-updates when files change

### Directory Structure

```
~/dotfiles/config/hazel/
├── README.md                    # This file
├── audit-2026-02-01.md          # Implementation audit log
├── SYNC-PATHS.txt               # Quick reference for setup
├── rules/                       # Active rules (synced to Hazel)
│   ├── desktop-critical.hazelrules
│   ├── downloads-critical.hazelrules
│   ├── gdrive-critical.hazelrules
│   └── backups-critical.hazelrules
└── archive/                     # Full rule sets (future use)
    ├── desktop-lifecycle.hazelrules
    ├── downloads-lifecycle.hazelrules
    ├── gdrive-lifecycle.hazelrules
    └── backups-lifecycle.hazelrules
```

---

## Core Principles

### 1. Incremental Adoption
**Why:** Automation can be overwhelming if introduced all at once.

**Approach:**
- Start with 1 critical, low-risk rule per folder
- Observe behavior for 1-2 weeks
- Gradually add more rules from `archive/`
- Build trust in the system before expanding

### 2. Buffer Times
**Why:** Prevent processing files you just added.

**Implementation:**
- 1-hour buffer for media imports (screenshots, videos, images)
- 7-day buffer for installer cleanup
- Gives you time to use/review files before automation triggers

### 3. Safety First
**Why:** Avoid accidental data loss.

**Safeguards:**
- Import to Photos before deletion (media has backup)
- Only delete re-downloadable files (DMG installers)
- Only delete system clutter (.DS_Store) or failed artifacts (.tmp)
- Never delete user documents automatically

### 4. Lifecycle-Based Organization
**Why:** Match natural file flow through time and usage.

**Stages:**
```
Inbox → Active → Recent → Archive → Cold Storage
  ↑       ↑        ↑         ↑          ↑
 New   Current  1-3mo    >3mo       >1yr
```

Rules trigger based on:
- Time since added (for new files)
- Time since last opened (for existing files)

---

## Architectural Decisions

### Decision 1: Sync Rules vs Import Rules
**Chosen:** Sync Rules
**Why:**
- Auto-updates when dotfiles change
- No manual re-import needed
- File-based configuration persists across Hazel reinstalls
- One-time setup, then fully automated

**Trade-off:** Requires initial GUI setup (5 minutes), but saves hours long-term

### Decision 2: Critical Rules Only (Phase 1)
**Chosen:** 1 rule per folder initially
**Why:**
- Lower risk of unexpected behavior
- Easier to debug if something goes wrong
- Builds confidence in automation
- Can expand to full lifecycle later

**Trade-off:** Less automation initially, but safer onboarding

### Decision 3: Media → Photos.app
**Chosen:** Auto-import videos/images to Photos, then delete
**Why:**
- Photos provides automatic iCloud backup
- Prevents Downloads folder clutter
- Searchable/organized in Photos app
- Safe deletion (backed up before removal)

**Trade-off:** Requires Photos.app, but standard on macOS

### Decision 4: No Auto-Delete of Documents
**Chosen:** Manual review required for documents/PDFs
**Why:**
- Too high risk for accidental data loss
- User documents often unique/irreplaceable
- Better to notify than auto-delete

**Trade-off:** Manual organization needed for documents (acceptable)

---

## Current Rules (Active)

| Folder | Rule | Trigger | Action | Risk |
|--------|------|---------|--------|------|
| **Desktop** | Screenshot import | Name contains "Screenshot" + 1h old | Import to Photos → Trash | Low |
| **Downloads** | Video import | MP4/MOV/etc + 1h old | Import to Photos → Trash | Low |
| **Downloads** | Image import | JPG/PNG/etc + 1h old | Import to Photos → Trash | Low |
| **Downloads** | DMG cleanup | .dmg + 7 days old | Move to Trash | Low |
| **Google Drive** | .DS_Store cleanup | Name is ".DS_Store" | Trash immediately | Zero |
| **Backups** | Orphaned cleanup | .tmp/.partial/.download + 7 days old | Move to Trash | Low |

**Total:** 6 critical rules across 4 folders

---

## Setup (One-Time)

1. **Open Hazel** (System Settings → Hazel, or standalone app)

2. **Add Folders:**
   - Desktop
   - Downloads
   - Google Drive/My Drive (✓ Include subfolders)
   - Backups (✓ Include subfolders)

3. **Enable Sync Rules** for each folder:
   - Select folder → Gear icon (⚙️) → "Sync Rules..."
   - Choose corresponding `.hazelrules` file from `~/dotfiles/config/hazel/rules/`
   - See `SYNC-PATHS.txt` for exact paths

**Result:** Rules auto-update when you edit dotfiles. No manual import needed.

---

## Future Expansion

**When ready** (after 1-2 weeks of observation):

1. Review rules in `archive/` directory
2. Copy desired rule from archive to active file
3. Commit change to git
4. Hazel automatically syncs new rule

**Suggested order:**
1. ✅ Critical rules (active now)
2. Desktop: Day-old files → Review folder
3. Downloads: PDF categorization by content
4. Google Drive: Inbox flagging (3-day reminder)
5. Full lifecycle transitions (Active → Recent → Archive → Cold)

---

## Maintenance

### Modifying Rules
```bash
# Edit rule file
vim ~/dotfiles/config/hazel/rules/downloads-critical.hazelrules

# Commit changes
cd ~/dotfiles
git add config/hazel/rules/downloads-critical.hazelrules
git commit -m "feat(hazel): add new condition to downloads rule"

# Hazel automatically detects change and updates ✨
```

### Viewing Logs
```bash
# Check Hazel is running
ps aux | grep -i hazel

# View Hazel logs
tail -f ~/Library/Logs/Hazel/*.log

# Or: Open Hazel → Select folder → Info tab → "Show Log"
```

---

## Best Practices

### Rule Ordering
**Principle:** Most specific to least specific
- Process screenshots before generic images
- Check file type before checking age
- Apply narrow conditions before broad ones

### Buffer Times
**Principle:** Longer buffers for irreversible actions
- 1 hour: Media imports (reversible via Photos)
- 7 days: File deletions (re-downloadable)
- 30+ days: Document archival (user content)

### Exclusions
**Principle:** Exclude what you know won't work
- GIF files: Often used for reference (not auto-import)
- .icloud files: Placeholder files (not real files)
- System files: .DS_Store, .localized (auto-delete safe)

### Testing
**Principle:** Test before committing
1. Add rule with 1-hour buffer
2. Create test file
3. Wait for rule to trigger
4. Verify expected behavior
5. If works, commit to git

---

## Related Systems

- **Folder Organization:** `~/.claude/plans/folder-organization-system.md`
- **Lifecycle Transitions:** Defined in `archive/*-lifecycle.hazelrules`
- **iCloud→GDrive Sync:** Separate system (rclone + launchd)

---

**Status:** ✅ Active (6 critical rules)
**Last Updated:** 2026-02-01
**Audit Log:** `audit-2026-02-01.md`
