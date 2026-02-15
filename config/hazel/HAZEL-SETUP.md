# Hazel Rules for Google Drive Inbox Auto-Filing

## Watched Folder
`~/Library/CloudStorage/GoogleDrive-hank.lee.qed@gmail.com/My Drive/Inbox/`

## Rules (add in Hazel UI, in this order)

### Rule 1: Financial Documents
- **Condition:** Name contains any of: `invoice`, `receipt`, `statement`, `tax`, `robinhood`, `allstate`, `insurance`, `billing`, `payment`, `budget`, `monarch`
- **Action:** Move to `Areas/Finance/`

### Rule 2: Legal/Immigration
- **Condition:** Name contains any of: `uscis`, `eb5`, `i-829`, `green-card`, `immigration`, `passport`, `visa`, `legal`, `contract`
- **Action:** Move to `Areas/Legal/`

### Rule 3: Medical/Health
- **Condition:** Name contains any of: `therapy`, `health`, `medical`, `whoop`, `tapering`, `doctor`, `prescription`, `aetna`, `carefirst`
- **Action:** Move to `Areas/Medical/`

### Rule 4: Home/Housing
- **Condition:** Name contains any of: `lease`, `rent`, `apartment`, `olivia`, `cielo`, `industrious`, `verizon`, `t-mobile`, `utilities`, `move-out`
- **Action:** Move to `Areas/Home/`

### Rule 5: Pet Documents
- **Condition:** Name contains any of: `meep`, `milli`, `cat`, `vet`, `viagen`, `pure-paws`, `favn`
- **Action:** Move to `Areas/Family/Pets/`

### Rule 6: Photos by Extension
- **Condition:** Extension is any of: `jpg`, `jpeg`, `png`, `heic`, `dng`, `raw`
- **Action:** Move to `Media/Photos/`

### Rule 7: Audio by Extension
- **Condition:** Extension is any of: `m4a`, `mp3`, `wav`, `whisper`, `webm`
- **Action:** Move to `Media/Audio/`

### Rule 8: Video by Extension
- **Condition:** Extension is any of: `mp4`, `mov`, `mkv`
- **Action:** Move to `Media/Videos/`

### Rule 9: AI/Dev References
- **Condition:** Name contains any of: `claude`, `chatgpt`, `ai-prompt`, `llm`, `playbook`, `elite-dev`
- **Action:** Move to `Refs/AI-Prompts/`

### Rule 10: Catch-all (older than 7 days)
- **Condition:** Date added is not in the last 7 days
- **Action:** Move to `Archive/Miscellaneous/`

## Notes
- Rules are evaluated top-to-bottom; first match wins
- The catch-all rule gives you 7 days to manually file before auto-archiving
- Add Hazel to watch `Inbox/` via: Hazel Preferences → + → navigate to Inbox folder
- Delete this file after setup
