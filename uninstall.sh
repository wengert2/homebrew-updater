#!/bin/sh
# Remove the user LaunchAgent and installed script; retain the log.

set -eu

LABEL="com.example.homebrew-updater"
OLD_LABEL="com.example.homebrew-weekly"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
OLD_PLIST="$HOME/Library/LaunchAgents/$OLD_LABEL.plist"
SCRIPT="$HOME/.local/bin/homebrew-updater.sh"
OLD_SCRIPT="$HOME/.local/bin/homebrew-weekly.sh"
CONFIG_FILE="$HOME/.config/homebrew-updater/config"

launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
launchctl bootout "gui/$(id -u)/$OLD_LABEL" 2>/dev/null || true
rm -f "$PLIST" "$SCRIPT" "$OLD_PLIST" "$OLD_SCRIPT"

echo "Removed $LABEL and its installed script."
echo "Any log remains at: $HOME/Library/Logs/homebrew-updater.log"
echo "Config remains at: $CONFIG_FILE"
