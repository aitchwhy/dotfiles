#!/usr/bin/osascript
-- Automated Hazel Folder Setup
-- Adds folders to Hazel and configures sync rules

tell application "System Events"
    -- Check if Hazel is available in System Settings
    if exists process "System Settings" then
        tell process "System Settings"
            -- Open Hazel preferences
            -- Note: This may require manual navigation in GUI
            -- Hazel 6+ appears as a pane in System Settings
        end tell
    end if
end tell

-- Alternative: Try opening Hazel directly
tell application "Hazel"
    activate
end tell

display dialog "Hazel automation via AppleScript is limited. Please use the manual setup:

1. Open Hazel (System Settings → Hazel)
2. Add 4 folders using the '+' button
3. Enable 'Sync Rules' for each folder

See ~/dotfiles/config/hazel/SYNC-PATHS.txt for exact paths." buttons {"OK"} default button "OK"
