#!/bin/sh
# Install the user LaunchAgent and maintenance script.

set -eu

REPO_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
BIN_DIR="$HOME/.local/bin"
AGENT_DIR="$HOME/Library/LaunchAgents"
SCRIPT_DEST="$BIN_DIR/homebrew-updater.sh"
PLIST_DEST="$AGENT_DIR/com.example.homebrew-updater.plist"
LABEL="com.example.homebrew-updater"

mkdir -p "$BIN_DIR" "$AGENT_DIR" "$HOME/Library/Logs"
cp "$REPO_DIR/scripts/homebrew-updater.sh" "$SCRIPT_DEST"
chmod 755 "$SCRIPT_DEST"
cp "$REPO_DIR/launchd/com.example.homebrew-updater.plist" "$PLIST_DEST"
chmod 644 "$PLIST_DEST"

plutil -lint "$PLIST_DEST"

# Reload cleanly if this agent is already loaded.
launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST_DEST"

echo "Installed and loaded $LABEL."
echo "Logs: $HOME/Library/Logs/homebrew-updater.log"
echo "Run now with: \"$SCRIPT_DEST\""
