# Hazel Rules

**Status:** Rules must be created in Hazel GUI first

## Why Empty?

The previous text-based `.hazelrules` files were invalid - Hazel requires rules to be created in its GUI and exported to a binary/XML plist format.

## How to Populate This Directory:

1. **Create rules in Hazel GUI** (see ~/Desktop/01-Today/HAZEL-CORRECT-SETUP.md)
2. **Export each rule set:**
   - Select folder in Hazel
   - Gear icon (⚙️) → "Export Rules..."
   - Save here as: `[folder]-critical.hazelrules`
3. **Commit to git** once exported

## Expected Files (After Manual Creation):

- `desktop-critical.hazelrules` - Screenshot import rule
- `downloads-critical.hazelrules` - Video/image import, DMG cleanup
- `gdrive-critical.hazelrules` - .DS_Store cleanup
- `backups-critical.hazelrules` - Orphaned file cleanup

**Total:** 6 rules across 4 folders
