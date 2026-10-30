#!/bin/sh
# Remove the user LaunchAgent and installed script; retain the log.

set -eu

LABEL="com.example.homebrew-updater"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
SCRIPT="$HOME/.local/bin/homebrew-updater.sh"

launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
rm -f "$PLIST" "$SCRIPT"

echo "Removed $LABEL and its installed script."
echo "Any log remains at: $HOME/Library/Logs/homebrew-updater.log"
