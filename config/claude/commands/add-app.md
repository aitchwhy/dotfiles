Add a macOS app to the Homebrew casks list, install it, and commit.

The user will provide an app name as the argument: `/add-app <app-name>`

## Steps

1. **Find the Homebrew cask name.** Search `brew search --cask <app-name>` to find the correct cask. If multiple results, pick the most relevant one or ask the user.

2. **Get version info.** Run `brew info --cask <cask-name>` to confirm the cask exists and show the latest version available.

3. **Check for duplicates.** Read `modules/homebrew.nix` and verify the cask is not already listed. If it is, tell the user and stop.

4. **Determine the correct category.** Read the existing categories in `modules/homebrew.nix` (Browsers, Development, AI & LLM, Design & Creative, Documents & Files, Communication, Productivity, Media, Remote Desktop, Utilities, System Utilities, QuickLook Plugins). Pick the best fit. If unsure, ask the user.

5. **Add the cask entry.** Edit `modules/homebrew.nix` to add the cask in the appropriate category section, following the existing format:
   ```
   "cask-name" # Brief description
   ```
   Place it alphabetically within its category section.

6. **Commit the change.** Stage and commit with:
   ```
   feat(homebrew): add <App Name> for <brief purpose>
   ```

7. **Run `just switch`.** Execute `just switch` to rebuild the system and install the app.

8. **Verify installation.** Run `brew list --cask | grep <cask-name>` to confirm the app is installed. Report the installed version to the user.

If any step fails, report the error and stop.
