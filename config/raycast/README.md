# Raycast Configuration

Raycast settings are partially managed via `targets.darwin.defaults` in Nix.
Extensions and other settings sync via Raycast account.

## What's Managed by Nix

Via `modules/home/apps/raycast.nix`:
- Global hotkey (Cmd+Space)
- Clipboard history settings
- Floating notes settings
- AI chat hotkey dismissed

## What's NOT Managed (Manual Setup Required)

These require manual setup after fresh install:

### Extensions to Install
- Clipboard History
- Window Management
- System Commands
- GitHub (if used)
- Linear (if used)

### Hotkey Setup
1. Open Raycast Preferences (Cmd+,)
2. Set hotkey to Cmd+Space
3. **Disable Spotlight**: System Settings → Keyboard → Shortcuts → Spotlight

## Export/Import Settings

### Export Current Settings
```bash
# Full defaults export (readable plist)
defaults export com.raycast.macos ~/dotfiles/config/raycast/raycast.plist

# View contents
plutil -p ~/dotfiles/config/raycast/raycast.plist
```

### Import Settings
```bash
defaults import com.raycast.macos ~/dotfiles/config/raycast/raycast.plist
```

## .rayconfig Files

Raycast `.rayconfig` exports are **encrypted** (contain API keys, snippets, etc.).
The `Raycast.rayconfig` file in this directory is stored as a reference but
cannot be directly parsed or modified.

To import on a new machine:
1. Open Raycast
2. Go to Settings → Advanced
3. Click "Import Data"
4. Select `Raycast.rayconfig`

## Troubleshooting

If Raycast hotkey doesn't work:
1. Check System Settings → Privacy & Security → Accessibility → Raycast
2. Check System Settings → Privacy & Security → Input Monitoring → Raycast
3. Ensure Spotlight is disabled (Cmd+Space conflict)
