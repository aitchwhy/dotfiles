# Cursor IDE configuration
# Uses copy-on-init pattern: copies config if not present, preserves runtime changes
{ config, lib, ... }:

with lib;

{
  options.modules.home.apps.cursor = {
    enable = mkEnableOption "Cursor IDE configuration";
  };

  config = mkIf config.modules.home.apps.cursor.enable {
    # Cursor on macOS stores config in ~/Library/Application Support/Cursor/User/
    # We use copy-on-init to allow runtime changes while providing a baseline from dotfiles
    home.activation.cursorConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      CONFIG_DIR="$HOME/Library/Application Support/Cursor/User"
      SOURCE_DIR="${../../../config/cursor}"

      # Create directory if needed
      $DRY_RUN_CMD mkdir -p "$CONFIG_DIR"

      # Copy settings.json if it doesn't exist
      if [ ! -f "$CONFIG_DIR/settings.json" ]; then
        $DRY_RUN_CMD cp "$SOURCE_DIR/settings.json" "$CONFIG_DIR/settings.json"
        $DRY_RUN_CMD chmod 644 "$CONFIG_DIR/settings.json"
        echo "Cursor settings.json initialized from dotfiles"
      fi

      # Copy keybindings.json if it doesn't exist
      if [ ! -f "$CONFIG_DIR/keybindings.json" ]; then
        $DRY_RUN_CMD cp "$SOURCE_DIR/keybindings.json" "$CONFIG_DIR/keybindings.json"
        $DRY_RUN_CMD chmod 644 "$CONFIG_DIR/keybindings.json"
        echo "Cursor keybindings.json initialized from dotfiles"
      fi
    '';
  };
}
