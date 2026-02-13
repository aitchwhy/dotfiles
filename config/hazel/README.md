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
├── scripts/                     # One-time maintenance scripts
│   ├── cleanup-documents.sh     # Move app folders from Documents → Backups
│   └── fix-archive-folders.sh   # Fix colon-separated Archive folder names
└── rules/                       # Active rules (synced to Hazel) - SOURCE OF TRUTH
    ├── Desktop.hazelrules       # Screenshot auto-import + iCloud sync to GDrive
    ├── Downloads.hazelrules     # Video/image auto-import to Photos
    └── Documents.hazelrules     # Stale project archival (6mo → Archive)
```

**Note:** Only files in `rules/*.hazelrules` are active. Create/edit rules in Hazel GUI and they auto-sync here.

---

## Taxonomy: Backups vs Archive

Google Drive organizes files into two top-level categories:

| Category | Contents | Examples | Structure |
|----------|----------|----------|-----------|
| **Backups** | App-named folders (app data/metadata) | Zoom/, Cursor/, Anthropic-Claude-AI/ | Flat: `Backups/AppName/` |
| **Archive** | Project-based folders (time-limited, clear deliverable) | Lease PDFs, export ZIPs, meeting notes | Nested: `Archive/2025/Apr/05/` |

Additionally, `Backups/iCloud/` mirrors Desktop and Documents via Hazel Sync.

**Active folders** (Hayaeh, Therapy, Told) stay in `~/Documents/` — evergreen, no end date.

---

## Core Principles

### 1. Incremental Adoption
- Start with 1 critical, low-risk rule per folder
- Observe behavior for 1-2 weeks
- Gradually add more rules
- Build trust in the system before expanding

### 2. Buffer Times
- 1-hour buffer for media imports (screenshots, videos, images)
- 7-day buffer for installer cleanup
- 6-month buffer for document archival

### 3. Safety First
- Import to Photos before deletion (media has backup)
- Only delete re-downloadable files (DMG installers)
- Deletions NOT synced from iCloud to Google Drive (backup preserved)
- Never delete user documents automatically

### 4. Lifecycle-Based Organization
```
Inbox → Active → Recent → Archive → Cold Storage
  ↑       ↑        ↑         ↑          ↑
 New   Current  1-3mo    >6mo       >1yr
```

---

## Current Rules (Active)

| Folder | Rule | Trigger | Action |
|--------|------|---------|--------|
| **Desktop** | Screenshot import | Name contains "Screenshot" + Kind is Image + 1h old | Import to Photos → Trash |
| **Desktop** | Sync to Google Drive | Name is NOT .DS_Store + Ext is NOT icloud | Sync to `GDrive/Backups/iCloud/Desktop` |
| **Downloads** | Video import | Type is public.movie + 1h old | Import to Photos → Trash |
| **Downloads** | Image import | Type is public.image + 1h old | Import to Photos → Trash |
| **Documents** | Sync to Google Drive | Name is NOT .DS_Store + Ext is NOT icloud | Sync to `GDrive/Backups/iCloud/Documents` |
| **Documents** | Archive stale projects | NOT Hayaeh/Therapy/Told + 6mo untouched | Sort into `GDrive/Archive/{year}/{month}/{day}/` |

**Total:** 6 active rules across 3 folders

### Sync Rules Details

Desktop and Documents use Hazel's [Sync action](https://www.noodlesoft.com/manual/hazel/advanced-topics/syncing-folders/) for one-way iCloud → Google Drive backup:

- **One-way only** — source → destination, never the reverse
- **Incremental** — only new/changed files, not full copies each time
- **Deletions NOT synced** — files deleted from iCloud stay in Google Drive
- **Folder structure preserved** — "From Monitored Folder" maintains subfolder hierarchy
- **Google Drive versioning** — overwrites keep old versions (up to 100 versions, 30-day retention)

---

## Setup (One-Time)

1. **Open Hazel** (System Settings → Hazel, or standalone app)

2. **Add Folders:**
   - Desktop (with subfolders)
   - Downloads
   - Documents (with subfolders for sync; without subfolders for archival)

3. **Enable Sync Rules** for each folder:
   - Select folder → Gear icon → "Sync Rules..."
   - Choose corresponding `.hazelrules` file:
     - Desktop → `~/dotfiles/config/hazel/rules/Desktop.hazelrules`
     - Downloads → `~/dotfiles/config/hazel/rules/Downloads.hazelrules`
     - Documents → `~/dotfiles/config/hazel/rules/Documents.hazelrules`

**Result:** Rules auto-update when you edit dotfiles. No manual import needed.

---

## One-Time Scripts

### Documents Cleanup
Move app folders from `~/Documents/` to `Google Drive/Backups/`:

```bash
# Preview changes
config/hazel/scripts/cleanup-documents.sh --dry-run

# Execute
config/hazel/scripts/cleanup-documents.sh
```

### Archive Folder Fix
Convert malformed `2025:Apr:05:filename` folders to nested `2025/Apr/05/`:

```bash
# Preview changes
config/hazel/scripts/fix-archive-folders.sh --dry-run

# Execute
config/hazel/scripts/fix-archive-folders.sh
```

---

## Related Systems

- **iCloud → Google Drive:** Hazel Sync rules (Desktop + Documents)
- **Google Drive versioning:** Built-in (up to 100 versions, 30-day retention)
- **Documents lifecycle:** Stale projects auto-archive after 6 months

---

**Status:** Active
**Last Updated:** 2026-02-13
