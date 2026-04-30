# Hazel Configuration

Hazel 6.1.2 — file-based, version-controlled automation for macOS folders.

## Official Documentation

Hazel's full docs are bundled in the app and viewable via macOS Tips/Help:
- **Location:** `/Applications/Hazel.app/Contents/Resources/HazelHelp.help/`
- **Open in Tips:** Help menu in Hazel app, or `open /Applications/Hazel.app/Contents/Resources/HazelHelp.help`
- **Key pages:** Using Shell Scripts, Sync Rules, Attribute Reference, Action Reference

## Directory Structure

```
config/hazel/
├── CLAUDE.md                        # This file
├── rules/                           # Active rules (synced to Hazel) — SOURCE OF TRUTH
│   ├── Desktop.hazelrules
│   ├── Downloads.hazelrules
│   ├── Documents.hazelrules
│   ├── Inbox.hazelrules
│   └── Archive.hazelrules
└── scripts/                         # Shell scripts called by Hazel rules
    ├── convert-video-to-mp4.sh      # Ongoing: convert non-MP4 video → MP4
    ├── cleanup-documents.sh         # One-time: move app folders Documents → Backups
    └── fix-archive-folders.sh       # One-time: fix colon-separated Archive folder names
```

## How It Works

- `.hazelrules` files in `rules/` are binary (Hazel GUI generates them)
- Hazel's "Sync Rules" feature keeps the GUI in sync with these dotfiles
- Changes made in Hazel GUI auto-persist to the synced `.hazelrules` files
- Scripts in `scripts/` are referenced by Hazel rules and also usable from CLI

## Shell Script Convention (Hazel)

Per Hazel docs ("Using Shell Scripts"):
- `$1` = full path to the matched file (always quote it)
- Return exit code 0 for success; non-zero triggers Hazel retry
- Scripts run in a limited environment — always set explicit `PATH`
- Use `#!/bin/zsh` shebang and `set -euo pipefail`
- External scripts must be `chmod +x`

For Hazel rules using dotfiles scripts, the embedded script should be a one-liner:
```zsh
exec "$HOME/dotfiles/config/hazel/scripts/script-name.sh" "$1"
```

## Current Rules

| Folder | Rule | Trigger | Action |
|--------|------|---------|--------|
| Desktop | Screenshot import | Name contains "Screenshot" + Kind is Image + 1h old | Import to Photos → Trash |
| Desktop | Sync to GDrive | Name is NOT .DS_Store + Ext is NOT icloud + Name does NOT contain "Google Drive" + Name does NOT contain "Lost and Found" + Name does NOT contain "google-drive-not-synced" | Sync to GDrive/Backups/iCloud/Desktop |
| Downloads | Video convert → MP4 | Extension is webp/mkv/avi/mov/wmv/flv/webm/m4v/3gp/ts/ogv/mpg/mpeg | Run convert-video-to-mp4.sh → Trash original |
| Downloads | Video import | Type is public.movie + 1h old | Import to Photos → Trash |
| Downloads | Image import | Type is public.image + 1h old | Import to Photos → Trash |
| Documents | Sync to GDrive | Name is NOT .DS_Store + Ext is NOT icloud + Name does NOT contain "Google Drive" + Name does NOT contain "Lost and Found" + Name does NOT contain "google-drive-not-synced" | Sync to GDrive/Backups/iCloud/Documents |
| Documents | Archive stale projects | NOT Hayaeh/Therapy/Told + 6mo untouched | Sort into GDrive/Archive/{year}/{month}/{day}/ |

## Sync Paths

| Folder | Sync File |
|--------|-----------|
| Desktop | `~/dotfiles/config/hazel/rules/Desktop.hazelrules` |
| Downloads | `~/dotfiles/config/hazel/rules/Downloads.hazelrules` |
| Documents | `~/dotfiles/config/hazel/rules/Documents.hazelrules` |

## Principles

1. **Safety first** — import before delete, buffer times (1h media, 7d installers, 6mo docs)
2. **Incremental** — add 1 rule, observe, then expand
3. **Portable** — scripts + rules in dotfiles, clone and it works
4. **Never auto-delete user documents** — only re-downloadable files (DMGs)

## Dependencies

- `ffmpeg` / `ffprobe` — declared in `modules/homebrew.nix` (line 62)
- Hazel — declared in `modules/homebrew.nix` casks (line 141)

## Drive Folder Taxonomy & Stream Retention Policy

Google Drive is the host's largest storage liability — at one point it carried
~1.4 TB locally because every subfolder defaulted to "Available offline." After
CC-58, the policy is **stream-only by default**. Only mark folders "Available
offline" when there is a concrete reason (offline editing, frequent reads).

| `~/My Drive/<folder>` | Mode | Reason |
|---|---|---|
| `Archive` | STREAM ONLY | 782 GB cold archive — primary disk-fill failure mode |
| `Refs` | STREAM ONLY | Read-only references; rare access |
| `Media` | STREAM ONLY | Large media; access on demand |
| `Korean Traditional Art Yuran Choi` | STREAM ONLY | Cold archive |
| `Areas` | CASE-BY-CASE | Mark only sub-folders actively edited offline |

**Hazel interaction**: the Documents `Archive stale projects` rule writes into
`~/My Drive/Archive`. That triggers a brief local cache write before Drive Stream
re-evicts on sync — acceptable. The Archive folder itself must remain stream-only.

**Drift check**: re-run `just disk-audit` quarterly. The script flags any
subfolder >100 GB locally as a likely "Available offline" mistake.

**iMazing**: not declared in `modules/homebrew.nix` and not currently installed
(verified on 2026-04-29). Policy: do **not** reinstall — iCloud Backup is the
canonical iOS backup path. iMazing's local backups grew to 738 GB unaccounted
for, which is the failure mode CC-58 documents.
